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
//@synthesize fileURL;
//@synthesize asset;
@synthesize settings;
//@synthesize track;
//@synthesize trackCount;
@synthesize reader;
@synthesize output;
@synthesize audioBuffersSize;
//@synthesize sizeAudioData1;
//@synthesize sizeAudioData2;
//@synthesize fillAudioData1;
//@synthesize fillAudioData2;
//@synthesize currentAudioBuffer;
@synthesize noDataAvailable;
@synthesize endReading;
//@synthesize duration;
//@synthesize packets;
//@synthesize startPacket;
//@synthesize endPacket;
@synthesize curStartPacket;
@synthesize curEndPacket;

const size_t kSampleBufferSize = 32768;
// 44,100 x 16 x 2 = 1,411,200 bits per second (bps) = 1,411 kbps = ~142 KBytes/sec
const size_t kAudioDataBufferSize = (1024 * 256) + kSampleBufferSize;

- (id) initWithRecordsFile:(NSString*)recordsFile
{
	self = [super init];
    if(self != nil)
    {
		audioBuffersSize = kAudioDataBufferSize;

		NSMutableArray *records = [NSMutableArray arrayWithContentsOfFile:recordsFile];
		if(records != nil && [records count] > 0)
		{				
			NSArray *sortedRecords = [records sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
											  {
												  int result = [[obj1 objectForKey:@"startPacket"] compare:[obj2 objectForKey:@"startPacket"]];
												  if(result == 0)
												  {
													  result = [[obj1 objectForKey:@"recDate"] compare:[obj2 objectForKey:@"recDate"]];
												  }
												  
												  return result;
											  }];
						
			for(NSDictionary *record in sortedRecords)
			{
				NSString *fileName = [record objectForKey:@"fileName"];

				NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
				NSURL *fileURL = [NSURL fileURLWithPath:[[paths objectAtIndex:0] stringByAppendingPathComponent:fileName]];
							  
				AVURLAsset *theAsset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
				if(theAsset != nil)
				{									
					NSArray *tracks = [theAsset tracks];
					if([tracks count] > 0)
					{										
						AVAssetTrack *theTrack = [tracks objectAtIndex:0];
						if(theTrack != nil)
						{
							recordings = (recordingPtr)realloc(recordings, sizeof(recording) * (totRecordings + 1));
							if(recordings == NULL)
							{
								[self release];
								
								return NULL;
							}

							recordings[totRecordings].name = [fileName copy];
							recordings[totRecordings].asset = theAsset;
							recordings[totRecordings].track = theTrack;
							recordings[totRecordings].startPacket = [[record objectForKey:@"startPacket"] integerValue];
							recordings[totRecordings].endPacket = [[record objectForKey:@"endPacket"] integerValue];
							recordings[totRecordings].duration = theAsset.duration;
							recordings[totRecordings].packets = ((double)theAsset.duration.value / (double)theAsset.duration.timescale) * 44100.0;
							recordings[totRecordings].audioData1 = (UInt32*)malloc(audioBuffersSize);
							recordings[totRecordings].audioData2 = (UInt32*)malloc(audioBuffersSize);
							recordings[totRecordings].sizeAudioData1 = 0;
							recordings[totRecordings].sizeAudioData2 = 0;
							recordings[totRecordings].fillAudioData1 = NO;
							recordings[totRecordings].fillAudioData2 = NO;
							recordings[totRecordings].currentAudioBuffer = 0;
							recordings[totRecordings].loaded = NO;
							recordings[totRecordings].played = NO;
							recordings[totRecordings].noDataAvailable = YES;
							totRecordings++;
							
							continue;
						}
					}
				}
				
				NSLog(@"Sequencer recording %@ can't be used", fileName);
			}
			
			NSLog(@"Sequencer recordings: %d", totRecordings);
			for(int idx = 0; idx < totRecordings; idx++)
			{
				NSLog(@"%@ %d packets from %d to %d", recordings[idx].name, recordings[idx].packets, recordings[idx].startPacket, recordings[idx].endPacket);
			}
			
			[self setQueuePriority:NSOperationQueuePriorityHigh];
			
			settings = [[NSDictionary alloc] initWithObjectsAndKeys:
									  [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
									  // [NSNumber numberWithInt:44100.0], AVSampleRateKey,            // Not supported
									  // [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,           // Not Supported
									  [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
									  [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
									  [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
									  [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
									  nil];
/*
			audioData1 = (UInt32*)malloc(audioBuffersSize);
			audioData2 = (UInt32*)malloc(audioBuffersSize);
			if(audioData1 == NULL || audioData2 == NULL)
			{
				[self release];

				return NULL;
			}
*/			
			startSamplePacket = -1;
			restartSamplePacket = -1;
			currentSamplePacket = -1;
			
			//curPlaying = &recordings[playingIdx];
			curPlaying = NULL;
			curReading = NULL;
		}
		else
		{
			noDataAvailable = YES;
		}
    }
    
    return self;
}


- (void) dealloc
{
	if(reader != nil)
	{
		[reader cancelReading];
		[reader release];
		reader = nil;
	}

    //free(audioData1);
    //audioData1 = NULL;
   
    //free(audioData2);
	//audioData2 = NULL;
    	
	free(recordings);
	recordings = NULL;
 	
	// release all assets...
	//[asset release];
    //asset = nil;

	[super dealloc];
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

		if(curReading == NULL || curReading->readerStatus == AVAssetReaderStatusCompleted)
		{
			curReading = NULL;
			
			if(readingIdx == totRecordings)
			{
				readingIdx = 0;
			}
			
			while(readingIdx < totRecordings)
			{
				if(recordings[readingIdx].noDataAvailable)
				{
					if(reader != NULL)
					{
						[reader cancelReading];
						[reader release];
						reader = nil;
					}

					curReading = &recordings[readingIdx++];
					
					[self openAudioFile];
					break;
				}
				
				readingIdx++;
			}
		}

		if(curReading != NULL && curReading->readerStatus != AVAssetReaderStatusCompleted)
		{
			if(curReading->fillAudioData1)
			{
				@synchronized(self)
				{
					curReading->sizeAudioData1 = [self fillAudioBuffer:curReading->audioData1];
					if(curReading->sizeAudioData1 > 0)
					{
						curReading->fillAudioData1 = NO;
					}
				}
			}
			else if(curReading->fillAudioData2)
			{
				@synchronized(self)
				{
					curReading->sizeAudioData2 = [self fillAudioBuffer:curReading->audioData2];
					if(curReading->sizeAudioData2 > 0)
					{
						curReading->fillAudioData2 = NO;
					}
				}
			}
		}
		
        [NSThread sleepForTimeInterval:0.01]; // Let's save some cpu...
    }
    
END:
    if(reader != nil)
    {
        [reader cancelReading];
        [reader release];
		reader = nil;
    }

    [waitForAction release];
    
	NSLog(@"SequencerOperation --");
}


- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;
{
	NSLog(@"Sequencer getNextAudioBuffer %@", curPlaying->name);

	*packetsInBuffer = 0;
	
	if(curPlaying->readerStatus == AVAssetReaderStatusCompleted)
	{
		if(curPlaying->currentAudioBuffer == 1)
		{
			curPlaying->sizeAudioData1 = 0;
			
			if(curPlaying->sizeAudioData2 == 0)
			{
				curPlaying->noDataAvailable = YES;
				return NULL;
			}
		}
		else if(curPlaying->currentAudioBuffer == 2)
		{
			curPlaying->sizeAudioData2 = 0;

			if(curPlaying->sizeAudioData1 == 0)
			{
				curPlaying->noDataAvailable = YES;
				return NULL;
			}
		}
	}
		
    if(curPlaying->currentAudioBuffer == 1)
    {
        curPlaying->fillAudioData1 = YES;

        curPlaying->currentAudioBuffer = 2;
        
        *packetsInBuffer = (curPlaying->sizeAudioData2 / sizeof(UInt32));
        
        return curPlaying->audioData2;
    }
    else
    {
        curPlaying->fillAudioData2 = YES;
        
        curPlaying->currentAudioBuffer = 1;
        
        *packetsInBuffer = (curPlaying->sizeAudioData1 / sizeof(UInt32));
        
        return curPlaying->audioData1;
    }
}


- (NSUInteger) fillAudioBuffer:(void*)audioBuffer
{
/*
    AVAssetReaderStatusUnknown = 0,
    AVAssetReaderStatusReading,
    AVAssetReaderStatusCompleted,
    AVAssetReaderStatusFailed,
    AVAssetReaderStatusCancelled,
*/
	if(curReading->readerStatus == AVAssetReaderStatusCompleted || curReading->readerStatus == AVAssetReaderStatusCancelled)
	{		
		return 0;
	}
	
	if(reader == nil)
    {
		NSLog(@"Reader == nil");
		
		[self openAudioFile];
	}

    NSUInteger dataIdx = 0;
	
	// NSLog(@"AVAssetReaderStatus-1: %d", readerStatus);
  
    while((curReading->readerStatus = reader.status) == AVAssetReaderStatusReading)
    {
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
		
		curReading->readerStatus = reader.status;
		
        if(sampleBuffer != NULL)
        {
            CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
            if(blockBuffer != NULL)
            {
				size_t dataLen = CMBlockBufferGetDataLength(blockBuffer);
				
				if(dataLen > 0)
                {
					curReading->noDataAvailable = NO;

					// NSLog(@"Read %lu bytes", dataLen);
 					currentSamplePacket += dataLen / 4;
					// NSLog(@"currentSamplePacket: %d", currentSamplePacket);
					
                    OSStatus err = CMBlockBufferCopyDataBytes(blockBuffer, 0, dataLen, (Byte*)audioBuffer + dataIdx);

                    CMSampleBufferInvalidate(sampleBuffer);
                    CFRelease(sampleBuffer);

                    if(err != kCMBlockBufferNoErr)
                    {
                        NSLog(@"Sequencer CMBlockBufferCopyDataBytes returned error %lu", err);
                        
						return 0;
                    }
                }
				else
				{
					NSLog(@"Sequencer No Data");
				}
                
                dataIdx += dataLen;
                if(dataIdx >= audioBuffersSize - kSampleBufferSize)
                {
                    // NSLog(@"AudioBuffer %p filled with %d bytes", audioBuffer, dataIdx);
                    
                    break;
                }
            }
            else
            {
                NSLog(@"Sequencer CMSampleBufferGetDataBuffer returned NULL");
                
                break;
            }
        }
        else
        {
			if(curReading->readerStatus == AVAssetReaderStatusFailed)  // If reader must be restarted, save the current packet
			{
				restartSamplePacket = currentSamplePacket;
			}
			
			NSLog(@"Sequencer copyNextSampleBuffer returned nil - Status %d", curReading->readerStatus);

			break;
        }
    }
    	
	NSLog(@"Sequencer AVAssetReaderStatus: %d", curReading->readerStatus);

	if(curReading->readerStatus == AVAssetReaderStatusCompleted || curReading->readerStatus == AVAssetReaderStatusFailed || curReading->readerStatus == AVAssetReaderStatusCancelled)
    {
		[reader cancelReading];
		[reader release];
		reader = nil;
		
		curReading->loaded = YES;
	}

    return dataIdx;
}


- (BOOL) openAudioFile
{
	NSLog(@"Sequencer openAudioFile: %@", curReading->name);
	
	NSError *error = nil;
	reader = [[AVAssetReader alloc] initWithAsset:curReading->asset error:&error];
	if(reader == nil)
	{
		NSLog(@"Error %@ opening file %@", [error description], curReading->name);
		return NO;
	}
		
	output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:curReading->track outputSettings:settings];
	if(output == nil)
	{
		NSLog(@"Error in assetReaderTrackOutputWithTrack()");
		return NO;
	}
	
	[reader addOutput:output];
	
	currentSamplePacket = 0;
	// TEST!!
	//reader.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(44100 * 5, 44100));

	if(NO/*restartSamplePacket != -1*/)
	{
		NSLog(@"Sequencer Restart reading %@ from packet %d", curReading->name, restartSamplePacket);

		reader.timeRange = CMTimeRangeMake(CMTimeMake(restartSamplePacket, 44100), kCMTimePositiveInfinity);
		
		currentSamplePacket = restartSamplePacket;
		restartSamplePacket = -1;
	}
	else if(NO/*startSamplePacket != -1*/)
	{
		NSLog(@"Sequencer Start reading %@ from packet %d", curReading->name, startSamplePacket);

		reader.timeRange = CMTimeRangeMake(CMTimeMake(startSamplePacket, 44100), kCMTimePositiveInfinity);
		
		currentSamplePacket = startSamplePacket;
		startSamplePacket = -1;
	}
	
	[reader startReading];
	
	curReading->readerStatus = reader.status;
/*
	curStartPacket = curReading->startPacket;
	curEndPacket = curReading->endPacket;
	
	if(startSamplePacket > curStartPacket)
	{
		if(startSamplePacket < curEndPacket)
		{
			curStartPacket = startSamplePacket;
		}
		else
		{
			curStartPacket = 0;
			curEndPacket = 0;
		}
	}
	
	NSLog(@"Sequencer curStartPacket: %d", curStartPacket);
	NSLog(@"Sequencer curEndPacket: %d", curEndPacket);
*/
	curReading->fillAudioData1 = YES;
	curReading->fillAudioData2 = NO;
	curReading->currentAudioBuffer = 0;

	return YES;
}


- (void) reset
{
	@synchronized(self)
	{
		NSLog(@"Operation Reset");

		if(reader != nil)
		{
			[reader cancelReading];
			[reader release];
			reader = nil;
		}
		
		for(int idx = 0; idx < totRecordings; idx++)
		{
			recordings[idx].fillAudioData1 = NO;
			recordings[idx].fillAudioData2 = NO;
			recordings[idx].currentAudioBuffer = 0;
			recordings[idx].loaded = NO;
			recordings[idx].played = NO;
			recordings[idx].noDataAvailable = YES;
			curReading->readerStatus = 0;
		}
		
		readingIdx = 0;
		playingIdx = 0;
		
		curPlaying = NULL;
		curReading = NULL;

		//fillAudioData1 = YES;
		//fillAudioData2 = NO;
		
		//currentAudioBuffer = 0;
		//readerStatus = 0;
		
		startSamplePacket = -1;
		restartSamplePacket = -1;
		currentSamplePacket = -1;

		//free(audioData1);
		//audioData1 = (UInt32*)malloc(audioBuffersSize);
		
		//free(audioData2);
        //audioData2 = (UInt32*)malloc(audioBuffersSize);
		
		working = NO;
/*
		FIX IT
		curReading
		curPlaying
		etc...
*/
	}
}


- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset
{
	@synchronized(self)
	{		
		NSUInteger newStartPosition = time * 44100.0;
		
		if(reset)
		{
			[self reset];
		}
			
		startSamplePacket = newStartPosition;		
/*
		FIX IT
		if(curPlaying != NULL && curPlaying->startPacket != 0 && curPlaying->endPacket != 0)
		{
			curStartPacket = curPlaying->startPacket;
			curEndPacket = curPlaying->endPacket;
			
			if(newStartPosition > curStartPacket)
			{
				if(newStartPosition < curEndPacket)
				{
					curStartPacket = newStartPosition;
				}
				else
				{
					curStartPacket = 0;
					curEndPacket = 0;
				}
			}
			
			NSLog(@"Sequencer curStartPacket: %d", curStartPacket);
			NSLog(@"Sequencer curEndPacket: %d", curEndPacket);
		}
		else
		{
			curStartPacket = 0;
			curEndPacket = 0;
		}
*/
	}
}


- (void) setCurrentPlayPosition:(NSTimeInterval)time
{
	@synchronized(self)
	{
		NSUInteger newStartPosition = time * 44100.0;

		startSamplePacket = newStartPosition;
/*
		FIX IT
		if(curPlaying != NULL && curPlaying->startPacket != 0 && curPlaying->endPacket != 0)
		{
			curStartPacket = curPlaying->startPacket;
			curEndPacket = curPlaying->endPacket;
			
			if(newStartPosition > curStartPacket)
			{
				if(newStartPosition < curEndPacket)
				{
					curStartPacket = newStartPosition;
				}
				else
				{
					curStartPacket = 0;
					curEndPacket = 0;
				}
			}
			
			NSLog(@"Sequencer curStartPacket: %d", curStartPacket);
			NSLog(@"Sequencer curEndPacket: %d", curEndPacket);
		}
		else
		{
			curStartPacket = 0;
			curEndPacket = 0;
		}
*/
	}
}


- (void) activate
{
	active = YES;

	[waitForAction lock];
	[waitForAction signal];
	[waitForAction unlock];
}


- (void) deactivate
{
	active = NO;
	
	[waitForAction lock];
	[waitForAction signal];
	[waitForAction unlock];
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


- (BOOL) sequencerActive
{
	if(!active)
	{
		return NO;
	}

	NSUInteger packetIdx = mixer->durationPacketsIndex;

	if(curPlaying != NULL)
	{
		if(packetIdx < curPlaying->startPacket || packetIdx > curPlaying->endPacket || curPlaying->noDataAvailable)
		{
				curPlaying->noDataAvailable = YES;
				
				curPlaying->readerStatus = AVAssetReaderStatusCompleted;

			if(working)
			{
				NSLog(@"Sequencer Disactive %ld %@", mixer->durationPacketsIndex, curPlaying->name);
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
				if(!recordings[idx].noDataAvailable)
				{
					curPlaying = &recordings[idx];

					if(!working)
					{
						NSLog(@"Sequencer Active %ld %@ %u %u", mixer->durationPacketsIndex, curPlaying->name, curPlaying->startPacket, curPlaying->endPacket);
						working = YES;
						
						curPlaying->loaded = NO;
					}
				}
				
				break;
			}
		}
	}
			
	return (curPlaying != NULL);
}

/*
- (BOOL) sequencerActive
{
	if(curPlaying == NULL)
	{
		return NO;
	}
	
	NSUInteger startPacket = curPlaying->startPacket;
	NSUInteger endPacket = curPlaying->endPacket;
	
	if(active && !curPlaying->noDataAvailable && (mixer->durationPacketsIndex >= startPacket && mixer->durationPacketsIndex < endPacket))
	{
		if(!working)
		{
			NSLog(@"Sequencer Active - %ld %u %u", mixer->durationPacketsIndex, startPacket, endPacket);
			working = YES;
			
			curPlaying->loaded = NO;
		}
		
		return YES;
	}
	else
	{
		if(working)
		{
			NSLog(@"Sequencer Disactive - %ld %u %u", mixer->durationPacketsIndex, startPacket, endPacket);
			working = NO;
			
			curPlaying->noDataAvailable = YES;
			
			if(++playingIdx == totRecordings)
			{
				if(mixer.loop)
				{
					playingIdx = 0;
					curPlaying = &recordings[playingIdx];
				}
				else
				{
					curPlaying = NULL;
				}
			}
			else
			{
				curPlaying = &recordings[playingIdx];
			}
			
		}
		
		return NO;
	}
}
*/
@end
