//
//  SequencerOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 21/4/2013.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>


typedef struct audioBuffer
{
	UInt32		*data;
	NSUInteger	size;
	NSInteger	status;		// 0 -> Empty or finished to read, 1 -> Filling, 2 -> Filled/Ready to be read, 3 -> Reading
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
	
	audioBuffer		buffers[4];
	NSUInteger		fillingBufferIdx;
	NSUInteger		readingBufferIdx;

	BOOL			firstBufferLoaded;
	NSUInteger		firstPackets;
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
	NSUInteger startSamplePacket;
	BOOL active;
	BOOL working;
	NSUInteger totRecordings;
	recordingPtr recordings;
	recordingPtr curPlaying;
	recordingPtr curReading;

	int numChannels;
	AudioStreamBasicDescription outputFormat;
}

@property (nonatomic, retain) DJMixer *mixer;
@property (nonatomic, retain) NSCondition *waitForAction;
@property (atomic, assign) BOOL noDataAvailable;

- (id) initWithRecords:(NSString*)recordsFile;
- (BOOL) openAudioFile:(recordingPtr)recording;
- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;
- (void) reset;
- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset;
- (void) activate;
- (void) deactivate;
- (void) remove;
- (BOOL) sequencerActive;
- (BOOL) isActive;
- (BOOL) hasData;
- (NSInteger) getRecordings:(recordingPtr*)theRecordings;
- (void) setRecords:(NSString*)recordsFile;
- (void) loadFirstBuffer:(recordingPtr)recording;

@end



