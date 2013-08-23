//
//  DJMixer.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import "DJMixer.h"
#import "MusicAppAppDelegate.h"
#import "DJMixerViewController.h"
#import "LoadAudioOperation.h"

DJMixer* _this;

#pragma mark Listeners

void propListener (void *inClientData, AudioSessionPropertyID inID, UInt32 inDataSize, const void *inData)
{
	// RemoteIOPlayer *THIS = (RemoteIOPlayer*)inClientData;
	if(inID == kAudioSessionProperty_AudioRouteChange)
    {
        // NSLog(@"Property Listener: kAudioSessionProperty_AudioRouteChange");
		
		NSDictionary *routeChangeDictionary = (NSDictionary*)inData;
		// NSLog(@"routeChangeDictionary: %@", routeChangeDictionary);
		
		NSDictionary *newRouteDict = [routeChangeDictionary objectForKey:(id)kAudioSession_AudioRouteChangeKey_CurrentRouteDescription];
		NSDictionary *newRouteOutputs = [newRouteDict objectForKey:(id)kAudioSession_AudioRouteKey_Outputs];
		for(id output in newRouteOutputs)
		{
			NSString *outputsName = [output objectForKey:@"RouteDetailedDescription_UID"];
			// NSLog(@"RouteDetailedDescription_UID: %@", outputsName);
			
			if([outputsName isEqualToString:@"Wired Headphones"])
			{
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				if([defaults boolForKey:@"autoSetAudioInputOn"])
				{
					MusicAppDelegate *appDelegate = [MusicAppDelegate sharedInstance];
					[appDelegate.djMixerViewController enableAudioInput];
				}
			}
			else if([outputsName isEqualToString:@"Built-In Receiver"])
			{
				// Set output to internal (bottom) speaker
				UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
				OSStatus status = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof (audioRouteOverride), &audioRouteOverride);
				if(status != noErr)
				{
					NSLog(@"Could not override the audio route to internal speaker");
				}
				
				NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
				if([defaults boolForKey:@"autoSetAudioInputOn"])
				{
					MusicAppDelegate *appDelegate = [MusicAppDelegate sharedInstance];
					[appDelegate.djMixerViewController disableAudioInput];
				}
			}
		}
	}
	else if(inID == kAudioSessionProperty_AudioInputAvailable)
	{
        NSLog(@"Property Listener: kAudioSessionProperty_AudioInputAvailable");
	}
}


void rioInterruptionListener (void *inClientData, UInt32 inInterruption)
{
	// NSLog(@"%s", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
	
	if(inInterruption == kAudioSessionEndInterruption) 
    {
		// make sure we are again the active session
		AudioSessionSetActive(true);
		
		AudioOutputUnitStart(_this.output);
		AudioOutputUnitStart(_this.crossFaderMixer);
		AudioOutputUnitStart(_this.masterFaderMixer);
	}
	else if(inInterruption == kAudioSessionBeginInterruption)
    {
		AudioOutputUnitStop(_this.masterFaderMixer);
		AudioOutputUnitStop(_this.crossFaderMixer);
		AudioOutputUnitStop(_this.output);
		
		AudioSessionSetActive(false);
    }
}

#pragma mark Callbacks

static OSStatus crossFaderMixerCallback (void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, 
																	UInt32 inBusNumber, UInt32  inNumberFrames, AudioBufferList *ioData) 
{	
	// Get a reference to the djMixer class, we need this as we are outside the class in just a straight C method.
	DJMixer *djMixer = (DJMixer *)inRefCon;
	
	// NSLog(@"crossFaderMixerCallback - Packet: %ld", djMixer->durationPacketsIndex);

	UInt32 *frameBuffer = (UInt32*)ioData->mBuffers[0].mData;
	
    if(inBusNumber == 9)		// This is the Live Playback channel (9)
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
                if(djMixer->packetIndex == djMixer->packetsInBuffer)
                {
                    djMixer->packetIndex = 0;
                }
                
                UInt16 value = djMixer.inputAudioData[djMixer->packetIndex++];
                frameBuffer[frameNum] = value + (value << 16);
            }

