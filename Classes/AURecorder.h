//
//  AURecorder.h
//
//  Created by Luca Severini on 30/9/2012.
//

#import <Foundation/Foundation.h>

@interface AURecorder : NSObject
{
@public
	int audioproblems;
    BOOL startedCallback;
}

@property (nonatomic, assign) BOOL startedCallback;
@property (nonatomic, assign) SInt32 packetsInBuffer;

// Set up audio buffers, YourSynth object
- (void) setUpData;
- (void) freeData;

- (OSStatus) startRecord;
- (OSStatus) stopRecord;

- (void) closeDownAudioDevice;
- (OSStatus) setUpAudioDevice;

- (UInt16*) nextBufferAudioData;

@end
