//
//  SequencerOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 21/4/2013.
//


typedef struct audioBuffer
{
	UInt32		*data;
	NSUInteger	size;
	NSInteger	status;		// 0->Empty or finished to read, 1->Filling, 2->Filled/Ready to be read, 3->Reading
}
audioBuffer, *audioBufferPtr;

typedef struct recording
{
	ExtAudioFileRef fileRef;
	NSURL			*file;
	NSString		*name;
	CMTime			duration;
	SInt64			packets;
	NSUInteger		startPacket;
	NSUInteger		endPacket;
	
	audioBuffer		buffer1;
	audioBuffer		buffer2;
	audioBuffer		buffer3;
	
	NSUInteger		fillBuffer;
	NSUInteger		readBuffer;
	NSUInteger		readPackets;
	NSUInteger		totReadPackets;
	NSUInteger		totBufferPackets;
	
	BOOL			loaded;
	BOOL			played;
	BOOL			noDataAvailable;
	NSInteger		readerStatus;
}
recording, *recordingPtr;

@class NSURL;
@class NSCondition;
@class DJMixer;

@interface SequencerOperation : NSOperation
{
	NSUInteger		startPacket;
	BOOL			active;
	BOOL			working;
	NSUInteger		totRecordings;
	recordingPtr	recordings;
	recordingPtr	curPlaying;
	NSUInteger		readingBuffer;
	NSUInteger		fillingBuffer;

	int numChannels;
	AudioStreamBasicDescription outputFormat;
}

@property (nonatomic, retain) DJMixer *mixer;
@property (nonatomic, retain) NSCondition *waitForAction;
@property (atomic, assign) BOOL noDataAvailable;

- (id) initWithRecords:(NSString*)recordsFile;
- (void) setRecords:(NSString*)recordsFile;
- (BOOL) openAudioFile:(recordingPtr)recording;
- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;
- (void) reset:(NSUInteger)packetPosition;
- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset;
- (void) activate;
- (void) deactivate;
- (void) remove;
- (BOOL) sequencerActive;
- (BOOL) isActive;
- (BOOL) hasData;

@end