#pragma message "Change this part"
			if(djMixer.savingFile)
			{
				if(djMixer.savingFileStartPacket == -1)
				{
					djMixer.savingFileStartPacket = djMixer->durationPacketsIndex;
				}
				
				OSStatus status = ExtAudioFileWriteAsync(djMixer.savingFileRef, inNumberFrames, ioData);
				if(status != noErr)
				{
					NSLog(@"Error %d in ExtAudioFileWriteAsync", (int)status);
				}
				else
				{
					djMixer.savingFilePackets += inNumberFrames;
				}
			}
		}
    }
	else if(inBusNumber == 0)	// This is the Sequencer channel (0)
	{
        InMemoryAudioFile *sequencer = djMixer.sequencer;
        if(!sequencer.noData)
        {
			*ioActionFlags &= ~kAudioUnitRenderAction_OutputIsSilence;
			
            for(int frameNum = 0; frameNum < inNumberFrames; frameNum++)
            {
                // getNextPacket returns a 32 bit value, one frame which is one packet.
				djMixer->framePacketsIndex = frameNum;
				frameBuffer[frameNum] = [sequencer getNextPacket];
            }
        }
        else
        {
			*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
		}
	}
    else						// These are all the other channels (1-8)
    {
		static BOOL playing = YES;
		
		InMemoryAudioFile *channel = djMixer.channels[inBusNumber - 1];
        if(channel.playing && !channel.noData)
        {
#pragma message "Change this part"
			if(NO /*djMixer.sequencer.playing*/)
			{
				if(playing)
				{
					NSLog(@"Channel %ld stops at packet %ld", inBusNumber, djMixer->durationPacketsIndex);
					
					playing = NO;
				}

				*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;

				for(int frameNum = 0; frameNum < inNumberFrames; frameNum++)
				{
					[channel getNextPacket];
				}
			}
			else
			{
				if(!playing)
				{
					NSLog(@"Channel %ld starts at packet %ld", inBusNumber, djMixer->durationPacketsIndex);
					
					playing = YES;
				}

				*ioActionFlags &= ~kAudioUnitRenderAction_OutputIsSilence;

				for(int frameNum = 0; frameNum < inNumberFrames; frameNum++)
				{					
					// getNextPacket returns a 32 bit value, one frame which is one packet.
					frameBuffer[frameNum] = [channel getNextPacket];
				}
			}
        }
        else
        {			
			*ioActionFlags |= kAudioUnitRenderAction_OutputIsSilence;
		}
    }
    
	return noErr;
}


