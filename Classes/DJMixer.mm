//
//  DJMixer.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import "DJMixer.h"


#pragma mark Listeners

void propListener (void                     *inClientData,
				  AudioSessionPropertyID	inID,
				  UInt32                    inDataSize,
				  const void                *inData)
{
	// RemoteIOPlayer *THIS = (RemoteIOPlayer*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
    {
        NSLog(@"Property Listener: kAudioSessionProperty_AudioRouteChange");
	}
	else if (inID == kAudioSessionProperty_AudioInputAvailable)
	{
        NSLog(@"Property Listener: kAudioSessionProperty_AudioInputAvailable");
    }
}


void rioInterruptionListener (void *inClientData, UInt32 inInterruption)
{
	NSLog(@"Session interrupted! --- %s ---", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
	
	if (inInterruption == kAudioSessionEndInterruption) 
    {
		// make sure we are again the active session
		AudioSessionSetActive(true);
		//AudioOutputUnitStart(THIS->audioUnit);
	}
	if (inInterruption == kAudioSessionBeginInterruption) 
    {
		//AudioOutputUnitStop(THIS->audioUnit);
    }
}

#pragma mark Callbacks

static OSStatus crossFaderMixerCallback (void *inRefCon, 
                                         AudioUnitRenderActionFlags *ioActionFlags, 
                                         const AudioTimeStamp       *inTimeStamp, 
                                         UInt32                     inBusNumber, 
                                         UInt32                     inNumberFrames, 
                                         AudioBufferList            *ioData) 
{  
	// Get a reference to the djMixer class, we need this as we are outside the class in just a straight C method.
	DJMixer *djMixer = (DJMixer *)inRefCon;
	
	UInt32 *frameBuffer = (UInt32*)ioData->mBuffers[0].mData;
	
    if(inBusNumber == 8)
    {
        if(djMixer.paused)
        {
            for(int frameNum = 0; frameNum < inNumberFrames; frameNum++)
            {
                frameBuffer[frameNum] = 0;
            }
        }
        else
        {
            for(int frameNum = 0; frameNum < inNumberFrames; frameNum++)
            {
                if(djMixer.packetIndex == djMixer.packetsInBuffer)
                {
                    djMixer.packetIndex = 0;
                }
                
                UInt16 value = djMixer.inputAudioData[djMixer.packetIndex++];
                frameBuffer[frameNum] = value + (value << 16);
            }
        }
    }
    else
    {
        InMemoryAudioFile *loop = djMixer.loop[inBusNumber];
        if(loop.playing)
        {
            for(int frameNum = 0; frameNum < inNumberFrames; frameNum++)
            {
                // get NextPacket returns a 32 bit value, one frame.
                frameBuffer[frameNum] = [loop getNextPacket];
            }
        }
        else
        {
            for(int frameNum = 0; frameNum < inNumberFrames; frameNum++)
            {
                frameBuffer[frameNum] = 0;
            }
       }
    }
    
	return 0;
}

static OSStatus masterFaderCallback (void                       *inRefCon,
                                    AudioUnitRenderActionFlags  *ioActionFlags, 
                                    const AudioTimeStamp        *inTimeStamp, 
                                    UInt32                      inBusNumber, 
                                    UInt32                      inNumberFrames, 
                                    AudioBufferList             *ioData) 
{  	
	// Get self
	DJMixer *djMixer = (DJMixer*)inRefCon;
    
    // Get the audio from the crossfader, we could directly connect them but this gives us a chance to get at the audio to apply an effect
    OSStatus err = AudioUnitRender(djMixer.crossFaderMixer, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
    // Apply master effect (if any)		
     
    return err;
}

// Called when there is a new buffer of input samples available
static OSStatus recordingCallback (void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData)
{
	// Get self
	DJMixer *djMixer = (DJMixer*)inRefCon;
    
	if(djMixer.recordingStarted)
    {
        // Fills bufferList->mBuffers[0].mData with audio data from microphone
		OSStatus result = AudioUnitRender(djMixer.output, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, djMixer.bufferList);
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

#pragma mark DJMixer

@implementation DJMixer

@synthesize crossFaderMixer;
@synthesize masterFaderMixer;
@synthesize output;
@synthesize loop;
@synthesize bufferList;
@synthesize packetsInBuffer;
@synthesize packetIndex;
@synthesize inputAudioData;
@synthesize recordingStarted;
@synthesize loadAudioQueue;
@synthesize paused;

- (id) init
{	
	self = [super init];
    if(self != nil)
    {    
        loop = (InMemoryAudioFile**)calloc(kNumChannels, sizeof(InMemoryAudioFile*));
        
        loop[0] = [[InMemoryAudioFile alloc]initForChannel:1];
        loop[1] = [[InMemoryAudioFile alloc]initForChannel:2];
        loop[2] = [[InMemoryAudioFile alloc]initForChannel:3];
        loop[3] = [[InMemoryAudioFile alloc]initForChannel:4];
        loop[4] = [[InMemoryAudioFile alloc]initForChannel:5];
        loop[5] = [[InMemoryAudioFile alloc]initForChannel:6];
        loop[6] = [[InMemoryAudioFile alloc]initForChannel:7];
        loop[7] = [[InMemoryAudioFile alloc]initForChannel:8];
        // loop[8] = [[InMemoryAudioFile alloc]initForChannel:9];
        
        loadAudioQueue = [[NSOperationQueue alloc] init];
        [loadAudioQueue setMaxConcurrentOperationCount:10];

        [self initAudio];
	}
    
	return self;
}


- (void) setUpData
{
    packetsInBuffer = 512;
	
	bufferList = (AudioBufferList*) malloc(sizeof(AudioBufferList));
	bufferList->mNumberBuffers = 1;
	for(UInt32 i = 0; i < bufferList->mNumberBuffers; i++)
	{
		bufferList->mBuffers[i].mNumberChannels = 1;
		bufferList->mBuffers[i].mDataByteSize = (packetsInBuffer * 2);    // 16bit packets
        
		bufferList->mBuffers[i].mData = malloc(bufferList->mBuffers[i].mDataByteSize);
        NSAssert(bufferList->mBuffers[i].mData != NULL, @"Memory Allocation Error.");
        inputAudioData = (UInt16*)bufferList->mBuffers[i].mData;
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


- (void) dealloc
{
    for(int idx = 0; idx < kNumChannels; idx++)
    {
        [loop[idx] release];
        loop[idx] = nil;
    }
    
    free(loop);
    
    [self freeData];
    
    [loadAudioQueue release];
    
    [super dealloc];
}

#pragma mark Control

- (void) pause:(BOOL)flag forChannel:(NSInteger)channel;
{
    int index = channel - 1;
    
    if(flag)
    {
        [loop[index] pause:flag];
    }
    else
    {
        [loop[index] pause:flag];
    }
}


- (void) changeCrossFaderAmount:(float)volume forChannel:(NSInteger)channel
{	    		
	// set the volume levels on the two input channels to the crossfader
	OSStatus err = AudioUnitSetParameter(crossFaderMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, channel - 1, volume, 0);
    NSAssert(err == noErr, @"Error setting Cross Fader");
}


- (void) pause:(BOOL)pause
{

    if(pause)
    {
        for(int idx = 0; idx < kNumChannels; idx++)
        {
            if(loop[idx].playing)
            {
                [loop[idx] pause:YES];
            }
        }
    }
    else
    {
        for(int idx = 0; idx < kNumChannels; idx++)
        {
            if(loop[idx].paused)
            {
                [loop[idx] pause:NO];
            }
        }
    }

    paused = pause;
}


- (BOOL) isPlaying
{
	Boolean graphRunning;
	AUGraphIsRunning(graph, &graphRunning);
    
    return graphRunning;
}


- (void) play
{
    OSStatus status;
    
	Boolean graphRunning;
	AUGraphIsRunning(graph, &graphRunning);
	if(!graphRunning)
	{
        [loop[kNumChannels - 1] start];

        for(int idx = 0; idx < kNumChannels - 1; idx++)
        {
            if(loop[idx].loaded)
            {
                [loop[idx] start];
            }
        }
        
        packetIndex = 0;

		status = AUGraphStart(graph);
		NSAssert(status == noErr, @"Error starting graph.");
	}

	status = AudioOutputUnitStart(output);
	if(status == noErr)
    {
        recordingStarted = YES;
    }
    else
    {
		NSLog(@"Failure at AudioOutputUnitStart:%ld", status);
    }
}


- (void) stop
{
	OSStatus status = AudioOutputUnitStop(output);
	if(status == noErr)
    {
        recordingStarted = NO;
    }
    else
	{
		NSLog(@"Failure at AudioOutputUnitStop:%ld", status);
	}

	Boolean graphRunning;
	AUGraphIsRunning(graph, &graphRunning);
	if(graphRunning)
	{
        status = AUGraphStop(graph);
        NSAssert(status == noErr, @"Error stopping graph.");
        
        [loop[kNumChannels - 1] stop];

        for(int idx = 0; idx < kNumChannels - 1; idx++)
        {
            if(loop[idx].playing || loop[idx].paused)
            {
                [loop[idx] stop];
            }
        }
    }
}


#pragma mark Initialization

-(void) initAudio
{
/*
	Getting the value of kAudioUnitProperty_ElementCount tells you how many elements you have in a scope.
	This happens to be 8 for this mixer.
	If you want to increase it, you need to set this property. 
*/
    [self setUpData];

	// Initialize and configure the audio session, and add an interuption listener
    AudioSessionInitialize(NULL, NULL, rioInterruptionListener, self);
				
    // set the audio session active
	AudioSessionSetActive(YES);

    // we do not want to allow recording if input is not available
    UInt32 inputAvailable = 0;
    UInt32 size = sizeof(inputAvailable);
    OSStatus status = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
	NSAssert(status == noErr, @"Error getting input availability.");
	if(inputAvailable == 0)
    {
        NSLog(@"Audio Input Available? %s", inputAvailable != 0 ? "yes" : "no");
        // Warn No input capability
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"No Audio Input Available!!" delegate:self
                                                                        cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
	}
 
    status = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self);
	NSAssert(status == noErr, @"Error adding audio session prop listener.");

    // we also need to listen to see if input availability changes
    status = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, propListener, self);
	NSAssert(status == noErr, @"Error adding audio session prop listener.");
 
	Float64 sampleRate;
	sampleRate = 44100.0; // Supports and changes to 22050.0 or 48000.0 too!
	status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, sizeof(sampleRate), &sampleRate);
	
	size = sizeof(sampleRate);
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &sampleRate);
	NSLog(@"Device sample rate %f", sampleRate);

	// Set preferred hardward buffer size of 1024; part of assumptions in callbacks
	Float32 preferredBufferSize = (float)packetsInBuffer / 44100.0;
	status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
	NSAssert(status == noErr, @"Error setting io buffer duration.");

    Float32 ioBufferSize;
	size = sizeof(ioBufferSize);
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &size, &ioBufferSize);
	NSLog(@"Hardware buffer size %f", ioBufferSize);
	
	// set the audio category
	UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord; // kAudioSessionCategory_AmbientSound;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
	
	UInt32 getAudioCategory = sizeof(audioCategory);
	AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &getAudioCategory, &getAudioCategory);
	if(getAudioCategory != kAudioSessionCategory_PlayAndRecord)
	{
		NSLog(@"Could not get kAudioSessionCategory_PlayAndRecord");
	}
    
    UInt32 numchannels;
	size = sizeof(numchannels);
	// Problematic: gives number of potential inputs, not number actually connected
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels, &size, &numchannels);
	NSAssert(status == noErr, @"Error getting number input channels.");
	NSLog(@"Input Channels %ld", numchannels);
	
	size = sizeof(numchannels);
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputNumberChannels, &size, &numchannels);
	NSAssert(status == noErr, @"Error getting number output channels.");
	NSLog(@"Output Channels %ld", numchannels);
     
	// the descriptions for the components
	AudioComponentDescription crossFaderMixerDescription, masterFaderDescription, outputDescription;	
	// the AUNodes
	AUNode crossFaderMixerNode, masterMixerNode, outputNode;
	
	// the graph
	status = NewAUGraph(&graph);
	NSAssert(status == noErr, @"Error creating graph.");

	// the cross fader mixer
	crossFaderMixerDescription.componentFlags = 0;
	crossFaderMixerDescription.componentFlagsMask = 0;
	crossFaderMixerDescription.componentType = kAudioUnitType_Mixer;
	crossFaderMixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	crossFaderMixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	status = AUGraphAddNode(graph, &crossFaderMixerDescription, &crossFaderMixerNode);
	NSAssert(status == noErr, @"Error creating mixer node.");
		
	// the master mixer
	masterFaderDescription.componentFlags = 0;
	masterFaderDescription.componentFlagsMask = 0;
	masterFaderDescription.componentType = kAudioUnitType_Mixer;
	masterFaderDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	masterFaderDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	status = AUGraphAddNode(graph, &masterFaderDescription, &masterMixerNode);
	NSAssert(status == noErr, @"Error creating mixer node.");
	
	// the output
	outputDescription.componentFlags = 0;
	outputDescription.componentFlagsMask = 0;
	outputDescription.componentType = kAudioUnitType_Output;
	outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	status = AUGraphAddNode(graph, &outputDescription, &outputNode);
	NSAssert(status == noErr, @"Error creating output node.");
	
	status = AUGraphOpen(graph);
	NSAssert(status == noErr, @"Error opening graph.");
	
	// get the cross fader
	status = AUGraphNodeInfo(graph, crossFaderMixerNode, &crossFaderMixerDescription, &crossFaderMixer);
	// get the master fader
	status = AUGraphNodeInfo(graph, masterMixerNode, &masterFaderDescription, &masterFaderMixer);
	// get the output
	status = AUGraphNodeInfo(graph, outputNode, &outputDescription, &output);
 
    // enable output node for recording
	UInt32 kInputBus = 1;
	UInt32 flag = 1;
	status = AudioUnitSetProperty(output,
								  kAudioOutputUnitProperty_EnableIO,
								  kAudioUnitScope_Input,
								  kInputBus,
								  &flag,
								  sizeof(flag));
	NSAssert(status == noErr, @"Error enabling output node for recording.");

	// Will be used by code below for defining bufferList, critical that this is set-up second
	// Describe input format; not stereo for audio input!
	audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
    
	// For input recording
	status = AudioUnitSetProperty(output,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Output,
								  kInputBus,
								  &audioFormat,
								  sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input audio format.");
	
	// Set input callback
	AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = recordingCallback;
	// Set the reference to "self" this becomes *inRefCon in the playback callback
	callbackStruct.inputProcRefCon = self;
    
	status = AudioUnitSetProperty(output,
								  kAudioOutputUnitProperty_SetInputCallback,
								  kAudioUnitScope_Global,
								  kInputBus,
								  &callbackStruct,
								  sizeof(callbackStruct));
	NSAssert(status == noErr, @"Error setting input audio callback.");
    
    UInt32 elementsCount = 8 + 1;       // 8 channels for mediaItems + audioInput
    UInt32 dataSize = sizeof(UInt32);
	status = AudioUnitSetProperty(crossFaderMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &elementsCount, dataSize);
		
	// the cross fader mixer
	AURenderCallbackStruct callbackCrossFader;
	callbackCrossFader.inputProc = crossFaderMixerCallback;
	// set the reference to "self" this becomes *inRefCon in the playback callback
	callbackCrossFader.inputProcRefCon = self;
	
	// mixer channel 1
	status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, 0, &callbackCrossFader);
	NSAssert(status == noErr, @"Error setting render callback 0 Cross fader.");
	// mixer channel 2
	status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, 1, &callbackCrossFader);
	NSAssert(status == noErr, @"Error setting render callback 1 Cross fader.");
	// mixer channel 3
	status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, 2, &callbackCrossFader);
	NSAssert(status == noErr, @"Error setting render callback 2 Cross fader.");
	// mixer channel 4
	status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, 3, &callbackCrossFader);
	NSAssert(status == noErr, @"Error setting render callback 3 Cross fader.");
	// mixer channel 5
	status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, 4, &callbackCrossFader);
	NSAssert(status == noErr, @"Error setting render callback 4 Cross fader.");
	// mixer channel 6
	status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, 5, &callbackCrossFader);
	NSAssert(status == noErr, @"Error setting render callback 5 Cross fader.");
	// mixer channel 7
	status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, 6, &callbackCrossFader);
	NSAssert(status == noErr, @"Error setting render callback 6 Cross fader.");
	// mixer channel 8
	status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, 7, &callbackCrossFader);
	NSAssert(status == noErr, @"Error setting render callback 7 Cross fader.");
	// mixer channel 9
	status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, 8, &callbackCrossFader);
	NSAssert(status == noErr, @"Error setting render callback 8 Cross fader.");
	
	// Set up the master fader callback
	AURenderCallbackStruct playbackCallbackStruct;
	playbackCallbackStruct.inputProc = masterFaderCallback;
	//set the reference to "self" this becomes *inRefCon in the playback callback
	playbackCallbackStruct.inputProcRefCon = self;
	
	status = AUGraphSetNodeInputCallback(graph, outputNode, 0, &playbackCallbackStruct);
	NSAssert(status == noErr, @"Error setting effects callback.");
			
	// Describe output format
	audioFormat.mSampleRate			= 44100.00;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 2;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 4;
	audioFormat.mBytesPerFrame		= 4;
		
	//set the master fader input properties
	status = AudioUnitSetProperty(output,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting RIO input property.");
	
	//set the master fader input properties
	status = AudioUnitSetProperty(masterFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting Master fader property.");
	
	//set the master fader input properties
	status = AudioUnitSetProperty(masterFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Output, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting Master fader property.");
	
	//set the crossfader output properties
	status = AudioUnitSetProperty(crossFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Output, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting output property format 0.");

	//set the crossfader input properties
	status = AudioUnitSetProperty(crossFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input property format 0.");
	
	status = AudioUnitSetProperty(crossFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   1, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input property format 1.");

	status = AudioUnitSetProperty(crossFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   2, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input property format 2.");

	status = AudioUnitSetProperty(crossFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   3, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input property format 3.");

	status = AudioUnitSetProperty(crossFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   4, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input property format 4.");

	status = AudioUnitSetProperty(crossFaderMixer, 
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   5, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input property format 5.");	

	status = AudioUnitSetProperty(crossFaderMixer, 
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   6, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input property format 6.");	

	status = AudioUnitSetProperty(crossFaderMixer, 
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   7, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input property format 7.");	

	status = AudioUnitSetProperty(crossFaderMixer,
							   kAudioUnitProperty_StreamFormat,
							   kAudioUnitScope_Input,
							   8,
							   &audioFormat,
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting input property format 8.");

	status = AUGraphInitialize(graph);
	NSAssert(status == noErr, @"Error initializing graph.");
	
	// CAShow(graph); 
}

@end
