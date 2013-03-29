//
//  AURecorder.mm
//
//  Created by Luca Severini on 30/9/2012.
//

// This code owes tribute to various folk who have worked out how to use RemoteIO:
// in particular, see
//  http://michael.tyson.id.au/2008/11/04/using-remoteio-audio-unit/ 
//	http://www.iwillapps.com/wordpress/?p=196
// I use similar code in my music iPhone apps like Concat and iGendyn

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioServices.h>
#import "AURecorder.h"

@implementation AURecorder

@synthesize startedCallback;
@synthesize packetsInBuffer;

AudioComponentInstance audioUnit;
AudioStreamBasicDescription audioFormat;
AudioBufferList* bufferList;

// Called when there is a new buffer of input samples available
static OSStatus recordingCallback (void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData)
{
	NSLog(@"recordingCallback...");
	
    AURecorder *recorder = (AURecorder*)inRefCon;
    
	if(recorder->startedCallback)
    {
        // Fills bufferList->mBuffers[0].mData with audio data from microphone               
		OSStatus result = AudioUnitRender(audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, bufferList);
		switch(result)
		{
			case noErr:
				// doSomethingWithAudioBuffer((SInt16*)audioRIO.bufferList->mBuffers[0].mData,inNumberFrames);
				
				// Stay absolutely locked, outputcallback comes after inputcallback I think in AUGraph
				// NSLog(@"numFrames %d input count %d output count %d \n", inNumberFrames, inputcallbacktest, outputcallbacktest); 
				// inputcallbacktest += inNumberFrames; 				
				break;
                
			case kAudioUnitErr_InvalidProperty:
                NSLog(@"AudioUnitRender Failed: Invalid Property");
                break;
                
			case -50:
                NSLog(@"AudioUnitRender Failed: Invalid Parameter(s)");
                break;
                
			default:
                NSLog(@"AudioUnitRender Failed: Unknown (%ld)", result);
                break;
		}		
	}
	
	return noErr;
}


- (void) setUpData
{	    
    packetsInBuffer = 1024;
	
	bufferList = (AudioBufferList*) malloc(sizeof(AudioBufferList));
	bufferList->mNumberBuffers = 1;
	for(UInt32 i = 0; i < bufferList->mNumberBuffers; i++)
	{
		bufferList->mBuffers[i].mNumberChannels = 1;
		bufferList->mBuffers[i].mDataByteSize = ((packetsInBuffer * 2) * 2);
        
        int buffSize = bufferList->mBuffers[i].mDataByteSize;
		bufferList->mBuffers[i].mData = malloc(buffSize);
	}
}


- (void) freeData
{	
	for(UInt32 i = 0; i < bufferList->mNumberBuffers; i++)
    {
		free(bufferList->mBuffers[i].mData);
	}
	
	free(bufferList);
}


