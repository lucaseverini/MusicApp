//
//  LoadAudioOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 15/2/2013.
//

#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

@class NSURL;
@class NSCondition;
@class AVURLAsset;
@class AVAssetReader;
@class AVAssetReaderTrackOutput;
@class AVAssetTrack;
@class DJMixer;

@interface LoadAudioOperation : NSOperation
{
	NSInteger readerStatus;
	UInt32 *audioData1;
	UInt32 *audioData2;
	BOOL noDataAvailable;
	NSUInteger startSamplePacket;
	NSUInteger currentSamplePacket;
	NSUInteger restartSamplePacket;
	BOOL active;
}

@property (nonatomic, retain) DJMixer *mixer;
@property (nonatomic, retain) NSCondition *waitForAction;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) AVURLAsset *asset;
@property (nonatomic, retain) NSDictionary *settings;
@property (nonatomic, retain) AVAssetTrack *track;
@property (nonatomic, assign) NSUInteger trackCount;
@property (nonatomic, retain) AVAssetReader *reader;
@property (nonatomic, retain) AVAssetReaderTrackOutput *output;
@property (nonatomic, assign) size_t audioBuffersSize;
@property (nonatomic, assign) NSUInteger sizeAudioData1;
@property (nonatomic, assign) NSUInteger sizeAudioData2;
@property (atomic, assign) BOOL fillAudioData1;
@property (atomic, assign) BOOL fillAudioData2;
@property (atomic, assign) BOOL endReading;
@property (atomic, assign) NSUInteger currentAudioBuffer;
@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) UInt32 packets;

- (id) initWithAudioFile:(NSString*)audioFileUrl;
- (BOOL) openAudioFile;
- (NSUInteger) fillAudioBuffer:(void*)audioBuffer;
- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;
- (void) reset;
- (void) setCurrentPlayPosition:(NSTimeInterval)time;
- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset;
- (void) activate;
- (void) deactivate;
- (void) remove;

@end
