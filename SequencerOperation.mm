//
//  SequencerOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 21/4/2013.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioFile.h>
#import "SequencerOperation.h"
#import "DJMixer.h"
#import "MusicAppAppDelegate.h"


@implementation SequencerOperation

@synthesize mixer;
@synthesize waitForAction;
@synthesize noDataAvailable;

// 44,100 x 16 x 2 = 1,411,200 bits per second (bps) = 1,411 kbps = ~142 KBytes/sec per channel
const double kSamplingRate = 44100.0;
const size_t kAudioDataBufferSize = (1024 * 256);


- (id) initWithRecords:(NSString*)recordsFile
{
	self = [super init];
    if(self != nil)
    {
		[self setRecords:recordsFile];

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

		startSamplePacket = -1;
		
		curPlaying = NULL;
		curReading = NULL;
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

		for(int idx2 = 0; idx2 < 4; idx2++)
		{
			free(recordings[idx].buffers[idx2].data);
		}
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
			for(int idx2 = 0; idx2 < 4; idx2++)
			{
				free(recordings[idx].buffers[idx2].data);
			}
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
						
						for(int idx = 0; idx < 4; idx++)
						{
							recordings[totRecordings].buffers[idx].data = (UInt32*)malloc(kAudioDataBufferSize);
							recordings[totRecordings].buffers[idx].size = 0;
							recordings[totRecordings].buffers[idx].status = 0;
						}
						
						recordings[totRecordings].firstBufferLoaded	 = NO;
						recordings[totRecordings].loaded = NO;
						recordings[totRecordings].played = NO;
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

		// If no recording is being read/played at the moment, loops on the records and load the first buffer for everyone that hasn't...
		if(curReading == NULL && curPlaying == NULL)
		{
			for(int idx = 0; idx < totRecordings; idx++)
			{
				if(!recordings[idx].firstBufferLoaded)
				{
					[self loadFirstBuffer:&recordings[idx]];
					
					break;
				}
			}
			
			[NSThread sleepForTimeInterval:0.01]; // Let's save some cpu...
		}
		
		if(curPlaying != NULL)
		{
			// Sequencer is playing at this time...
			
			if(curReading != curPlaying)
			{
				if(curReading != NULL)
				{
					curReading->firstBufferLoaded = NO;

					// If the file is changed close it
					if(curReading->fileRef != NULL)
					{
						ExtAudioFileDispose(curReading->fileRef);
						curReading->fileRef = NULL;
					}
				}
								
				curReading = curPlaying;

				// No audio file is open, open it
				if(curReading->fileRef == NULL)
				{
					[self openAudioFile:curReading];
				}
			}
						
			if(curReading->readerStatus == AVAssetReaderStatusReading)
			{
				audioBufferPtr buffer = NULL;
				
				@synchronized(self)
				{
					for(int idx = 0; idx < 4; idx++)
					{
						if(curReading->buffers[idx].status == 0)
						{
							buffer = &curReading->buffers[idx];
							buffer->status = 1;
							
							break;
						}
					}
				}
				
				if(buffer != NULL)
				{
					[self fillAudioBuffer:buffer];
				}
			}
			else if(curReading->readerStatus >= AVAssetReaderStatusCompleted)
			{
				ExtAudioFileDispose(curReading->fileRef);
				curReading->fileRef = NULL;
			}
		}
		else 
		{
			// Sequencer is not playing at this time...
			
			if(curReading != NULL)
			{
				// If the file is open, close it
				if(curReading->fileRef != NULL)
				{
					ExtAudioFileDispose(curReading->fileRef);
					curReading->fileRef = NULL;
				}
				
				curReading->firstBufferLoaded = NO;		// Reload the first buffer as soon as is possible
				
				curReading = NULL;
			}
		}
		
        [NSThread sleepForTimeInterval:0.01]; // Let's save some cpu...
    }
    
END:
    [waitForAction release];
    
	NSLog(@"SequencerOperation --");
}


- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;
{
	*packetsInBuffer = 0;
	
	if(curPlaying->noDataAvailable)
	{
		NSLog(@"Sequencer getNextAudioBuffer %@ noDataAvailable", curPlaying->name);

		return NULL;
	}
	
	@synchronized(self)
	{
		int idx2 = 0;
		
		for(int idx = 0; idx < 4; idx++)
		{
			if(curPlaying->buffers[idx].status == 3)
			{
				curPlaying->buffers[idx].status = 0;
				
				if(idx < 3)
				{
					idx2 = idx + 1;
				}
				
				break;
			}
		}
		
		for(; idx2 < 4; idx2++)
		{
			if(curPlaying->buffers[idx2].status == 2)
			{
				*packetsInBuffer = curPlaying->buffers[idx2].size / sizeof(UInt32);
				curPlaying->buffers[idx2].status = 3;
				
				NSLog(@"Sequencer getNextAudioBuffer %@ %p", curPlaying->name, curPlaying->buffers[idx2].data);

				return curPlaying->buffers[idx2].data;
			}
		}
	}
	
	curPlaying->noDataAvailable = YES;
	
	NSLog(@"Sequencer getNextAudioBuffer %@ noDataAvailable", curPlaying->name);

	return NULL;
}


- (NSUInteger) fillAudioBuffer:(audioBufferPtr)buffer
{
	OSStatus status = noErr;
	
	NSLog(@"Sequencer fillAudioBuffer %@", curReading->name);

	if(curReading->fileRef == NULL)
    {
		return 0;
	}
	
	// Read the audio
	AudioBufferList incomingAudio;
	incomingAudio.mNumberBuffers = 1;
	incomingAudio.mBuffers[0].mNumberChannels = numChannels;
	incomingAudio.mBuffers[0].mDataByteSize = kAudioDataBufferSize;
	incomingAudio.mBuffers[0].mData = buffer->data;
	UInt32 framesRead = kAudioDataBufferSize / outputFormat.mBytesPerFrame;
	status = ExtAudioFileRead(curReading->fileRef, &framesRead, &incomingAudio);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileRead", status);
		
		curReading->readerStatus = AVAssetReaderStatusFailed;
	}
	else
	{
		// NSLog(@"Read %ld frames", framesRead);
		
		if(framesRead == 0)
		{
			curReading->readerStatus = AVAssetReaderStatusCompleted;
		}
		else
		{
			curReading->readerStatus = AVAssetReaderStatusReading;
		}
	}
		
	buffer->size = incomingAudio.mBuffers[0].mDataByteSize;
	buffer->status = 2;
	
	curReading->noDataAvailable = NO;

	return incomingAudio.mBuffers[0].mDataByteSize;
}


- (BOOL) openAudioFile:(recordingPtr)recording
{
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

	if(recording->packets == 0 || streamFormat.mSampleRate != kSamplingRate)
	{
		NSLog(@"File %@ can't be used", recording->name);
		
		return NO;
	}
	
	NSLog(@"File %@ open", recording->name);
	NSLog(@"Duration: %.2f", (double)recording->packets / kSamplingRate);
	
	if(recording->firstPackets != 0)
	{
		SInt64 seekValue = recording->firstPackets;
		status = ExtAudioFileSeek(recording->fileRef, seekValue);
		if(status != noErr)
		{
			NSLog(@"Error %ld in ExtAudioFileSeek", status);
		}
		
		recording->firstPackets = 0;
	}

	recording->readerStatus = AVAssetReaderStatusReading;

	return YES;
}


