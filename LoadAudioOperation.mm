//
//  LoadAudioOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 15/2/2013.
//


#import "LoadAudioOperation.h"
#import "DJMixer.h"


@implementation LoadAudioOperation

@synthesize mixer;
@synthesize waitForAction;
@synthesize fileURL;
@synthesize sizeAudioData1;
@synthesize sizeAudioData2;
@synthesize fillAudioData1;
@synthesize fillAudioData2;
@synthesize currentAudioBuffer;
@synthesize duration;
@synthesize packets;

// 44,100 x 16 x 2 = 1,411,200 bits per second (bps) = 1,411 kbps = ~142 KBytes/sec per channel
const size_t kAudioDataBufferSize = (1024 * 256);
const double kLatency = 0.011609977;	// 512 samples at (44100 samples per sec)


- (id) initWithAudioFile:(NSString*)audioFileUrl
{
	assert(audioFileUrl != nil);

	self = [super init];
    if(self != nil)
    {
        fileURL = [NSURL URLWithString:audioFileUrl];

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
		
		if([self openAudioFile])
		{						
			audioData1 = (UInt32*)malloc(kAudioDataBufferSize);
			audioData2 = (UInt32*)malloc(kAudioDataBufferSize);
			if(audioData1 == NULL || audioData2 == NULL)
			{
				[self dealloc];				
				return nil;
			}
		}
		else
		{
			[self dealloc];
			return nil;
		}
    }
    
    return self;
}


- (void) dealloc
{
	if(fileRef != NULL)
	{
		ExtAudioFileDispose(fileRef);
	}
	
    free(audioData1);   
    free(audioData2);
  	
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
		
		if(readerStatus == AVAssetReaderStatusCompleted)
		{
			if(mixer.loop)
			{
				SInt64 seekValue = 0;
				OSStatus status = ExtAudioFileSeek(fileRef, seekValue);
				if(status != noErr)
				{
					NSLog(@"Error %ld in ExtAudioFileSeek", status);
					
					readerStatus = AVAssetReaderStatusFailed;
				}
				else
				{
					readerStatus = AVAssetReaderStatusReading;
				}
			}
			else
			{
				[self deactivate];
			}
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
		
		if(!fillAudioData1 && !fillAudioData2)
		{
			[NSThread sleepForTimeInterval:0.1]; // Let's save some cpu...
		}
    }
    
END:
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
		NSInteger audioPackets = (sizeAudioData2 / sizeof(UInt32));
		if(audioPackets != 0)
		{
			fillAudioData1 = YES;

			currentAudioBuffer = 2;
			
			*packetsInBuffer = audioPackets;
		}
		else
		{
			// NSLog(@"No data for audioData2");
		}

		return audioData2;
    }
    else
    {
		NSInteger audioPackets = (sizeAudioData1 / sizeof(UInt32));
		if(audioPackets != 0)
		{
			fillAudioData2 = YES;
			
			currentAudioBuffer = 1;
			
			*packetsInBuffer = audioPackets;
		}
		else
		{
			// NSLog(@"No data for audioData1");
		}
		
		return audioData1;
    }
}


- (NSUInteger) fillAudioBuffer:(void*)audioBuffer
{
	OSStatus status = noErr;
	
	if(fileRef == NULL)
    {
		return 0;
	}
	
	// Read the audio
	AudioBufferList incomingAudio;
	incomingAudio.mNumberBuffers = 1;
	incomingAudio.mBuffers[0].mNumberChannels = numChannels;
	incomingAudio.mBuffers[0].mDataByteSize = kAudioDataBufferSize;
	incomingAudio.mBuffers[0].mData = audioBuffer;
	UInt32 framesRead = kAudioDataBufferSize / outputFormat.mBytesPerFrame;
	status = ExtAudioFileRead(fileRef, &framesRead, &incomingAudio);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileRead", status);
		
		readerStatus = AVAssetReaderStatusFailed;
	}
	else
	{
		// NSLog(@"Read %ld frames", framesRead);
		
		if(framesRead == 0)
		{
			readerStatus = AVAssetReaderStatusCompleted;
		}
		else
		{
			readerStatus = AVAssetReaderStatusReading;
		}
	}

	return incomingAudio.mBuffers[0].mDataByteSize;
}


- (BOOL) openAudioFile
{
	OSStatus status = ExtAudioFileOpenURL((CFURLRef)fileURL, &fileRef);
	if(status != noErr)
	{
		return NO;
	}
	
	status = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), &outputFormat);
	if(status != noErr)
	{
		return NO;
	}

    UInt32 propertySize = sizeof(packets);
    status = ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_FileLengthFrames, &propertySize, &packets);
	if(status != noErr)
	{
		return NO;
	}
    
    AudioStreamBasicDescription streamFormat;
    propertySize = sizeof(streamFormat);
    status = ExtAudioFileGetProperty(fileRef, kExtAudioFileProperty_FileDataFormat, &propertySize, &streamFormat);
	if(status != noErr)
	{
		return NO;
	}

	if(packets == 0 || streamFormat.mSampleRate != kSamplingRate)
	{
		NSLog(@"File %@ can't be used", [fileURL path]);

		return NO;
	}

	NSLog(@"File %@ open", [fileURL path]);
	NSLog(@"Duration: %.2f", (double)packets / kSamplingRate);
	
	return YES;
}


- (void) reset
{
	@synchronized(self)
	{
		NSLog(@"Operation Reset");
		
		noDataAvailable = NO;
		
		fillAudioData1 = YES;
		fillAudioData2 = NO;
		
		currentAudioBuffer = 0;		
		readerStatus = 0;
	}
}


- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset
{
	@synchronized(self)
	{		
		NSUInteger newStartPosition = time * kSamplingRate;
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
		
		SInt64 seekValue = newStartPosition;
		OSStatus status = ExtAudioFileSeek(fileRef, seekValue);
		if(status != noErr)
		{
			NSLog(@"Error %ld in ExtAudioFileSeek", status);
		}
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
