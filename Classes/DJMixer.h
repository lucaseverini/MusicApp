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

@interface DJMixer : NSObject 
{
	AudioStreamBasicDescription audioFormat;

	// the graph of audio connections
	AUGraph graph;
    
    BOOL paused;
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

- (void) initAudio;
- (void) changeCrossFaderAmount:(float)volume forChannel:(NSInteger)channel;
- (void) play;
- (void) stop;
- (void) pause:(BOOL)pause;
- (BOOL) isPaused;
- (BOOL) isPlaying;
- (void) pause:(BOOL)flag forChannel:(NSInteger)channel;
- (void) setUpData;
- (void) freeData;

@end
