//
//  InMemoryAudioFile.h
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioFile.h>
#import "AQRecorder.h"
#import "AURecorder.h"
#import <sys/time.h>

@class MPMediaItem;
@class LoadAudioOperation;

@interface InMemoryAudioFile : NSObject 
{
	AudioStreamBasicDescription		mDataFormat;                    
    AudioFileID						mAudioFile;                     
    UInt32							bufferByteSize;                 
    SInt64							mCurrentPacket;                 
    UInt32							mNumPacketsToRead;              
    AudioStreamPacketDescription	*mPacketDescs;                  
	SInt64							packetCount;
	UInt32							*audioData;
	SInt64							packetIndex;
	SInt64							leftPacketIndex;
	SInt64							rightPacketIndex;
	
	SInt16							*leftAudioData;
	SInt16							*rightAudioData;
	
	float							*monoFloatDataLeft;
	float							*monoFloatDataRight;
    
    BOOL                            playFromAudioInput;
    //AQRecorder                    *recorder;
	UInt16							*inputAudioData;
    UInt32                          lastInputAudioValue;
    SInt64                          packetsInBuffer;
    SInt64                          jumpedpackets;
	UInt64							totalPacketIndex;
    UInt64                          lostPackets;
}

@property (nonatomic, retain) NSString *fileName;
@property (nonatomic, retain) NSString *url;
@property (nonatomic, assign) NSInteger channel;
@property (nonatomic, assign) NSInteger trackCount;
@property (atomic, assign) BOOL playing;
@property (atomic, assign) BOOL paused;
@property (atomic, assign) BOOL loaded;
@property (nonatomic, assign) BOOL noData;
@property (nonatomic, assign) AURecorder *recorder;
@property (nonatomic, assign) LoadAudioOperation *operation;

- (id) initForChannel:(NSInteger)numChannel;

// Opens and read data from an audio file
- (OSStatus) file:(NSString*)filePath;
// Opens and read data from a mediaItem url
- (OSStatus) mediaItemUrl:(NSString*)fileUrl;
// Read data from a mediaItem
- (OSStatus) mediaItem:(MPMediaItem*)mediaItem;
// Read data from a audio Input
- (OSStatus) audioInput;

// Read data from a NSOperation
- (void) setLoadOperation:(LoadAudioOperation*)loadOperation;
- (void) removeLoadOperation;

// Gets the info about a wav file
- (OSStatus) getFileInfo;

// Gets the next packet from the buffer, returns -1 if we have reached the end of the buffer
- (UInt32) getNextPacket;
// Gets the current index (where we are up to in the buffer)
- (SInt64) getIndex;

//reset the index to the start of the file
- (void) reset;

- (void) start;
- (void) stop;

- (void) pause:(BOOL)flag;

- (void) freeStuff;     // Free the buffers just in case they contain some data

- (NSMutableData*) ReadAudioData:(NSURL*)audioFileURL;

@end


