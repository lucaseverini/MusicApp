//
//  SequencerOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 21/4/2013.
//


#import <AudioToolbox/AudioFile.h>
#import "SequencerOperation.h"
#import "DJMixer.h"
#import "MusicAppAppDelegate.h"


@implementation SequencerOperation

@synthesize mixer;
@synthesize waitForAction;
@synthesize noDataAvailable;

// 44,100 x 16 x 2 = 1,411,200 bits per second (bps) = 1,411 kbps = ~142 KBytes/sec per channel
const size_t kAudioDataBufferSize = (1024 * 256);


- (id) initWithRecords:(NSString*)recordsFile
{
	self = [super init];
    if(self != nil)
    {		
		[self setQueuePriority:NSOperationQueuePriorityHigh];

		numChannels = 2;

		outputFormat.mSampleRate = kSamplingRate;
		outputFormat.mFormatID = kAudioFormatLinearPCM;
		outputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
		outputFormat.mBitsPerChannel = 16;
		outputFormat.mChannelsPerFrame = numChannels;
		outputFormat.mFramesPerPacket = 1;
		outputFormat.mBytesPerFrame = (outputFormat.mBitsPerChannel * outputFormat.mChannelsPerFrame) / 8;
		outputFormat.mBytesPerPacket = outputFormat.mBytesPerFrame * outputFormat.mFramesPerPacket;

		startPacket = 0;
		
		curPlaying = NULL;

		[self setRecords:recordsFile];
	}
    
    return self;
}


- (void) dealloc
{
	for(int idx = 0; idx < totRecordings; idx++)
	{
		if(recordings[idx].fileRef != NULL)
		{
			ExtAudioFileDispose(recordings[idx].fileRef);
		}

		free(recordings[idx].buffer1.data);
		free(recordings[idx].buffer2.data);
		free(recordings[idx].buffer3.data);
	}
    	
	free(recordings);

	[super dealloc];
}