// Lots of setup required
- (OSStatus) setUpAudioDevice
{
	OSStatus status;
	
	startedCallback = NO;
		
	// AudioSessionGetProperty(AudioSessionPropertyID inID, UInt32 *ioDataSize, void *outData);
	UInt32 sizeofdata;

	NSLog(@"Audio session details");
	
	UInt32 audioavailableflag; 
	
	// Can check whether input plugged in
	sizeofdata = sizeof(audioavailableflag); 
	status = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &sizeofdata, &audioavailableflag);
	NSLog(@"Audio Input Available? %s", audioavailableflag != 0 ? "yes" : "no");
	if(audioavailableflag == 0)
    {
        // No input capability
		return 1; 
	}
			
	Float64 samplerate; 
	samplerate = 44100.0; // Supports and changes to 22050.0 or 48000.0 too!
	status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, sizeof(samplerate), &samplerate);
	
	sizeofdata = sizeof(samplerate); 
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &sizeofdata, &samplerate);		
	NSLog(@"Device sample rate %f", samplerate);
	
	// Set preferred hardward buffer size of 1024; part of assumptions in callbacks
	Float32 iobuffersize = 1024.0 / 44100.0;
	status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(iobuffersize), &iobuffersize);
	
	sizeofdata = sizeof(iobuffersize);
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &sizeofdata, &iobuffersize);	
	NSLog(@"Hardware buffer size %f",iobuffersize);
	
	// There are other possibilities
	UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord; // Both input and output
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
	
	// Describe audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output;
	desc.componentSubType = kAudioUnitSubType_RemoteIO;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple;
	// Get component
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// Get audio units
	status = AudioComponentInstanceNew(inputComponent, &audioUnit);	
	if(status!= noErr)
    {		
		NSLog(@"Failure at AudioComponentInstanceNew: %ld", status);		
		return status; 		
	}
	
	UInt32 kOutputBus = 0;
	UInt32 kInputBus = 1;
	
	// Enable IO for recording
	UInt32 flag = 1;
	status = AudioUnitSetProperty(audioUnit,
								  kAudioOutputUnitProperty_EnableIO, 
								  kAudioUnitScope_Input, 
								  kInputBus,
								  &flag, 
								  sizeof(flag));
	if(status!= noErr)
    {		
		NSLog(@"Failure at AudioUnitSetProperty 1:%ld", status);
		return status; 
	} 
				
	// Will be used by code below for defining bufferList, critical that this is set-up second
	// Describe format; not stereo for audio input! 
	audioFormat.mSampleRate			= 44100.0;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
		
	// For input recording
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Output, 
								  kInputBus, 
								  &audioFormat, 
								  sizeof(audioFormat));
	if(status!= noErr)
    {		
		NSLog(@"Failure at AudioUnitSetProperty 4:%ld", status); 		
		return status; 
	}
	
	// Set input callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = recordingCallback;
	// Set the reference to "self" this becomes *inRefCon in the playback callback
	callbackStruct.inputProcRefCon = self;
    
	status = AudioUnitSetProperty(audioUnit, 
								  kAudioOutputUnitProperty_SetInputCallback, 
								  kAudioUnitScope_Global, 
								  kInputBus, 
								  &callbackStruct, 
								  sizeof(callbackStruct));
	if(status!= noErr)
    {		
		NSLog(@"Failure at AudioUnitSetProperty 5:%ld", status); 		
		return status; 
	} 
				
	status = AudioUnitInitialize(audioUnit);
	if(status != noErr)
	{
		NSLog(@"Failure at AudioUnitInitialize:%ld", status); 		
		return status; 
	}
		
	return status;	
}


- (OSStatus) startRecord
{
	OSStatus status = AudioOutputUnitStart(audioUnit);
	if(status == noErr)
    {
		audioproblems = 0;
		startedCallback = YES;
	}
    else
	{
		NSLog(@"Failure at AudioOutputUnitStart:%ld", status);
        
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Problem with audio setup"
                                    message:@"Are you on an ipod touch without headphone microphone? AudioTest requires audio input, please make sure you have a microphone."
                                    delegate:self
                                    cancelButtonTitle:@"Press me then plugin microphone in"
                                    otherButtonTitles:nil];
		[anAlert show];
	}
    
    return status;
}


- (OSStatus) stopRecord
{
	OSStatus status = AudioOutputUnitStop(audioUnit);
	if(status != noErr)
	{
		NSLog(@"Failure at AudioOutputUnitStop:%ld", status);
	}
	else
    {
        if(startedCallback)
        {
            startedCallback	= NO;
        }
    }
    
    return status;
}


- (void) closeDownAudioDevice
{
    if(startedCallback)
    {
        [self stopRecord];
    }
    
	// AudioUnitUninitialize(audioUnit);
	
	// AudioSessionSetActive(false);
}


- (UInt16*) nextBufferAudioData
{
    return (UInt16*)bufferList->mBuffers[0].mData;
}

@end
