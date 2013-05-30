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
@synthesize settings;
@synthesize reader;
@synthesize output;
@synthesize audioBuffersSize;
@synthesize noDataAvailable;
@synthesize endReading;
@synthesize curStartPacket;
@synthesize curEndPacket;
@synthesize playingIdx;
@synthesize readingIdx;

const size_t kSampleBufferSize = 32768;
// 44,100 x 16 x 2 = 1,411,200 bits per second (bps) = 1,411 kbps = ~142 KBytes/sec
const size_t kAudioDataBufferSize = (1024 * 256) + kSampleBufferSize;

- (id) initWithRecords:(NSString*)recordsFile
{
	self = [super init];
    if(self != nil)
    {
		audioBuffersSize = kAudioDataBufferSize;

		[self setRecords:recordsFile];

		[self setQueuePriority:NSOperationQueuePriorityNormal];
		
		settings = [[NSDictionary alloc] initWithObjectsAndKeys:
						[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
						// [NSNumber numberWithInt:44100.0], AVSampleRateKey,            // Not supported
						// [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,           // Not Supported
						[NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
						[NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
						[NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
						[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
						nil];
		
		startSamplePacket = -1;
		restartSamplePacket = -1;
		currentSamplePacket = -1;
		
		curPlaying = NULL;
		curReading = NULL;
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

	for(int idx = 0; idx < totRecordings; idx++)
	{
		for(int idx2 = 0; idx2 < 4; idx2++)
		{
			free(recordings[idx].buffers[idx2].data);
		}

		[recordings[idx].asset release];
	}
    	
	free(recordings);
	recordings = NULL;

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
			
			[recordings[idx].asset release];
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
						assert(recordings != NULL);
						
						recordings[totRecordings].name = [fileName copy];
						recordings[totRecordings].asset = theAsset;
						recordings[totRecordings].track = theTrack;
						recordings[totRecordings].startPacket = [[record objectForKey:@"startPacket"] integerValue];
						recordings[totRecordings].endPacket = [[record objectForKey:@"endPacket"] integerValue];
						recordings[totRecordings].duration = theAsset.duration;
						recordings[totRecordings].packets = ((double)theAsset.duration.value / (double)theAsset.duration.timescale) * 44100.0;
						
						for(int idx = 0; idx < 4; idx++)
						{
							recordings[totRecordings].buffers[idx].data = (UInt32*)malloc(audioBuffersSize);
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
			
			NSLog(@"Sequencer recording %@ can't be used", fileName);
		}
		
		// If some recordings intersect, the newer one takes precedence
		if(totRecordings > 1)
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
		
		NSLog(@"Sequencer recordings: %d", totRecordings);
		for(int idx = 0; idx < totRecordings; idx++)
		{
			double start = (double)recordings[idx].startPacket / 44100.0;
			double end = (double)recordings[idx].endPacket / 44100.0;
			NSLog(@"%@ %d packets from %d to %d - %.1f to %.1f", recordings[idx].name, recordings[idx].packets, recordings[idx].startPacket, recordings[idx].endPacket, start, end);
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
			// Sequencer is playing at thgis time...
			
			if(curReading != curPlaying)
			{
				if(curReading != NULL)
				{
					curReading->firstBufferLoaded = NO;
				}

				// If the recording to read is changed deactivate the current reader if any
				if(reader != nil)
				{
					[reader cancelReading];
					[reader release];
					reader = nil;
				}
								
				curReading = curPlaying;

				// If the reader is not active, activate it for the recording to read
				if(reader == nil)
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
				[reader cancelReading];
				[reader release];
				reader = nil;
			}
		}
		else 
		{
			// Sequencer is not playiong at this time...
			
			if(curReading != NULL)
			{
				// If the reader is still active, deactivate it
				if(reader != nil)
				{
					[reader cancelReading];
					[reader release];
					reader = nil;
				}
				
				curReading->firstBufferLoaded = NO;		// Reload the first buffer as soon as is possible
				
				curReading = NULL;
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
/*
    AVAssetReaderStatusUnknown = 0,
    AVAssetReaderStatusReading,
    AVAssetReaderStatusCompleted,
    AVAssetReaderStatusFailed,
    AVAssetReaderStatusCancelled,
*/
	NSLog(@"Sequencer fillAudioBuffer %@", curReading->name);

	if(curReading->readerStatus >= AVAssetReaderStatusCompleted) // Gets also AVAssetReaderStatusFailed and AVAssetReaderStatusCancelled
	{		
		return 0;
	}
	
	Byte *audioBuffer = (Byte*)buffer->data;	
    NSUInteger dataIdx = 0;
  
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
 					currentSamplePacket += dataLen / 4;
					
                    OSStatus err = CMBlockBufferCopyDataBytes(blockBuffer, 0, dataLen, audioBuffer + dataIdx);

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
				NSLog(@"Sequencer AVAssetReaderStatus Failed");

				restartSamplePacket = currentSamplePacket;
			}
			
			NSLog(@"Sequencer copyNextSampleBuffer returned nil - Status %d", curReading->readerStatus);

			break;
        }
    }
    	
	if(curReading->readerStatus >= AVAssetReaderStatusCompleted) // Gets also AVAssetReaderStatusFailed and AVAssetReaderStatusCancelled
    {
		NSLog(@"Sequencer AVAssetReaderStatus: %d", curReading->readerStatus);

		NSLog(@"%u packets - %g secs", currentSamplePacket, (double)currentSamplePacket / 44100.0);

		[reader cancelReading];
		[reader release];
		reader = nil;
	}
	
	buffer->size = dataIdx;
	buffer->status = 2;
	
	curReading->noDataAvailable = NO;

    return dataIdx;
}


- (BOOL) openAudioFile:(recordingPtr)recording
{
	NSLog(@"Sequencer openAudioFile: %@", recording->name);
	
	NSError *error = nil;
	reader = [[AVAssetReader alloc] initWithAsset:recording->asset error:&error];
	if(reader == nil)
	{
		NSLog(@"Error %@ opening file %@", [error description], recording->name);
		return NO;
	}
		
	output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:recording->track outputSettings:settings];
	if(output == nil)
	{
		NSLog(@"Error in assetReaderTrackOutputWithTrack()");
		return NO;
	}
	
	[reader addOutput:output];
	
	currentSamplePacket = 0;
	
	NSUInteger startPacket = 0;
	
	if(recording->firstBufferLoaded)
	{
		startPacket = recording->firstPackets;
	}	
	else if(startSamplePacket != -1 && startSamplePacket > recording->startPacket)
	{
		startPacket = startSamplePacket - recording->startPacket;
		
		startSamplePacket = -1;
	}
	
	reader.timeRange = CMTimeRangeMake(CMTimeMake(startPacket, 44100), kCMTimePositiveInfinity);
	
	[reader startReading];
	
	recording->readerStatus = reader.status;

	return YES;
}


- (void) reset
{
	@synchronized(self)
	{
		NSLog(@"Sequencer Operation Reset");

		if(reader != nil)
		{
			[reader cancelReading];
			[reader release];
			reader = nil;
		}
		
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
		
		readingIdx = -1;
		playingIdx = -1;
		
		curPlaying = NULL;
		curReading = NULL;
		
		startSamplePacket = -1;
		restartSamplePacket = -1;
		currentSamplePacket = -1;
		
		working = NO;
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
					double secs = (double)(curPlaying->endPacket - curPlaying->startPacket) / 44100.0;
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
	NSError *error = nil;
	AVAssetReader *theReader = [[AVAssetReader alloc] initWithAsset:recording->asset error:&error];
	if(theReader == nil)
	{
		NSLog(@"Error %@ opening file %@", [error description], recording->name);
		return;
	}
	
	AVAssetReaderTrackOutput *theOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:recording->track outputSettings:settings];
	if(theOutput == nil)
	{
		NSLog(@"Error in assetReaderTrackOutputWithTrack()");
		return;
	}
	
	[theReader addOutput:theOutput];

	NSUInteger startPacket = 0;

	if(startSamplePacket != -1 && (startSamplePacket > recording->startPacket && startSamplePacket < recording->endPacket))
	{
		startPacket = startSamplePacket - recording->startPacket;
		theReader.timeRange = CMTimeRangeMake(CMTimeMake(startPacket, 44100), kCMTimePositiveInfinity);
		
		startSamplePacket = -1;
	}
	
	[theReader startReading];
	
	recording->firstPackets = 0;
	
	Byte *audioBuffer = (Byte*)recording->buffers[0].data;
	recording->buffers[0].status = 1;
	
	NSUInteger dataIdx = 0;
	
    while(theReader.status == AVAssetReaderStatusReading)
    {
        CMSampleBufferRef sampleBuffer = [theOutput copyNextSampleBuffer];		
        if(sampleBuffer != NULL)
        {
            CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
            if(blockBuffer != NULL)
            {
				size_t dataLen = CMBlockBufferGetDataLength(blockBuffer);				
				if(dataLen > 0)
                {
					OSStatus err = CMBlockBufferCopyDataBytes(blockBuffer, 0, dataLen, audioBuffer + dataIdx);
					
                    CMSampleBufferInvalidate(sampleBuffer);
                    CFRelease(sampleBuffer);
					
                    if(err != kCMBlockBufferNoErr)
                    {
                        NSLog(@"Sequencer CMBlockBufferCopyDataBytes returned error %lu", err);
						break;
                    }
                }
				else
				{
					NSLog(@"Sequencer No Data");
				}
                
                dataIdx += dataLen;
                if(dataIdx >= audioBuffersSize - kSampleBufferSize)
                {
                    NSLog(@"AudioBuffer %p filled with %d bytes", audioBuffer, dataIdx);                    
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
			if(theReader.status == AVAssetReaderStatusFailed)
			{
				NSLog(@"Sequencer AVAssetReaderStatus Failed");
			}
			
			NSLog(@"Sequencer copyNextSampleBuffer returned nil - Status %d", theReader.status);			
			break;
        }
    }
	
	if(theReader.status == AVAssetReaderStatusReading || theReader.status == AVAssetReaderStatusCompleted)
	{
		recording->buffers[0].size = dataIdx;
		recording->buffers[0].status = 2;
		
		recording->firstPackets = startPacket + (dataIdx / sizeof(UInt32));
		recording->firstBufferLoaded = YES;
		
		recording->noDataAvailable = NO;

		NSLog(@"Sequencer loadFirstBuffer: %@ - %u packets", recording->name, recording->firstPackets);
	}
	
	[theReader cancelReading];
	[theReader release];
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
