//
//  InMemoryAudioFile.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "InMemoryAudioFile.h"
#import "LoadAudioOperation.h"

#define STAY_SYNCHRONIZED // If defined a paused channel maintains synchronization with other channels

@implementation InMemoryAudioFile

@synthesize fileName;
@synthesize url;
@synthesize channel;
@synthesize trackCount;
@synthesize playing;
@synthesize paused;
@synthesize loaded;

// Override init method
- (id) initForChannel:(NSInteger)numChannel
{ 
    [super init];
    if(self != nil)
    {
        channel = numChannel;
        leftPacketIndex = 0;
        rightPacketIndex = 0;
        playing = NO;
        paused = NO;
        audioData = NULL;
        leftAudioData = NULL;
        rightAudioData = NULL;	
        monoFloatDataLeft = NULL;
        monoFloatDataRight = NULL;
        mPacketDescs = NULL;
        playFromAudioInput = NO;
        inputAudioData = NULL;
        lastInputAudioValue = 0;
        trackCount = 0;
        packetCount = 0;
        packetIndex = 0;
        lostPackets = 0;
    }
    
	return self;
}


- (void) freeStuff
{
    if(operation != nil)
    {
        [self removeLoadOperation];
		
		audioData = NULL;	// Nullify the pointer to avoid the memore to be freed here (it was allocated in LoadAudioOperation) 
	}
    
	if(audioData != NULL)	 // Free the memory if allocated here
    {
        free(audioData); 
        audioData = NULL;
    }
     
    if(monoFloatDataLeft != NULL)
    {
        free(monoFloatDataLeft);
        monoFloatDataLeft = NULL;
    }
    
    if(monoFloatDataRight != NULL)
    {
        free(monoFloatDataRight);   
        monoFloatDataRight = NULL;
    }
    
    if(leftAudioData != NULL)
    {
        free(leftAudioData);
        leftAudioData = NULL;
    }
    
    if(rightAudioData != NULL)
    {
        free(rightAudioData);
        rightAudioData = NULL;
    }
    
    trackCount = 0;
    
    packetCount = 0;
    packetIndex = 0;
    lostPackets = 0;
    
    fileName = @"";
    url = @"";

    loaded = NO;
    playFromAudioInput = NO;
    
    if(recorder != NULL)
    {
        // delete recorder;
        
        [recorder release];
    }
}


- (void) dealloc 
{
    [self freeStuff];
     
    [super dealloc];
}


- (void) start
{    
	if(!playing)
	{
        if(playFromAudioInput)
        {
            //recorder->StartRecord();
            //packetsInBuffer = recorder->PacketsInBuffer();
            
            [recorder startRecord];
            packetsInBuffer = recorder.packetsInBuffer;
        }
        
		playing = YES;
		paused = NO;
	}
}


- (void) stop
{
    if(playFromAudioInput)
    {
        [recorder stopRecord];
    }
	
	// [operation cancel];

	if(playing || paused)
	{
		playing = NO;
		paused = NO;
    }
    
    [self reset];
    
	if(lostPackets > 0)
	{
		NSLog(@"LostPackets: %llu\n", lostPackets);
	}
}


- (void) pause:(BOOL)flag
{
    if(flag)
    {
        paused = YES;
        playing = NO;
    }
    else
    {
        paused = NO;
        playing = YES;
    }
}


