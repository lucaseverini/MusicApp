//
//  LoadAudioOperation.mm
//  MusicApp
//
//  Created by Luca Severini on 15/2/2013.
//


@class NSURL;
@class NSCondition;
@class DJMixer;

@interface LoadAudioOperation : NSOperation
{
	NSInteger readerStatus;
	UInt32 *audioData1;
	UInt32 *audioData2;
	BOOL noDataAvailable;
	BOOL active;	

	ExtAudioFileRef fileRef;
	NSInteger numChannels;
	AudioStreamBasicDescription outputFormat;
}

@property (nonatomic, retain) DJMixer *mixer;
@property (nonatomic, retain) NSCondition *waitForAction;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, assign) SInt64 packets;
@property (nonatomic, assign) NSUInteger sizeAudioData1;
@property (nonatomic, assign) NSUInteger sizeAudioData2;
@property (atomic, assign) BOOL fillAudioData1;
@property (atomic, assign) BOOL fillAudioData2;
@property (atomic, assign) NSUInteger currentAudioBuffer;
@property (nonatomic, assign) CMTime duration;

- (id) initWithAudioFile:(NSString*)audioFileUrl;
- (BOOL) openAudioFile;
- (NSUInteger) fillAudioBuffer:(void*)audioBuffer;
- (UInt32*) getNextAudioBuffer:(NSUInteger*)packetsInBuffer;
- (void) reset;
- (void) setStartPlayPosition:(NSTimeInterval)time reset:(BOOL)reset;
- (void) activate;
- (void) deactivate;
- (void) remove;

@end