- (void) setRecords:(NSString*)recordsFile
{
	if(recordings != NULL)
	{
		for(int idx = 0; idx < totRecordings; idx++)
		{
			if(recordings[idx].fileRef != NULL)
			{
				ExtAudioFileDispose(recordings[idx].fileRef);
			}

			free(recordings[idx].buffer1.data);
			free(recordings[idx].buffer2.data);
			free(recordings[idx].buffer3.data);
		}

		free(recordings);
		recordings = NULL;
		
		totRecordings = 0;
	}
	
	NSMutableArray *records = [NSMutableArray arrayWithContentsOfFile:recordsFile];
	if(records != nil && [records count] > 0)
	{
		// Filter all the disabled recordings
		[records filterUsingPredicate:[NSPredicate predicateWithFormat:@"(enabled == YES)"]];
		
		// Sort recordings by positioning time. Newer first
		NSArray *sortedRecords = [records sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
								  {
									  int result = [[obj2 objectForKey:@"posTime"] compare:[obj1 objectForKey:@"posTime"]];
									  return result;
								  }];
		
		for(NSDictionary *record in sortedRecords)
		{
			NSString *fileName = [record objectForKey:@"fileName"];
			
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
			NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:[[paths objectAtIndex:0] stringByAppendingPathComponent:fileName]];
			
			AVURLAsset *theAsset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
			if(theAsset != nil)
			{
				NSArray *tracks = [theAsset tracks];
				if([tracks count] > 0)
				{
					AVAssetTrack *theTrack = [tracks objectAtIndex:0];
					if(theTrack != nil)
					{
						recordings = (recordingPtr)realloc(recordings, sizeof(recording) * (totRecordings + 1));
						assert(recordings != NULL);
						
						recordings[totRecordings].fileRef = NULL;
						recordings[totRecordings].file = fileURL;
						recordings[totRecordings].name = [fileName copy];
						recordings[totRecordings].startPacket = [[record objectForKey:@"startPacket"] integerValue];
						recordings[totRecordings].endPacket = [[record objectForKey:@"endPacket"] integerValue];
						recordings[totRecordings].duration = theAsset.duration;
						recordings[totRecordings].packets = ((double)theAsset.duration.value / (double)theAsset.duration.timescale) * kSamplingRate;
						
						recordings[totRecordings].buffer1.data = (UInt32*)malloc(kSamplingRate * outputFormat.mBytesPerPacket); // First buffer always up to 1 second of data
						recordings[totRecordings].buffer1.size = 0;
						recordings[totRecordings].buffer1.status = 0;
						
						recordings[totRecordings].buffer2.data = (UInt32*)malloc(kAudioDataBufferSize);
						recordings[totRecordings].buffer2.size = 0;
						recordings[totRecordings].buffer2.status = 0;

						recordings[totRecordings].buffer3.data = (UInt32*)malloc(kAudioDataBufferSize);
						recordings[totRecordings].buffer3.size = 0;
						recordings[totRecordings].buffer3.status = 0;

						recordings[totRecordings].fillBuffer = 0;
						recordings[totRecordings].readBuffer = 0;
						
						recordings[totRecordings].readPackets = 0;
						recordings[totRecordings].totReadPackets = 0;
						recordings[totRecordings].totBufferPackets = 0;
						
						recordings[totRecordings].noDataAvailable = YES;
						recordings[totRecordings].readerStatus = 0;
						totRecordings++;
						
						continue;
					}
				}
			}
			
			[fileURL release];
			
			NSLog(@"Sequencer recording %@ can't be used", fileName);
		}
		
		// If some recordings intersect, the newer one takes precedence
		if(recordings != NULL && totRecordings > 1)
		{			
			for(int idx = 0; idx < totRecordings - 1; idx++)
			{
				for(int idx2 = idx + 1; idx2 < totRecordings; idx2++)
				{
					if(recordings[idx2].startPacket < recordings[idx].endPacket && recordings[idx2].endPacket > recordings[idx].startPacket)
					{
						totRecordings--;
						for(int idx3 = idx2; idx3 < totRecordings - 1; idx3++)
						{
							recordings[idx3] = recordings[idx3 + 1];
						}
						
						idx2--;
					}
				}
			}
		}
		
		if(recordings != NULL)
		{
			NSLog(@"Sequencer recordings: %d", totRecordings);
			for(int idx = 0; idx < totRecordings; idx++)
			{
				double start = (double)recordings[idx].startPacket / kSamplingRate;
				double end = (double)recordings[idx].endPacket / kSamplingRate;
				NSLog(@"%@ %lld packets from %d to %d - %.1f to %.1f", recordings[idx].name, recordings[idx].packets, recordings[idx].startPacket, recordings[idx].endPacket, start, end);
			}
		}
		
		noDataAvailable = (totRecordings == 0);

		// Open all recordings and fill the first buffer
		for(int idx = 0; idx < totRecordings; idx++)
		{
			[self openAudioFile:&recordings[idx]];
			
			[self fillFirstBuffer:&recordings[idx] packetPosition:startPacket restorePosition:NO];
		}
		
	}
	else
	{
		noDataAvailable = YES;
	}
}


- (void) main
{
	NSLog(@"SequencerOperation: Main ++");
    
    waitForAction = [[NSCondition alloc] init];
    
    while(!self.isCancelled)
    {
		while(!active)
		{
			[waitForAction lock];
			[waitForAction wait];
			[waitForAction unlock];
		}
		if([self isCancelled])
		{
			break;
		}
				
		while(active)
		{
			if(curPlaying != NULL && curPlaying->readerStatus <= AVAssetReaderStatusReading)
			{
				for(int bufferNum = 1; bufferNum <= 3; bufferNum++)
				{
					switch(bufferNum)
					{
						case 1:
							if(curPlaying->buffer1.status == 0)
							{
								[self fillFirstBuffer:curPlaying packetPosition:0 restorePosition:YES];
							}
							break;

						case 2:
							if(curPlaying->buffer2.status == 0)
							{
								[self fillBuffer:curPlaying number:2];
							}
							break;
							
						case 3:
							if(curPlaying->buffer3.status == 0)
							{
								[self fillBuffer:curPlaying number:3];
							}
							break;
					}
				}
			}
			
			[NSThread sleepForTimeInterval:0.1]; // Let's save some cpu..
		}
	}
END:
    [waitForAction release];
    
	NSLog(@"SequencerOperation --");
}


- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer
{
	*packetsInBuffer = 0;
	
	switch(curPlaying->readBuffer)
	{
		case 0:
			if(curPlaying->buffer1.status == 2)
			{
				curPlaying->readBuffer = 1;			// Set buffer1 to be read
			}
			break;

		case 1:
			curPlaying->buffer1.status = 0;			// Set buffer1 status to Empty so it can be filled with data
			
			if(curPlaying->buffer2.status == 2)
			{
				curPlaying->readBuffer = 2;			// Set buffer2 to be read
			}
			break;

		case 2:
			curPlaying->buffer2.status = 0;			// Set buffer2 status to Empty so it can be filled with new data
			
			if(curPlaying->buffer3.status == 2)
			{
				curPlaying->readBuffer = 3;			// Set buffer3 to be read
			}
			break;

		case 3:
			curPlaying->buffer3.status = 0;			// Set buffer3 status to Empty so it can be filled with new data

			if(curPlaying->buffer2.status == 2)
			{
				curPlaying->readBuffer = 2;			// Set buffer2 to be read
			}
			break;
	}
	
	if(curPlaying->noDataAvailable)
	{
		NSLog(@"Sequencer getNextAudioBuffer %@ noDataAvailable", curPlaying->name);

		return NULL;
	}
	
	switch(curPlaying->readBuffer)
	{
		case 1:	// Gives back buffer1 to mixer
			if(curPlaying->buffer1.status == 2)
			{
				curPlaying->buffer1.status = 3;		// Set buffer1 status to Reading
				
				curPlaying->fillBuffer = 2;			// Set buffer2 to be filled
				
				*packetsInBuffer = curPlaying->buffer1.size / outputFormat.mBytesPerPacket;
				return curPlaying->buffer1.data;
			}
			break;

		case 2:	// Gives back buffer2 to mixer
			if(curPlaying->buffer2.status == 2)
			{
				curPlaying->buffer2.status = 3;		// Set buffer2 status to Reading
				
				curPlaying->fillBuffer = 3;			// Set buffer3 to be filled
				
				*packetsInBuffer = curPlaying->buffer2.size / outputFormat.mBytesPerPacket;
				return curPlaying->buffer2.data;
			}
			break;

		case 3:	// Gives back buffer3 to mixer
			if(curPlaying->buffer3.status == 2)
			{
				curPlaying->buffer3.status = 3;		// Set buffer3 status to Reading
				
				curPlaying->fillBuffer = 2;			// Set buffer2 to be filled
				
				*packetsInBuffer = curPlaying->buffer3.size / outputFormat.mBytesPerPacket;
				return curPlaying->buffer3.data;
			}
			break;
	}
	
	curPlaying->noDataAvailable = YES;
	
	NSLog(@"Sequencer getNextAudioBuffer %@ noDataAvailable", curPlaying->name);

	return NULL;
}


- (NSUInteger) fillFirstBuffer:(recordingPtr)recording packetPosition:(NSUInteger)packet restorePosition:(BOOL)restore
{
	NSLog(@"Sequencer fillFirstBuffer: %d %@", packet, recording->name);

	if(recording->fileRef == NULL)
    {
		return 0;
	}

	recording->buffer1.status = 1;

	SInt64 prevPacketPosition;
	
	if(restore)
	{
		OSStatus status = ExtAudioFileTell(recording->fileRef, &prevPacketPosition);
		if(status != noErr)
		{
			NSLog(@"Error %ld in ExtAudioFileTell", status);
		}
	}

	OSStatus status = ExtAudioFileSeek(recording->fileRef, packet);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileSeek", status);
	}
	
	AudioBufferList incomingAudio;
	incomingAudio.mNumberBuffers = 1;
	incomingAudio.mBuffers[0].mNumberChannels = numChannels;
	incomingAudio.mBuffers[0].mDataByteSize = kSamplingRate * outputFormat.mBytesPerFrame;
	incomingAudio.mBuffers[0].mData = recording->buffer1.data;
	UInt32 framesRead = kSamplingRate;
	status = ExtAudioFileRead(recording->fileRef, &framesRead, &incomingAudio);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileRead", status);
		
		recording->buffer1.size = 0;
		recording->buffer1.status = 0;
		recording->readerStatus = AVAssetReaderStatusFailed;
	}
	else
	{
		NSLog(@"Read %ld frames", framesRead);

		recording->buffer1.size = incomingAudio.mBuffers[0].mDataByteSize;
		recording->buffer1.status = 2;
		recording->readerStatus = framesRead != 0 ? AVAssetReaderStatusReading : AVAssetReaderStatusCompleted;
		
		recording->noDataAvailable = NO;
	}

	if(restore)
	{
		OSStatus status = ExtAudioFileSeek(recording->fileRef, prevPacketPosition);
		if(status != noErr)
		{
			NSLog(@"Error %ld in ExtAudioFileSeek", status);
		}
	}

	return framesRead;
}


