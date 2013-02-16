//
//  LoadAudioOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 15/2/2013.
//

#import <UIKit/UIKit.h>

@class NSURL;
@class NSCondition;
@class AVURLAsset;
@class AVAssetReader;
@class AVAssetReaderTrackOutput;
@class AVAssetTrack;

@interface LoadAudioOperation : NSOperation

@property (nonatomic, retain) NSCondition *waitForAction;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) AVURLAsset *asset;
@property (nonatomic, retain) NSDictionary *settings;
@property (nonatomic, retain) AVAssetTrack *track;
@property (nonatomic, assign) NSUInteger trackCount;
@property (nonatomic, retain) AVAssetReader *reader;
@property (nonatomic, retain) AVAssetReaderTrackOutput *output;
@property (nonatomic, assign) UInt32 *audioData1;
@property (nonatomic, assign) UInt32 *audioData2;
@property (nonatomic, assign) size_t audioBuffersSize;
@property (nonatomic, assign) NSUInteger sizeAudioData1;
@property (nonatomic, assign) NSUInteger sizeAudioData2;
@property (atomic, assign) BOOL fillAudioData1;
@property (atomic, assign) BOOL fillAudioData2;
@property (nonatomic, assign) BOOL openFile;
@property (atomic, assign) BOOL endReading;
@property (atomic, assign) BOOL noDataAvailable;
@property (atomic, assign) NSUInteger currentAudioBuffer;

- (id) initWithAudioFile:(NSString*)filePath;
- (BOOL) openAudioFile:(NSURL*)fileUrl;
- (NSUInteger) fillAudioBuffer:(void*)audioBuffer;
- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;

@end
