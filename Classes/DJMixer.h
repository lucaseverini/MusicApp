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

#define kNumChannels 8 // 8 output channels

@interface DJMixer : NSObject 
{
	AudioStreamBasicDescription audioFormat;

	// The graph of audio connections
	AUGraph graph;
	
	@public
	UInt32 packetsInBuffer;		// Used for live playback channel
	UInt32 packetIndex;			// Used for live playback channel	
	UInt32 durationPacketsIndex;
	UInt32 totFrameNum;

	// Properties declared also here are visible in gdb as instance variables
	@private
	double duration;
	double playPosition;
	UInt32 durationPackets;
	BOOL savingFile;
	ExtAudioFileRef savingFileRef;
	NSURL *savingFileUrl;
	SInt32 savingFileStartPacket;
	UInt32 savingFilePackets;
}

@property (nonatomic) AudioUnit crossFaderMixer;
@property (nonatomic) AudioUnit masterFaderMixer;
@property (nonatomic) AudioUnit output;
@property (nonatomic, assign) BOOL missingAudioInput;
@property (nonatomic) AudioBufferList *bufferList;
@property (nonatomic, assign) InMemoryAudioFile **channels;
@property (nonatomic, assign) InMemoryAudioFile *playback;
@property (nonatomic, assign) InMemoryAudioFile *sequencer;
@property (nonatomic, assign) UInt16 *inputAudioData;
@property (nonatomic, assign) BOOL recordingStarted;
@property (nonatomic, assign) BOOL loop;
@property (nonatomic, retain) NSOperationQueue *loadAudioQueue;
@property (atomic, assign) BOOL paused;
@property (atomic, assign) BOOL isStopping;
@property (atomic, assign) double duration;
@property (atomic, assign) double playPosition;
@property (atomic, assign) UInt32 durationPackets;

@property (atomic, assign) BOOL savingFile;
@property (atomic, assign) ExtAudioFileRef savingFileRef;
@property (atomic, retain) NSURL *savingFileUrl;
@property (atomic, assign) SInt32 savingFileStartPacket;
@property (atomic, assign) UInt32 savingFilePackets;

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
- (void) setStartPosition:(NSTimeInterval)time reset:(BOOL)reset;
- (void) setCurrentPlayPosition:(NSTimeInterval)time;

@end