- (void) reset
{
	@synchronized(self)
	{
		NSLog(@"Sequencer Operation Reset");
		
		for(int idx = 0; idx < totRecordings; idx++)
		{
			for(int idx2 = 0; idx2 < 4; idx2++)
			{
				recordings[idx].buffers[idx2].size = 0;
				recordings[idx].buffers[idx2].status = 0;
			}

			recordings[idx].loaded = NO;
			recordings[idx].played = NO;
			recordings[idx].firstBufferLoaded = NO;
			recordings[idx].noDataAvailable = YES;
			recordings[idx].readerStatus = 0;
		}
		
		curPlaying = NULL;
		curReading = NULL;
		
		startSamplePacket = -1;
		
		working = NO;
	}
}


- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset
{
	@synchronized(self)
	{		
		NSUInteger newStartPosition = time * kSamplingRate;
		
		if(reset)
		{
			[self reset];
		}
			
		startSamplePacket = newStartPosition;		
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
				
				break;
			}
		}
	}
			
	return (curPlaying != NULL);
}


- (void) loadFirstBuffer:(recordingPtr)recording
{
	UInt32 propertySize;
    AudioStreamBasicDescription streamFormat;
	NSUInteger startPacket = 0;
	SInt64 seekValue;
	NSInteger readerStatus = 0;
	AudioBufferList incomingAudio;
	UInt32 framesRead;
	
	NSLog(@"Sequencer loadFirstBuffer: %@", recording->name);
	
	ExtAudioFileRef fileRef = NULL;
	OSStatus status = ExtAudioFileOpenURL((CFURLRef)recording->file, &fileRef);
	if(status != noErr)
	{
		goto END;
	}
	
	status = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &outputFormat);
	if(status != noErr)
	{
		goto END;
	}
	
	propertySize = sizeof(recording->packets);
    status = ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_FileLengthFrames, &propertySize, &recording->packets);
	if(status != noErr)
	{
		goto END;
	}
    
	propertySize = sizeof(streamFormat);
    status = ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_FileDataFormat, &propertySize, &streamFormat);
	if(status != noErr)
	{
		goto END;
	}

	if(startSamplePacket != -1 && (startSamplePacket > recording->startPacket && startSamplePacket < recording->endPacket))
	{
		startPacket = startSamplePacket - recording->startPacket;
		
		seekValue = startPacket;
		status = ExtAudioFileSeek(fileRef, seekValue);
		if(status != noErr)
		{
			NSLog(@"Error %ld in ExtAudioFileSeek", status);
		}

		startSamplePacket = -1;
	}
	
	recording->firstPackets = 0;
	recording->buffers[0].status = 1;

	// Read the audio
	incomingAudio.mNumberBuffers = 1;
	incomingAudio.mBuffers[0].mNumberChannels = numChannels;
	incomingAudio.mBuffers[0].mDataByteSize = kAudioDataBufferSize;
	incomingAudio.mBuffers[0].mData = recording->buffers[0].data;
	framesRead = kAudioDataBufferSize / outputFormat.mBytesPerFrame;
	status = ExtAudioFileRead(fileRef, &framesRead, &incomingAudio);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileRead", status);
		
		readerStatus = AVAssetReaderStatusFailed;
	}
	else
	{
		NSLog(@"Read %ld frames", framesRead);
		
		if(framesRead == 0)
		{
			readerStatus = AVAssetReaderStatusCompleted;
		}
		else
		{
			readerStatus = AVAssetReaderStatusReading;
		}
	}
		
	if(readerStatus == AVAssetReaderStatusReading || readerStatus == AVAssetReaderStatusCompleted)
	{
		recording->buffers[0].size = incomingAudio.mBuffers[0].mDataByteSize;
		recording->buffers[0].status = 2;
		
		recording->firstPackets = startPacket + framesRead;
		recording->firstBufferLoaded = YES;
		
		recording->noDataAvailable = NO;
		recording->readerStatus = readerStatus;

		NSLog(@"Sequencer loadFirstBuffer: %@ - %u packets", recording->name, recording->firstPackets);
	}
END:
	if(fileRef != NULL)
	{
		ExtAudioFileDispose(fileRef);
	}
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
