//
//  SequencerOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 21/4/2013.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>


typedef struct recording
{
	NSString		*name;
	AVURLAsset		*asset;
	AVAssetTrack	*track;
	CMTime			duration;
	NSUInteger		packets;
	NSUInteger		startPacket;
	NSUInteger		endPacket;
	NSUInteger		sizeAudioData1;
	NSUInteger		sizeAudioData2;
	UInt32			*audioData1;
	UInt32			*audioData2;
	BOOL			fillAudioData1;
	BOOL			fillAudioData2;
	NSUInteger		currentAudioBuffer;
	BOOL			loaded;
	BOOL			played;
	BOOL			noDataAvailable;
	NSInteger		readerStatus;
}
recording, *recordingPtr;

@class NSURL;
@class NSCondition;
@class AVURLAsset;
@class AVAssetReader;
@class AVAssetReaderTrackOutput;
@class AVAssetTrack;
@class DJMixer;

@interface SequencerOperation : NSOperation
{
	// NSInteger readerStatus;
	// NSUInteger sizeAudioData1;
	// NSUInteger sizeAudioData2;
	// UInt32 *audioData1;
	// UInt32 *audioData2;
	NSUInteger startSamplePacket;
	NSUInteger currentSamplePacket;
	NSUInteger restartSamplePacket;
	BOOL active;
	BOOL working;
	NSUInteger totRecordings;
	recordingPtr recordings;
	recordingPtr curPlaying;
	recordingPtr curReading;
	NSUInteger playingIdx;
	NSUInteger readingIdx;
}

@property (nonatomic, retain) DJMixer *mixer;
@property (nonatomic, retain) NSCondition *waitForAction;
//@property (nonatomic, retain) NSURL *fileURL;
//@property (nonatomic, retain) AVURLAsset *asset;
@property (nonatomic, retain) NSDictionary *settings;
//@property (nonatomic, retain) AVAssetTrack *track;
//@property (nonatomic, assign) NSUInteger trackCount;
@property (nonatomic, retain) AVAssetReader *reader;
@property (nonatomic, retain) AVAssetReaderTrackOutput *output;
@property (nonatomic, assign) size_t audioBuffersSize;
@property (atomic, assign) BOOL fillAudioData1;
@property (atomic, assign) BOOL fillAudioData2;
@property (atomic, assign) BOOL endReading;
@property (atomic, assign) BOOL noDataAvailable;
@property (atomic, assign) NSUInteger currentAudioBuffer;
//@property (nonatomic, assign) CMTime duration;
//@property (nonatomic, assign) NSUInteger packets;

//@property (nonatomic, assign) NSUInteger startPacket;		// Sequencer
//@property (nonatomic, assign) NSUInteger endPacket;			// Sequencer
@property (nonatomic, assign) NSUInteger curStartPacket;	// Sequencer
@property (nonatomic, assign) NSUInteger curEndPacket;		// Sequencer

- (id) initWithRecordsFile:(NSString*)recordsFile;
- (BOOL) openAudioFile;
- (NSUInteger) fillAudioBuffer:(void*)audioBuffer;
- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;
- (void) reset;
- (void) setCurrentPlayPosition:(NSTimeInterval)time;
- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset;
- (void) activate;
- (void) deactivate;
- (void) remove;
- (BOOL) sequencerActive;
- (NSInteger) getRecordings:(recordingPtr*)theRecordings;

@end



