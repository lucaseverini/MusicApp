//
//  DJMixer.h
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import "AudioToolbox/AudioToolbox.h"
#import "InMemoryAudioFile.h"

#define kNumChannels 9

@class DJMixer;

extern DJMixer* _this;

@interface DJMixer : NSObject 
{
	AudioStreamBasicDescription audioFormat;

	// The graph of audio connections
	AUGraph graph;
	
	@public
	UInt32 packetsInBuffer;		// Used for live playback channel-8
	UInt32 packetIndex;			// Used for live playback channel-8	
	UInt32 durationPacketsIndex;

	// Properties declared also here are visible in gdb as instance variables
	@private
	double duration;
	double playPosition;
	UInt32 durationPackets;
}

@property (nonatomic) AudioUnit crossFaderMixer;
@property (nonatomic) AudioUnit masterFaderMixer;
@property (nonatomic) AudioUnit output;
@property (nonatomic, assign) BOOL missingAudioInput;
@property (nonatomic) AudioBufferList *bufferList;
@property (nonatomic, assign) InMemoryAudioFile **channels;
@property (nonatomic, assign) UInt16 *inputAudioData;
@property (nonatomic, assign) BOOL recordingStarted;
@property (nonatomic, retain) NSOperationQueue *loadAudioQueue;
@property (atomic, assign) BOOL paused;
@property (atomic, assign) ExtAudioFileRef recordingFile;
@property (atomic, assign) BOOL fileRecording;
@property (atomic, assign) BOOL isStopping;
@property (atomic, assign) double duration;
@property (atomic, assign) double playPosition;
@property (atomic, assign) UInt32 durationPackets;

- (void) initAudio;
- (void) changeCrossFaderAmount:(double)volume forChannel:(NSInteger)channel;
- (void) startPlay;
- (void) stopPlay;
- (void) pause:(BOOL)pause;
- (BOOL) isPlaying;
- (BOOL) hasData;
- (void) pause:(BOOL)flag forChannel:(NSInteger)channel;
- (void) setUpData;
- (void) freeData;
- (UInt32) getTotalPackets;
- (void) setStartPosition:(NSTimeInterval)time;
- (void) setCurrentPlayPosition:(NSTimeInterval)time;

@end