- (NSUInteger) fillBuffer:(recordingPtr)recording number:(NSInteger)bufferNumber
{
	OSStatus status = noErr;
	
	NSLog(@"Sequencer fillBuffer: %d %@", bufferNumber, recording->name);

	if(recording->fileRef == NULL)
    {
		return 0;
	}
	
	audioBuffer *buffer = bufferNumber == 2 ? &recording->buffer2 : &recording->buffer3;
		
	buffer->status = 1;

	// Read the audio data
	AudioBufferList incomingAudio;
	incomingAudio.mNumberBuffers = 1;
	incomingAudio.mBuffers[0].mNumberChannels = numChannels;
	incomingAudio.mBuffers[0].mDataByteSize = kAudioDataBufferSize;
	incomingAudio.mBuffers[0].mData = buffer->data;
	UInt32 framesRead = kAudioDataBufferSize / outputFormat.mBytesPerFrame;
	status = ExtAudioFileRead(recording->fileRef, &framesRead, &incomingAudio);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileRead", status);
		
		buffer->status = 0;
		recording->readerStatus = AVAssetReaderStatusFailed;
	}
	else
	{
		NSLog(@"Read %ld frames", framesRead);
		
		if(framesRead == 0)
		{
			buffer->status = 0;
			recording->readerStatus = AVAssetReaderStatusCompleted;
		}
		else
		{
			buffer->status = 2;
			recording->readerStatus = AVAssetReaderStatusReading;
			
			recording->noDataAvailable = NO;
		}
		
		buffer->size = incomingAudio.mBuffers[0].mDataByteSize;
	}

	return framesRead;
}


- (BOOL) openAudioFile:(recordingPtr)recording
{
	if(recording == NULL)
	{
		return NO;
	}
	
	NSLog(@"Sequencer openAudioFile: %@", recording->name);
	
	recording->readerStatus = AVAssetReaderStatusFailed;
	
	OSStatus status = ExtAudioFileOpenURL((CFURLRef)recording->file, &recording->fileRef);
	if(status != noErr)
	{
		return NO;
	}
	
	status = ExtAudioFileSetProperty(recording->fileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &outputFormat);
	if(status != noErr)
	{
		return NO;
	}
	
    UInt32 propertySize = sizeof(recording->packets);
    status = ExtAudioFileGetProperty(recording->fileRef, kExtAudioFileProperty_FileLengthFrames, &propertySize, &recording->packets);
	if(status != noErr)
	{
		return NO;
	}
    
    AudioStreamBasicDescription streamFormat;
    propertySize = sizeof(streamFormat);
    status = ExtAudioFileGetProperty(recording->fileRef, kExtAudioFileProperty_FileDataFormat, &propertySize, &streamFormat);
	if(status != noErr)
	{
		return NO;
	}

	if(recording->packets == 0 /* || streamFormat.mSampleRate != kSamplingRate*/)
	{
		NSLog(@"File %@ can't be used", recording->name);
		
		return NO;
	}
	
	NSLog(@"File %@ open", recording->name);
	NSLog(@"Duration: %.2f", (double)recording->packets / kSamplingRate);
	
	recording->readerStatus = 0;

	return YES;
}


- (BOOL) setAudioFilePosition:(recordingPtr)recording packetPosition:(NSUInteger)packet
{
	NSLog(@"Sequencer setAudioFilePosition: %d - %@", packet, recording->name);
	
	SInt64 seekValue = packet;
	OSStatus status = ExtAudioFileSeek(recording->fileRef, seekValue);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileSeek", status);
	}

	return status == noErr;
}


