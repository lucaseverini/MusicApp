//
//  LoadAudioOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 15/2/2013.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioFile.h>
#import "LoadAudioOperation.h"
#import "DJMixer.h"
#import "MusicAppAppDelegate.h"


@implementation LoadAudioOperation

@synthesize mixer;
@synthesize waitForAction;
@synthesize fileURL;
@synthesize asset;
@synthesize settings;
@synthesize track;
@synthesize trackCount;
@synthesize reader;
@synthesize output;
@synthesize audioBuffersSize;
@synthesize sizeAudioData1;
@synthesize sizeAudioData2;
@synthesize fillAudioData1;
@synthesize fillAudioData2;
@synthesize endReading;
@synthesize currentAudioBuffer;
@synthesize duration;
@synthesize packets;

const size_t kSampleBufferSize = 32768;
// 44,100 x 16 x 2 = 1,411,200 bits per second (bps) = 1,411 kbps = ~142 KBytes/sec
const size_t kAudioDataBufferSize = (1024 * 256) + kSampleBufferSize;

- (id) initWithAudioFile:(NSString*)audioFileUrl
{
	assert(audioFileUrl != nil);

	self = [super init];
    if(self != nil)
    {
        fileURL = [NSURL URLWithString:audioFileUrl];

        [self setQueuePriority:NSOperationQueuePriorityVeryHigh];
        		      
        asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
        if(asset == nil)
        {
            return NULL;
        }
		
		duration = asset.duration;
		packets = ((double)duration.value / (double)duration.timescale) * 44100.0;
		        
        NSArray *tracks = [asset tracks];
        trackCount = [tracks count];
        if(trackCount < 1)
        {
            [asset release];
            asset = nil;
            
            return NULL;
        }
        
        track = [tracks objectAtIndex:0];
        assert(track != nil);
        
        settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                  [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                  // [NSNumber numberWithInt:44100.0], AVSampleRateKey,            // Not supported
                                  // [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,           // Not Supported
                                  [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                  [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                  [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                                  [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                  nil];

        audioBuffersSize = kAudioDataBufferSize;
        
        audioData1 = (UInt32*)malloc(audioBuffersSize);
        audioData2 = (UInt32*)malloc(audioBuffersSize);
        if(audioData1 == NULL || audioData2 == NULL)
        {
            free(audioData1);
            audioData1 = NULL;
            
            free(audioData2);
            audioData2 = NULL;
            
            return NULL;
        }
		
		startSamplePacket = -1;
		restartSamplePacket = -1;
		currentSamplePacket = -1;
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

    free(audioData1);
    audioData1 = NULL;
   
    free(audioData2);
	audioData2 = NULL;
    
	[asset release];
    asset = nil;	
 	
	[super dealloc];
}


- (void) main 
{	    
	// NSLog(@"NSOperation %@ : Main for %@ ++", self, [fileURL path]);
    
    fillAudioData1 = YES;
	
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

		if(readerStatus != AVAssetReaderStatusCompleted)
		{
			if(fillAudioData1)
			{
				// NSLog(@"Fill audioDataBuffer1");
				
				@synchronized(self)
				{
					sizeAudioData1 = [self fillAudioBuffer:audioData1];
					if(sizeAudioData1 > 0)
					{
						fillAudioData1 = NO;
					}
				}
			}
			else if(fillAudioData2)
			{
				// NSLog(@"Fill audioDataBuffer2");

				@synchronized(self)
				{
					sizeAudioData2 = [self fillAudioBuffer:audioData2];
					if(sizeAudioData2 > 0)
					{
						fillAudioData2 = NO;
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
    
	// NSLog(@"NSOperation %@ : Main for %@ --", self, [fileURL path]);
}


- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;
{
	*packetsInBuffer = 0;
	
	if(readerStatus == AVAssetReaderStatusCompleted)
	{
		if(currentAudioBuffer == 1)
		{
			sizeAudioData1 = 0;
			
			if(sizeAudioData2 == 0)
			{
				noDataAvailable = YES;
				return NULL;
			}
		}
		else if(currentAudioBuffer == 2)
		{
			sizeAudioData2 = 0;

			if(sizeAudioData1 == 0)
			{
				noDataAvailable = YES;
				return NULL;
			}
		}
	}
	
    if(currentAudioBuffer == 1)
    {
        fillAudioData1 = YES;

        currentAudioBuffer = 2;
        
        *packetsInBuffer = (sizeAudioData2 / sizeof(UInt32));
        
        return audioData2;
    }
    else
    {
        fillAudioData2 = YES;
        
        currentAudioBuffer = 1;
        
        *packetsInBuffer = (sizeAudioData1 / sizeof(UInt32));
        
        return audioData1;
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
	if(readerStatus == AVAssetReaderStatusCompleted || readerStatus == AVAssetReaderStatusCancelled)
	{		
		return 0;
	}
	
	if(reader == nil)
    {
		// NSLog(@"Reader == nil");
		
		[self openAudioFile];
	}

    NSUInteger dataIdx = 0;
	
	// NSLog(@"AVAssetReaderStatus-1: %d", readerStatus);
  
    while((readerStatus = reader.status) == AVAssetReaderStatusReading)
    {
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
		
		readerStatus = reader.status;
		
        if(sampleBuffer != NULL)
        {
            CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
            if(blockBuffer != NULL)
            {
				size_t dataLen = CMBlockBufferGetDataLength(blockBuffer);
				
				if(dataLen > 0)
                {					
					// NSLog(@"Read %lu bytes", dataLen);
 					currentSamplePacket += dataLen / 4;
					// NSLog(@"currentSamplePacket: %d", currentSamplePacket);
					
                    OSStatus err = CMBlockBufferCopyDataBytes(blockBuffer, 0, dataLen, (Byte*)audioBuffer + dataIdx);

                    CMSampleBufferInvalidate(sampleBuffer);
                    CFRelease(sampleBuffer);

                    if(err != kCMBlockBufferNoErr)
                    {
                        NSLog(@"CMBlockBufferCopyDataBytes returned error %lu", err);
                        
						return 0;
                    }
                }
				else
				{
					NSLog(@"No Data");
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
                NSLog(@"CMSampleBufferGetDataBuffer returned NULL");
                
                break;
            }
        }
        else
        {
			if(readerStatus == AVAssetReaderStatusFailed)  // If reader must be restarted, save the current packet
			{
				restartSamplePacket = currentSamplePacket;
			}
			
			// NSLog(@"copyNextSampleBuffer returned nil - Status %d", readerStatus);

			break;
        }
    }
    	
	// NSLog(@"AVAssetReaderStatus-2: %d", readerStatus);

	if(readerStatus == AVAssetReaderStatusCompleted || readerStatus == AVAssetReaderStatusFailed || readerStatus == AVAssetReaderStatusCancelled)
    {        
		[reader cancelReading];
		[reader release];
		reader = nil;

		if(readerStatus == AVAssetReaderStatusCompleted && mixer.loop)
		{
			[self openAudioFile];
		}
	}

    return dataIdx;
}


- (BOOL) openAudioFile
{    
	assert(fileURL != nil);

	// NSLog(@"openAudioFile: %@", [[fileURL path] lastPathComponent]);
	
	NSError *error = nil;
	reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
	if(reader == nil)
	{
		NSLog(@"Error %@ opening file %@", [error description], [fileURL path]);
		return NO;
	}
		
	output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:settings];
	if(output == nil)
	{
		NSLog(@"Error in assetReaderTrackOutputWithTrack()");
		return NO;
	}
	
	[reader addOutput:output];
	
	currentSamplePacket = 0;

	if(restartSamplePacket != -1)
	{
//#if TARGET_IPHONE_SIMULATOR
		//NSLog(@"Restart reading %@ from packet %d", [[fileURL path] lastPathComponent], restartSamplePacket);
//#endif
		reader.timeRange = CMTimeRangeMake(CMTimeMake(restartSamplePacket, 44100), kCMTimePositiveInfinity);
		
		currentSamplePacket = restartSamplePacket;
		restartSamplePacket = -1;
	}
	else if(startSamplePacket != -1)
	{
//#if TARGET_IPHONE_SIMULATOR
		//NSLog(@"Start reading %@ from packet %d", [[fileURL path] lastPathComponent] , startSamplePacket);
//#endif
		reader.timeRange = CMTimeRangeMake(CMTimeMake(startSamplePacket, 44100), kCMTimePositiveInfinity);
		
		currentSamplePacket = startSamplePacket;
		startSamplePacket = -1;
	}
	
	[reader startReading];
	
	readerStatus = reader.status;

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
		
		noDataAvailable = NO;
		
		fillAudioData1 = YES;
		fillAudioData2 = NO;
		
		currentAudioBuffer = 0;		
		readerStatus = 0;
		
		startSamplePacket = -1;
		restartSamplePacket = -1;
		currentSamplePacket = -1;

		free(audioData1);
		audioData1 = (UInt32*)malloc(audioBuffersSize);
		
		free(audioData2);
        audioData2 = (UInt32*)malloc(audioBuffersSize);
	}
}


- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset
{
	@synchronized(self)
	{		
		NSUInteger newStartPosition = time * 44100.0;
		if(newStartPosition > packets)
		{
			if(mixer.loop)
			{
				newStartPosition = newStartPosition % packets;
			}
			else
			{
				return;
			}
		}
		
		if(reset)
		{
			[self reset];
		}
			
		startSamplePacket = newStartPosition;
	}
}


- (void) setCurrentPlayPosition:(NSTimeInterval)time
{
	@synchronized(self)
	{
		NSUInteger newStartPosition = time * 44100.0;
		if(newStartPosition > packets)
		{
			newStartPosition = newStartPosition % packets;
		}

		startSamplePacket = newStartPosition;
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

@end