static OSStatus masterFaderCallback (void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp,
																UInt32 inBusNumber, UInt32  inNumberFrames, AudioBufferList *ioData)
{
	// NSLog(@"masterFaderCallback...");

	DJMixer *djMixer = (DJMixer*)inRefCon;
	
	if(djMixer->durationPacketsIndex >= djMixer->durationPackets)
	{
		if(djMixer.loop)
		{
			djMixer->durationPacketsIndex = 0;
		}
	}
    
#if TARGET_IPHONE_SIMULATOR
    // This is a workaround for an issue with core audio on the simulator, likely due to 44100 vs 48000 difference in OSX
    if(inNumberFrames == 471)
	{
        inNumberFrames = 470;
	}
#endif

    // Get the audio from the crossfader, we could directly connect them but this gives us a chance to get at the audio to apply an effect
    OSStatus err = AudioUnitRender(djMixer.crossFaderMixer, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
    // Apply master effect, if any...
	if(err == noErr)
	{
#pragma message "Change this part"
/*
		if(djMixer.savingFile)
		{
			if(djMixer.savingFileStartPacket == -1)
			{
				djMixer.savingFileStartPacket = djMixer->durationPacketsIndex;				
			}
			
			OSStatus status = ExtAudioFileWriteAsync(djMixer.savingFileRef, inNumberFrames, ioData);
			if(status != noErr)
			{
				NSLog(@"Error %d in ExtAudioFileWriteAsync", (int)status);
			}
			else
			{
				djMixer.savingFilePackets += inNumberFrames;
			}
		}
*/		
		if(djMixer->durationPacketsIndex < djMixer->durationPackets)
		{
			djMixer->durationPacketsIndex += inNumberFrames;
		}
	}
    
    return err;
}


// Called when there is a new buffer of input samples available
static OSStatus recordingCallback (void* inRefCon, AudioUnitRenderActionFlags* ioActionFlags, const AudioTimeStamp* inTimeStamp,
																UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList* ioData)
{
	// NSLog(@"recordingCallback...");

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
                // NSLog(@"AudioUnitRender Failed: Invalid Parameter(s)");
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
@synthesize missingAudioInput;
@synthesize channels;
@synthesize playback;
@synthesize sequencer;
@synthesize bufferList;
@synthesize inputAudioData;
@synthesize recordingStarted;
@synthesize loadAudioQueue;
@synthesize paused;
@synthesize savingFile;
@synthesize savingFileRef;
@synthesize duration;
@synthesize durationPackets;
@synthesize playPosition;
@synthesize savingFileUrl;
@synthesize savingFileStartPacket;
@synthesize savingFilePackets;
@synthesize loop;

- (id) init
{	
	self = [super init];
    if(self != nil)
    {    
        channels = (InMemoryAudioFile**)calloc(kNumChannels, sizeof(InMemoryAudioFile*));
        
		// Output channels
        channels[0] = [[InMemoryAudioFile alloc] initForChannel:1];
        channels[1] = [[InMemoryAudioFile alloc] initForChannel:2];
        channels[2] = [[InMemoryAudioFile alloc] initForChannel:3];
        channels[3] = [[InMemoryAudioFile alloc] initForChannel:4];
        channels[4] = [[InMemoryAudioFile alloc] initForChannel:5];
        channels[5] = [[InMemoryAudioFile alloc] initForChannel:6];
        channels[6] = [[InMemoryAudioFile alloc] initForChannel:7];
        channels[7] = [[InMemoryAudioFile alloc] initForChannel:8];
		
		// Playback channel
		playback = [[InMemoryAudioFile alloc] initForPlayback];
		
		// Sequencer channel
		sequencer = [[InMemoryAudioFile alloc] initForSequencer];
        
        loadAudioQueue = [[NSOperationQueue alloc] init];
        [loadAudioQueue setMaxConcurrentOperationCount:10];
		
		_this = self;

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
        NSAssert(bufferList->mBuffers[i].mData != NULL, @"Memory Allocation Error");
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
        [channels[idx] release];
        channels[idx] = nil;
    }    
    free(channels);
	
	[playback release];
	playback = nil;

	[sequencer release];
	sequencer = nil;
    
    [self freeData];
    
    [loadAudioQueue release];
    
    [super dealloc];
}

#pragma mark Control

- (void) pause:(BOOL)flag forChannel:(NSInteger)channel;
{
    int index = channel;
    
    if(flag)
    {
        [channels[index] pause:flag];
    }
    else
    {
        [channels[index] pause:flag];
    }
}


- (void) changeCrossFaderAmount:(double)volume forChannel:(NSInteger)channel
{
	if(channel >= 1 && channel <= 8)
	{
		// NSLog(@"Channel %d fader:%.1f", channel, volume);
	}
	else if(channel == 9)
	{
		// NSLog(@"Playback fader:%.1f", volume);
	}
	else if(channel == 0)
	{
		// NSLog(@"Sequencer fader:%.1f", volume);
	}
	
	// Set the volume levels on the two input channels to the crossfader
	OSStatus status = AudioUnitSetParameter(crossFaderMixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, channel, volume, 0);
    NSAssert1(status == noErr, @"Error %ld setting Cross Fader", status);
}


- (void) pause:(BOOL)pause
{
	OSStatus status = noErr;
	
    if(pause)
    {
		NSLog(@"Going in Pause");
		
		status = AudioOutputUnitStop(output);
		if(status == noErr)
		{
			AudioSessionSetActive(false);
			
			paused = YES;
		}
		else
		{
			NSLog(@"Failure at AudioOutputUnitStop:%ld", status);
		}

		if(sequencer.playing)
		{
			[sequencer pause:YES];
		}

        for(int idx = 0; idx < kNumChannels; idx++)
        {
            if(channels[idx].playing)
            {
                [channels[idx] pause:YES];
            }
        }

    }
    else
    {
		NSLog(@"Exiting from Pause");
		totFrameNum = 0;

        for(int idx = 0; idx < kNumChannels; idx++)
        {
            if(channels[idx].paused)
            {
                [channels[idx] pause:NO];
            }
        }
		
		if(sequencer.paused)
		{
			[sequencer pause:NO];
		}

		status = AudioOutputUnitStart(output);
		if(status == noErr)
		{
			AudioSessionSetActive(true);
			
			paused = NO;
		}
		else
		{
			NSLog(@"Failure at AudioOutputUnitStart:%ld", status);
		}
	}
}


- (BOOL) isPlaying
{
	Boolean graphRunning;
	AUGraphIsRunning(graph, &graphRunning);
    
    return graphRunning;
}


- (BOOL) hasData
{
	for(int idx = 0; idx < kNumChannels; idx++)
	{
		if(channels[idx].loaded && !channels[idx].noData)
		{
			return YES; // Some channel has data...
		}
	}
/*
	if(sequencer.loaded && !sequencer.noData)
	{
		return YES;		// Sequencer has data...
	}
*/
	return NO;	// None of the output channels has data...
}


- (void) startPlay
{
	NSLog(@"DJMixer Start:");

    OSStatus status = noErr;
    
	Boolean graphRunning;
	AUGraphIsRunning(graph, &graphRunning);
	if(!graphRunning)
	{        
        packetIndex = 0;
		durationPacketsIndex = playPosition * kSamplingRate;

		[playback start]; // Start Playback channel
		
		[sequencer start]; // Start Sequencer channel
		
		// Start Output channels
        for(int idx = 0; idx < kNumChannels; idx++)
        {
            if(channels[idx].loaded)
            {
                [channels[idx] start];
            }
        }
		
		[NSThread sleepForTimeInterval:0.1];

		status = AUGraphStart(graph);
		NSAssert1(status == noErr, @"Error %ld starting graph", status);
	}

	status = AudioOutputUnitStart(output);
	//if(status == noErr)
	//status = AudioOutputUnitStart(crossFaderMixer);
	//if(status == noErr)
	//status = AudioOutputUnitStart(masterFaderMixer);
	if(status == noErr)
    {
		AudioSessionSetActive(true);

        recordingStarted = YES;
    }
    else
    {
		NSLog(@"Failure at AudioOutputUnitStart:%ld", status);
    }
}


- (void) stopPlay
{
	NSLog(@"DJMixer Stop:");
	
	OSStatus status = noErr;

	//status = AudioOutputUnitStop(masterFaderMixer);
	//if(status == noErr)
	//status = AudioOutputUnitStop(crossFaderMixer);
	//if(status == noErr)
	status = AudioOutputUnitStop(output);
	if(status == noErr)
    {
		AudioSessionSetActive(false);
		
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
        NSAssert1(status == noErr, @"Error %ld stopping graph", status);
        
		[playback stop];	// Stop Playback channel
		
		[sequencer stop];	// Stop Sequencer channel

		// Stop Output channels
        for(int idx = 0; idx < kNumChannels; idx++)
        {
            if(channels[idx].playing || channels[idx].paused)
            {
                [channels[idx] stop];
            }
        }
		
		[sequencer.operation setStartPlayPosition:playPosition reset:YES];
/*
		// Set next start position to stop position
        for(int idx = 0; idx < kNumChannels; idx++)
        {
			[channels[idx].operation setStartPlayPosition:playPosition reset:NO];
		}
*/
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
				
    // Set the audio session active
	AudioSessionSetActive(true);

    // Dont allow recording if input is not available
    UInt32 inputAvailable = 0;
    UInt32 size = sizeof(inputAvailable);
    OSStatus status = AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &inputAvailable);
	NSAssert(status == noErr, @"Error getting property kAudioSessionProperty_AudioInputAvailable");
	if(inputAvailable == 0)
    {
		missingAudioInput = YES;
		
        NSLog(@"Audio Input Available? %s", inputAvailable != 0 ? "yes" : "no");
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Warning" message:@"No Audio Input Available!!" delegate:self
                                                                        cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
	}
	
	UInt32 otherAudioIsPlaying = 0;
    size = sizeof(otherAudioIsPlaying);
    status = AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &otherAudioIsPlaying);
	NSAssert(status == noErr, @"Error getting property kAudioSessionProperty_OtherAudioIsPlaying");
	if(otherAudioIsPlaying != 0)
    {
        NSLog(@"Other Audio Software is Playing");
 	}
 
    status = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, self);
	NSAssert(status == noErr, @"Error adding kAudioSessionProperty_AudioRouteChange property listener");

    // we also need to listen to see if input availability changes
    status = AudioSessionAddPropertyListener(kAudioSessionProperty_AudioInputAvailable, propListener, self);
	NSAssert(status == noErr, @"Error adding kAudioSessionProperty_AudioInputAvailable property listener");
 
	Float64 sampleRate;
	sampleRate = kSamplingRate; // Supports and changes to 22050.0 or 48000.0 too!
	status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, sizeof(sampleRate), &sampleRate);
	NSAssert(status == noErr, @"Error setting kAudioSessionProperty_PreferredHardwareSampleRate property");
	
	size = sizeof(sampleRate);
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &sampleRate);
	NSAssert(status == noErr, @"Error getting kAudioSessionProperty_CurrentHardwareSampleRate property");
	NSLog(@"Device sample rate %f", sampleRate);

	// Set preferred hardward buffer size of 1024; part of assumptions in callbacks
	Float32 preferredBufferSize = (double)packetsInBuffer / kSamplingRate;
	status = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
	NSAssert(status == noErr, @"Error setting io buffer duration");

    Float32 ioBufferSize;
	size = sizeof(ioBufferSize);
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareIOBufferDuration, &size, &ioBufferSize);
	NSAssert(status == noErr, @"Error getting kAudioSessionProperty_CurrentHardwareIOBufferDuration property");
	NSLog(@"Hardware buffer size %f", ioBufferSize);
	
	// Set the audio category
	UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
	
	UInt32 getAudioCategory = sizeof(audioCategory);
	AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &getAudioCategory, &getAudioCategory);
	if(getAudioCategory != kAudioSessionCategory_PlayAndRecord)
	{
		NSLog(@"Could not get kAudioSessionCategory_PlayAndRecord");
	}
	
	if(![self headsetPluggedIn])
	{
		// Set output to internal (bottom) speaker
		UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
		status = AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
		if(status != noErr)
		{
			NSLog(@"Could not override the audio route to internal speaker");
		}
	}
		
    UInt32 numchannels;
	size = sizeof(numchannels);
	// Problematic: gives number of potential inputs, not number actually connected
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareInputNumberChannels, &size, &numchannels);
	NSAssert(status == noErr, @"Error getting number input channels");
	NSLog(@"Input Channels %ld", numchannels);
	
	size = sizeof(numchannels);
	status = AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareOutputNumberChannels, &size, &numchannels);
	NSAssert(status == noErr, @"Error getting number output channels");
	NSLog(@"Output Channels %ld", numchannels);
     
	// The descriptions for the components
	AudioComponentDescription crossFaderMixerDescription, masterFaderDescription, outputDescription;	
	// The AUNodes
	AUNode crossFaderMixerNode, masterMixerNode, outputNode;
	
	// The graph
	status = NewAUGraph(&graph);
	NSAssert(status == noErr, @"Error creating graph");

	// the cross fader mixer
	crossFaderMixerDescription.componentFlags = 0;
	crossFaderMixerDescription.componentFlagsMask = 0;
	crossFaderMixerDescription.componentType = kAudioUnitType_Mixer;
	crossFaderMixerDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	crossFaderMixerDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	status = AUGraphAddNode(graph, &crossFaderMixerDescription, &crossFaderMixerNode);
	NSAssert(status == noErr, @"Error creating mixer node");
		
	// the master mixer
	masterFaderDescription.componentFlags = 0;
	masterFaderDescription.componentFlagsMask = 0;
	masterFaderDescription.componentType = kAudioUnitType_Mixer;
	masterFaderDescription.componentSubType = kAudioUnitSubType_MultiChannelMixer;
	masterFaderDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	status = AUGraphAddNode(graph, &masterFaderDescription, &masterMixerNode);
	NSAssert(status == noErr, @"Error creating mixer node");
	
	// the output
	outputDescription.componentFlags = 0;
	outputDescription.componentFlagsMask = 0;
	outputDescription.componentType = kAudioUnitType_Output;
	outputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	outputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	status = AUGraphAddNode(graph, &outputDescription, &outputNode);
	NSAssert(status == noErr, @"Error creating output node");
	
	status = AUGraphOpen(graph);
	NSAssert(status == noErr, @"Error opening graph");
	
	// Get the cross fader
	status = AUGraphNodeInfo(graph, crossFaderMixerNode, &crossFaderMixerDescription, &crossFaderMixer);
	NSAssert(status == noErr, @"Error AUGraphNodeInfo for Cross Fader");
	
	// Get the master fader
	status = AUGraphNodeInfo(graph, masterMixerNode, &masterFaderDescription, &masterFaderMixer);
	NSAssert(status == noErr, @"Error AUGraphNodeInfo for Master Fader");
	
	// Get the output
	status = AUGraphNodeInfo(graph, outputNode, &outputDescription, &output);
	NSAssert(status == noErr, @"Error AUGraphNodeInfo for Output");
 
    // Enable output node for recording
	UInt32 kInputBus = 1;
	UInt32 flag = 1;
	status = AudioUnitSetProperty(output,
								  kAudioOutputUnitProperty_EnableIO,
								  kAudioUnitScope_Input,
								  kInputBus,
								  &flag,
								  sizeof(flag));
	NSAssert(status == noErr, @"Error enabling output node for recording");

	// Will be used by code below for defining bufferList, critical that this is set-up second
	// Describe input format; not stereo for audio input!
	audioFormat.mSampleRate			= kSamplingRate;
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
	NSAssert(status == noErr, @"Error setting input audio format");
	
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
	NSAssert(status == noErr, @"Error setting input audio callback");
    
    UInt32 elementsCount = 1 + 8 + 1;   // Sequencer + 8 Channels + Playback
    UInt32 dataSize = sizeof(UInt32);
	status = AudioUnitSetProperty(crossFaderMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &elementsCount, dataSize);
	NSAssert(status == noErr, @"Error setting kAudioUnitProperty_ElementCount Input property");
		
	// The cross fader mixer
	AURenderCallbackStruct callbackCrossFader;
	callbackCrossFader.inputProc = crossFaderMixerCallback;
	// Set the reference to "self" this becomes *inRefCon in the playback callback
	callbackCrossFader.inputProcRefCon = self;
	
	for(int idx = 0; idx < elementsCount; idx++)
	{
		status = AUGraphSetNodeInputCallback(graph, crossFaderMixerNode, idx, &callbackCrossFader);
		if(status != noErr)
		{
			NSString *msg = [NSString stringWithFormat:@"Error setting render callback Cross Fader for channel %d", idx];
			NSLog(@"%@", msg);
			NSAssert(status == noErr, msg);
		}
	}
	
	// Set up the master fader callback
	AURenderCallbackStruct playbackCallbackStruct;
	playbackCallbackStruct.inputProc = masterFaderCallback;
	// Set the reference to "self" this becomes *inRefCon in the playback callback
	playbackCallbackStruct.inputProcRefCon = self;
	
	status = AUGraphSetNodeInputCallback(graph, outputNode, 0, &playbackCallbackStruct);
	NSAssert(status == noErr, @"Error setting effects callback");
			
	// Describe output format
	audioFormat.mSampleRate			= kSamplingRate;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 2;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 4;
	audioFormat.mBytesPerFrame		= 4;
		
	status = AudioUnitSetProperty(output,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error kAudioUnitProperty_StreamFormat Input property of Output");
	
	// Set the master fader input properties
	status = AudioUnitSetProperty(masterFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Input, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting kAudioUnitProperty_StreamFormat Input property of Master Fader");
	
	// Set the master fader input properties
	status = AudioUnitSetProperty(masterFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Output, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting kAudioUnitProperty_StreamFormat Output property of Master Fader");
	
	// Set the crossfader output properties
	status = AudioUnitSetProperty(crossFaderMixer,
							   kAudioUnitProperty_StreamFormat, 
							   kAudioUnitScope_Output, 
							   0, 
							   &audioFormat, 
							   sizeof(audioFormat));
	NSAssert(status == noErr, @"Error setting kAudioUnitProperty_StreamFormat Output property of Cross Fader");

	// Set the crossfader input properties
	for(int idx = 0; idx < elementsCount; idx++)
	{
		status = AudioUnitSetProperty(crossFaderMixer,
									  kAudioUnitProperty_StreamFormat,
									  kAudioUnitScope_Input,
									  idx,
									  &audioFormat,
									  sizeof(audioFormat));
		if(status != noErr)
		{
			NSString *msg = [NSString stringWithFormat:@"Error setting Cross Fader input property format for channel %d", idx];
			NSLog(@"%@", msg);
			NSAssert(status == noErr, msg);
		}
	}

	status = AUGraphInitialize(graph);
	NSAssert1(status == noErr, @"Error %ld initializing graph", status);
}


- (UInt32) getTotalPackets
{
	return durationPacketsIndex;
}


- (void) setStartPosition:(NSTimeInterval)time reset:(BOOL)reset
{
	if(time != playPosition)
	{
		reset = YES;
	}
	
	for(int idx = 0; idx < kNumChannels; idx++)
	{
		if(channels[idx].loaded)
		{
			if(reset)
			{
				[channels[idx] reset];
			}
			
			[channels[idx].operation setStartPlayPosition:time reset:reset];
		}
	}

	if(sequencer.loaded)
	{
		if(reset)
		{
			[sequencer reset];
		}
		
		[sequencer.operation setStartPlayPosition:time reset:reset];
	}

	playPosition = time;
}

- (BOOL) headsetPluggedIn
{
    UInt32 routeSize = sizeof(CFStringRef);
    CFStringRef route;	
    OSStatus status = AudioSessionGetProperty (kAudioSessionProperty_AudioRoute, &routeSize, &route);
    if (status ==  noErr && (route != NULL))
	{
        NSRange headphoneRange = [(NSString*)route rangeOfString:@"Head"];
        if(headphoneRange.location != NSNotFound)
		{
			return YES;
		}
    }
	
    return NO;
}

@end
