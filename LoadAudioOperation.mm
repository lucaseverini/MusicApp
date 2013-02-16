//
//  LoadAudioOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 15/2/2013.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioFile.h>
#import "LoadAudioOperation.h"


@implementation LoadAudioOperation

@synthesize waitForAction;
@synthesize fileURL;
@synthesize asset;
@synthesize settings;
@synthesize track;
@synthesize trackCount;
@synthesize reader;
@synthesize output;
@synthesize audioData1;
@synthesize audioData2;
@synthesize audioBuffersSize;
@synthesize sizeAudioData1;
@synthesize sizeAudioData2;
@synthesize fillAudioData1;
@synthesize fillAudioData2;
@synthesize openFile;
@synthesize endReading;
@synthesize noDataAvailable;
@synthesize currentAudioBuffer;

const size_t kSampleBufferSize = 32768;
// 44,100 x 2 x 16 = 1,411,200 bits per second (bps) = 1,411 kbps = ~142 KBytes
const size_t kAudioDataBufferSize = (1024 * 512) + kSampleBufferSize; // 1 MB

- (id) initWithAudioFile:(NSString*)filePath
{
	self = [super init];
    if(self != nil)
    {
        [self setQueuePriority:NSOperationQueuePriorityLow];
        
        fileURL = [NSURL URLWithString:filePath];
        
        asset = [[AVURLAsset alloc] initWithURL:fileURL options:nil];
        if(asset == nil)
        {
            return NULL;
        }
        
        NSArray *tracks = [asset tracks];
        trackCount = [tracks count];
        if(trackCount < 1)
        {
            [asset release];
            
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
            free(audioData2);
            
            return NULL;
        }
        
        NSLog(@"NSOperation %@ : Init for %@", self, [fileURL absoluteString]);
    }
    
    return self;
}


- (void) dealloc
{
    NSLog(@"NSOperation %@ : Dealloc for %@", self, [fileURL absoluteString]);

    free(audioData1);
    free(audioData2);
    
    [asset release];
    
    [super dealloc];
}


- (void) main 
{	    
    NSLog(@"NSOperation %@", self);
    NSLog(@"Thread: %@", [NSThread currentThread]);
    NSLog(@"Loading file: %@", [fileURL absoluteString]);
            
    openFile = YES;
    fillAudioData1 = YES;
    
    waitForAction = [[NSCondition alloc] init];

    while(!self.isCancelled)
    {
        if(openFile)
        {
            NSLog(@"Open file %@", [fileURL absoluteString]);
            
            if([self openAudioFile:fileURL])
            {
                openFile = NO;
            }
            else
            {
                NSLog(@"Error opening file %@", [fileURL absoluteString]);
            }
        }

        if(fillAudioData1)
        {
            NSLog(@"Fill audioDataBuffer1");
            
            sizeAudioData1 = [self fillAudioBuffer:audioData1];
            if(sizeAudioData1 > 0)
            {
                fillAudioData1 = NO;
            }
            else
            {
                NSLog(@"Error filling audioDataBuffer1");
            }
        }
        else if(fillAudioData2)
        {
            NSLog(@"Fill audioDataBuffer2");

            sizeAudioData2 = [self fillAudioBuffer:audioData2];
            if(sizeAudioData2 > 0)
            {
                fillAudioData2 = NO;
            }
            else
            {
                NSLog(@"Error filling audioDataBuffer2");
            }
        }
        
        [waitForAction lock];
        [waitForAction wait];
        [waitForAction unlock];
    }
    
END:
    if(reader != nil)
    {
        [reader cancelReading];
        [reader release];
    }
    
    [waitForAction release];
    
    NSLog(@"NSOperation: %@ ends", self);
}


- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;
{
    if(currentAudioBuffer == 1)
    {
        fillAudioData1 = YES;

        currentAudioBuffer = 2;
        
        *packetsInBuffer = (sizeAudioData2 / sizeof(UInt32));
        
        [waitForAction lock];
        [waitForAction signal];
        [waitForAction unlock];
        
        return audioData2;
    }
    else
    {
        fillAudioData2 = YES;
        
        currentAudioBuffer = 1;
        
        *packetsInBuffer = (sizeAudioData1 / sizeof(UInt32));
        
        [waitForAction lock];
        [waitForAction signal];
        [waitForAction unlock];

        return audioData1;
    }
}


- (NSUInteger) fillAudioBuffer:(void*)audioBuffer
{
    NSUInteger dataIdx = 0;
    
    if(reader.status == AVAssetReaderStatusCompleted || reader.status == AVAssetReaderStatusCancelled)
    {
        NSLog(@"No audio data available");
        
        return 0;
    }
    
    while(reader.status == AVAssetReaderStatusReading)
    {
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
        if(sampleBuffer != NULL)
        {
            CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
            if(blockBuffer != NULL)
            {
                size_t dataLen = CMBlockBufferGetDataLength(blockBuffer);
                // NSLog(@"Read %lu bytes", dataLen);
                if(dataLen > 0)
                {
                    OSStatus err = CMBlockBufferCopyDataBytes(blockBuffer, 0, dataLen, (Byte*)audioBuffer + dataIdx);
      
                    CMSampleBufferInvalidate(sampleBuffer);
                    CFRelease(sampleBuffer);

                    if(err != kCMBlockBufferNoErr)
                    {
                        NSLog(@"CMBlockBufferCopyDataBytes returned %lu", err);
                        
                        return 0;
                    }
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
                NSLog(@"CMSampleBufferGetDataBuffer returned NULL");
                
                return 0;
            }
        }
        else
        {
            if(dataIdx == 0)
            {
                return 0;
            }
            
            NSLog(@"AudioBuffer %p filled with %d bytes", audioBuffer, dataIdx);
            
            break;
        }
    }
    
    if(reader.status == AVAssetReaderStatusCompleted)
    {
        [reader cancelReading];        
        [reader release];
        reader = nil;
         
        openFile = YES;
    }

    return dataIdx;
}


- (BOOL) openAudioFile:(NSURL*)fileUrl
{    
    reader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
    assert(reader != nil);
    output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:settings];
    assert(output != nil);
    [reader addOutput:output];
    
    return [reader startReading];
}

@end