// Open and read a wav file
- (OSStatus) file:(NSString*)filePath
{	
    [self freeStuff];

	NSLog(@"File: %@", [filePath lastPathComponent]);
	
	// get a ref to the audio file, need one to open it
	CFURLRef audioFileURL = CFURLCreateFromFileSystemRepresentation(NULL, (const UInt8 *)[filePath cStringUsingEncoding:[NSString defaultCStringEncoding]] , strlen([filePath cStringUsingEncoding:[NSString defaultCStringEncoding]]), false);
	assert(audioFileURL != NULL);
    
	// Open the audio file
	OSStatus result = AudioFileOpenURL(audioFileURL, 0x01, 0, &mAudioFile);
	// Were there any errors reading? if so deal with them first
	if(result != noErr) 
	{
		NSLog(@"Could not open file: %@", [filePath lastPathComponent]);
		packetCount = -1;
	}
	else
	{       
        fileName = [[filePath lastPathComponent] stringByDeletingPathExtension];

		// Get the file info
		[self getFileInfo];
		// How many packets read? (packets are the number of stereo samples in this case)
		// NSLog([NSString stringWithFormat:@"File Opened, packet Count: %d", packetCount]);
		
		UInt32 packetsRead = packetCount;		        
		UInt32 numBytesRead = -1;
		OSStatus result = -1;
        
		if(packetCount > 0)     // Fill our in memory audio buffer with the whole file (I wouldnt use this with very large files btw)
		{
			// Allocate the buffer
			audioData = (UInt32 *)malloc(sizeof(UInt32) * packetCount);
			// Read the packets
			result = AudioFileReadPackets(mAudioFile, false, &numBytesRead, NULL, 0, &packetsRead,  audioData); 
            
            loaded = YES;
		}
/*		
        // The 32-bit read data mixed data (high 16 bit for left, lower 16 bit for right)
        // No separate left stereo data from right stereo data
		if(result == noErr)
		{
			monoFloatDataLeft = (float*)malloc(sizeof(float) * packetCount);
			monoFloatDataRight = (float*)malloc(sizeof(float) * packetCount);
			
			leftAudioData = (SInt16 *)malloc(sizeof(SInt16) * packetCount);			
			rightAudioData = (SInt16 *)malloc(sizeof(SInt16) * packetCount);
			
			// Now we need to copy the sample data
			UInt32 sample;
			SInt16 left;
			SInt16 right;
			
			for(UInt32 i = 0; i < packetCount; i++)
			{ 				
				sample = *(audioData + i);
				left = sample >> 16;
				right = sample;
				
				leftAudioData[i] = left;
				rightAudioData[i] = right;
				
				// Turn it into the range -1.0 - 1.0
				monoFloatDataLeft[i] = (float)left / 32768.0;       
				monoFloatDataRight[i] = (float)right / 32768.0;
			}
		
			// Print out general info about  the file
			NSLog([NSString stringWithFormat:@"Packets read from file: %d\n", packetsRead]);
			NSLog([NSString stringWithFormat:@"Bytes read from file: %d\n", numBytesRead]);
			// For a stereo 32 bit per sample file this is ok
			NSLog([NSString stringWithFormat:@"Sample count: %d\n", numBytesRead / 2]);
			// For a 32bit per stereo sample at 44100khz this is correct
			NSLog([NSString stringWithFormat:@"Time in Seconds: %f.4\n", ((float)numBytesRead / 4.0) / 44100.0]);
 		}
*/        
        result = AudioFileClose(mAudioFile);
	}

	CFRelease(audioFileURL);     

	return result;
}


- (OSStatus) getFileInfo 
{	
	OSStatus result = -1;
	double duration;
	
	if(mAudioFile != nil)
	{
		UInt32 dataSize = sizeof packetCount;
		result = AudioFileGetProperty(mAudioFile, kAudioFilePropertyAudioDataPacketCount, &dataSize, &packetCount);
		if(result == noErr) 
		{
			duration = ((double)packetCount * 2) / 44100.0;
		}
		else
		{
			packetCount = -1;
		}
	}
	
	return result;
}


// Gets the next packet from the buffer, if we have reached the end of the buffer return 0
- (UInt32) getNextPacket
{
    if(playFromAudioInput)
    {
        if(inputAudioData == NULL || packetIndex == packetsInBuffer)
        {
            // inputAudioData = recorder->NextBufferAudioData();
            
            inputAudioData = [recorder nextBufferAudioData];
             
            packetIndex = 0;
        }
        if(inputAudioData != NULL)
        {
            if(lostPackets != 0)
            {
                NSLog(@"lostPackets: %llu\n", lostPackets);
                
                lostPackets = 0;
            }
            
            packetIndex++;
            
            UInt16 value = inputAudioData[packetIndex];

            lastInputAudioValue = value + (value << 16);

            inputAudioData[packetIndex] = 0;

            return lastInputAudioValue;
        }
        else
        {
            lostPackets++;
            
            return lastInputAudioValue;
        }
    }
    else
    {
        if(operation != nil)
        {
            if(operation.noDataAvailable)
            {
                return 0;
            }
            
            if(packetIndex >= packetCount)
            {
                packetIndex = 0;
                
                NSUInteger numOfPackets;
                audioData = [operation getNextAudioBuffer:&numOfPackets];
                packetCount = (SInt64)numOfPackets;
            }

            return audioData[packetIndex++];
        }
        else
        {
            if(audioData == NULL)
            {
                return 0;
            }
                
            if(packetIndex >= packetCount)
            {
                packetIndex = 0;
            }
            
            return audioData[packetIndex++];
        }
    }
}


// Gets the current index (where we are up to in the buffer)
- (SInt64) getIndex
{
	return packetIndex;
}


- (void) reset
{
	packetIndex = 0;
    packetCount = 0;
    lostPackets = 0;
    
    [operation reset];
}


