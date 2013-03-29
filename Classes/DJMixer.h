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
}

@property (nonatomic) AudioUnit crossFaderMixer;
@property (nonatomic) AudioUnit masterFaderMixer;
@property (nonatomic) AudioUnit output;
@property (nonatomic) AudioBufferList *bufferList;
@property (nonatomic, assign) InMemoryAudioFile **loop;
@property (nonatomic, assign) SInt32 packetsInBuffer;
@property (nonatomic, assign) SInt32 packetIndex;
@property (nonatomic, assign) UInt16 *inputAudioData;
@property (nonatomic, assign) BOOL recordingStarted;
@property (nonatomic, retain) NSOperationQueue *loadAudioQueue;
@property (atomic, assign) BOOL paused;
@property (atomic, assign) ExtAudioFileRef recordingFile;
@property (atomic, assign) BOOL fileRecording;
@property (atomic, assign) BOOL isStopping;

- (void) initAudio;
- (void) changeCrossFaderAmount:(float)volume forChannel:(NSInteger)channel;
- (void) startPlay;
- (void) stopPlay;
- (void) pause:(BOOL)pause;
- (BOOL) isPlaying;
- (void) pause:(BOOL)flag forChannel:(NSInteger)channel;
- (void) setUpData;
- (void) freeData;

@end