- (recordingPtr) getRecording:(NSInteger)packet
{
	if(packet != -1)
	{
		for(int idx = 0; idx < totRecordings; idx++)
		{
			if(packet >= recordings[idx].startPacket && packet <= recordings[idx].endPacket)
			{
				return &recordings[idx];
			}
		}
	}
	
	return nil;
}


- (void) reset:(NSUInteger)packetPosition
{
	@synchronized(self)
	{
		NSLog(@"Sequencer Reset: %d", packetPosition);
		
		for(int idx = 0; idx < totRecordings; idx++)
		{			
			recordings[idx].fillBuffer = 0;
			recordings[idx].readBuffer = 0;
			recordings[idx].readerStatus = 0;

			recordings[idx].noDataAvailable = YES;

			if(packetPosition >= recordings[idx].startPacket && packetPosition < recordings[idx].endPacket)
			{
				NSUInteger packetToRead = (packetPosition - recordings[idx].startPacket);
				[self fillFirstBuffer:&recordings[idx] packetPosition:packetToRead restorePosition:NO];
			}
			else
			{
				[self fillFirstBuffer:&recordings[idx] packetPosition:0 restorePosition:NO];
			}
		}
		
		curPlaying = NULL;		
		working = NO;
	}
}


- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset
{
	@synchronized(self)
	{
		startPacket = time * kSamplingRate;
		
		if(reset)
		{
			[self reset:startPacket];
		}
	}
}


- (void) activate
{
	if(!active)
	{
		NSLog(@"Sequencer activated");
		
		active = YES;

		[waitForAction lock];
		[waitForAction signal];
		[waitForAction unlock];
	}
}


- (void) deactivate
{
	if(active)
	{
		NSLog(@"Sequencer deactivated");
		
		active = NO;
		
		[waitForAction lock];
		[waitForAction signal];
		[waitForAction unlock];
	}
}


- (void) remove
{
	[self cancel];
	[self activate];
}


- (NSInteger) getRecordings:(recordingPtr*)theRecordings;
{
	if(theRecordings != NULL)
	{
		*theRecordings = recordings;
	}
	
	return totRecordings;
}


- (BOOL) isActive
{
	return active;
}


- (BOOL) sequencerActive
{
	if(!active)
	{
		return NO;
	}

	NSUInteger packetIdx = mixer->durationPacketsIndex + mixer->framePacketsIndex;

	if(curPlaying != NULL)
	{
		if(packetIdx < curPlaying->startPacket || packetIdx >= curPlaying->endPacket)
		{
			if(working)
			{
				NSLog(@"Sequencer Disactive at %ld for %@", mixer->durationPacketsIndex, curPlaying->name);
				
				working = NO;
			}
			
			curPlaying = NULL;
		}
	}
	
	if(curPlaying == NULL)
	{
		for(int idx = 0; idx < totRecordings; idx++)
		{
			if(packetIdx >= recordings[idx].startPacket && packetIdx < recordings[idx].endPacket)
			{				
				curPlaying = &recordings[idx];

				if(!working)
				{
					double secs = (double)(curPlaying->endPacket - curPlaying->startPacket) / kSamplingRate;
					NSLog(@"Sequencer Active at %ld (%u-%u %g secs) for %@", mixer->durationPacketsIndex, curPlaying->startPacket, curPlaying->endPacket, secs, curPlaying->name);
					
					working = YES;
				}
				
				NSUInteger packetToRead = (packetIdx - recordings[idx].startPacket) + (curPlaying->buffer1.size / outputFormat.mBytesPerPacket);
				[self setAudioFilePosition:curPlaying packetPosition:packetToRead];

				curPlaying->buffer1.status = 2;
				curPlaying->buffer2.status = 0;
				curPlaying->buffer3.status = 0;
				
				curPlaying->fillBuffer = 0;
				curPlaying->readBuffer = 0;
				curPlaying->readerStatus = 0;

				break;
			}
		}
	}
			
	return (curPlaying != NULL);
}


- (BOOL) hasData
{
	if(curPlaying == NULL || curPlaying->noDataAvailable)
	{
		return NO;
	}
	
	return YES;
}

@end