- (OSStatus) mediaItem:(MPMediaItem*)mediaItem
{
    [self freeStuff];
    
    fileName = @"";
    
    if(mediaItem == nil)
        return noErr;
 
    NSURL *audioFileURL = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    assert(audioFileURL != nil);
    NSLog(@"URL: %@", audioFileURL);
 
    NSMutableData *data = [self ReadAudioData:audioFileURL];
    assert(data != nil);
     
    NSUInteger dataLen = [data length];
    audioData = (UInt32*)malloc(dataLen);
    assert(audioData != nil);
    if(audioData == NULL)
    {
        packetCount = -1;
        return ENOMEM;
    }
    
    memcpy(audioData, [data mutableBytes], dataLen);
    
    packetCount = dataLen / sizeof(UInt32);
 
    // float duration = [[mediaItem valueForProperty:MPMediaItemPropertyPlaybackDuration] floatValue];
    fileName = [[NSString alloc] initWithString:[mediaItem valueForProperty:MPMediaItemPropertyTitle]];
    
    [data release];
    
    loaded = YES;
   
    return noErr;
}


- (OSStatus) mediaItemUrl:(NSString*)fileUrl;
{
    if(fileUrl == nil || (url != nil && [url compare:fileUrl] == 0))
        return noErr;

    [self freeStuff];
            
    url = fileUrl;
    packetCount = -1;
   
    NSMutableData *data = [self ReadAudioData:[NSURL URLWithString:fileUrl]];
    if(data == nil)
    {
        return EINVAL;
    }
    
    NSUInteger dataLen = [data length];
    audioData = (UInt32*)malloc(dataLen);
    assert(audioData != nil);
    if(audioData == NULL)
    {
        return ENOMEM;
    }
    
    memcpy(audioData, [data mutableBytes], dataLen);
    
    packetCount = dataLen / sizeof(UInt32);
    
    [data release];
    
    loaded = YES;
  
    return noErr;
}


- (void) removeLoadOperation
{	
    if(operation != nil)
    {
		// NSLog(@"RemoveLoadOperation for file %@ ++", self.url);

        if(!operation.isFinished)
        {
            [operation waitUntilFinished];
        }
        
        if(!operation.isCancelled)
        {
            [operation cancel];
		}
			
		[operation release];
        operation = nil;
        
        trackCount = 0;
        
        packetCount = 0;
        packetIndex = 0;
        lostPackets = 0;
        
        loaded = NO;

		// NSLog(@"RemoveLoadOperation for file %@ --", self.url);
	}
}


- (void) setLoadOperation:(LoadAudioOperation*)loadOperation
{
    operation = loadOperation;
	
    trackCount = loadOperation.trackCount;
	url = [loadOperation.fileURL absoluteString];
    
    packetCount = 0;
    packetIndex = 0;
    lostPackets = 0;
    
    loaded = YES;
}


- (NSMutableData*) ReadAudioData:(NSURL*)audioFileURL
{
    NSMutableData *data = nil;
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:audioFileURL options:nil];
    assert(asset != nil);
    
    NSArray *tracks = [asset tracks];
    trackCount = [tracks count];

    AVAssetTrack *track = [tracks objectAtIndex:0];
    assert(track != nil);
    
    NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                              // [NSNumber numberWithInt:44100.0], AVSampleRateKey,            // Not supported
                              // [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,           // Not Supported
                              [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
                              [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                              nil];
    
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
    assert(reader != nil);
    AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:settings];
    assert(output != nil);
    [reader addOutput:output];
    
    BOOL ready = [reader startReading];
    if(ready)
    {
        data = [[NSMutableData alloc] init];
        
        while(reader.status == AVAssetReaderStatusReading)
        {
            CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
            if(sampleBuffer != NULL)
            {
                CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
                if(blockBuffer != NULL)
                {
                    size_t length = CMBlockBufferGetDataLength(blockBuffer);
                    NSMutableData *bufferData = [[NSMutableData alloc] initWithLength:length];
                    CMBlockBufferCopyDataBytes(blockBuffer, 0, length, bufferData.mutableBytes);
                    
                    [data appendData:bufferData];
                    
                    CMSampleBufferInvalidate(sampleBuffer);
                    CFRelease(sampleBuffer);
                    
                    [bufferData release];
                }
                else
                {
                    [reader cancelReading];
                    [data release];
                    data = nil;
                }
            }
        }
        
        if(data != nil)
        {
            NSLog(@"Audio Data from track 1: %u bytes", [data length]);
        }
        else
        {
            NSLog(@"Error reading Audio Data");
        }
    }
    
    [reader release];
    
    [asset release];
    
    return data;
}


- (OSStatus) audioInput
{
    if(recorder != nil)
    {
        // delete recorder;
        
        [recorder release];
        recorder = nil;
    }

    recorder = [[AURecorder alloc] init];
    
	[recorder setUpData]; // allocate buffers and concat
    
	// Initialise the audio player
	OSStatus status = [recorder setUpAudioDevice];
	if(status != noErr)
    {
		NSLog(@"Problem with recorder setup!");
        return status;
    }

    playFromAudioInput = YES;
    loaded = YES;

    return status;
}

@end
