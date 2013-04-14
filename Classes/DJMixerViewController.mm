//
//  DJMixerViewController.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import "MusicAppAppDelegate.h"
#import "DJMixer.h"
#import "DJMixerViewController.h"
#import "SettingsViewController.h"
#import "SelectionViewController.h"
#import "CoreText/CoreText.h"
#import "UITextScroll.h"
#import "Karaoke.h"
#import "LoadAudioOperation.h"
#import "AudioToolbox/AudioToolbox.h"


#define PLAYPOSITION_LABEL_PRECISION @"%.1f"	// Show 10th of second
#define PLAYPOSITION_TIMER_FREQUENCY 0.025		// Check every 20th of second

@implementation DJMixerViewController

@synthesize portraitView;
@synthesize landscapeView;
@synthesize channel1Slider;
@synthesize channel2Slider;
@synthesize channel3Slider;
@synthesize channel4Slider;
@synthesize channel5Slider;
@synthesize channel6Slider;
@synthesize channel7Slider;
@synthesize channel8Slider;
@synthesize audioInputSlider;
@synthesize channel1Label;
@synthesize channel2Label;
@synthesize channel3Label;
@synthesize channel4Label;
@synthesize channel5Label;
@synthesize channel6Label;
@synthesize channel7Label;
@synthesize channel8Label;
@synthesize audioInputLabel;
@synthesize playButton;
@synthesize pauseSwitch;
@synthesize selectButton;
@synthesize karaokeButton;
@synthesize karaokeText;
@synthesize karaokeActivated;

@synthesize playButtonLS;
@synthesize pauseSwitchLS;
@synthesize selectButtonLS;
@synthesize karaokeButtonLS;
@synthesize karaokeTextLS;
@synthesize positionLabelLS;
@synthesize durationLabelLS;
@synthesize positionSliderLS;

@synthesize djMixer;
@synthesize recordingFilePath;
@synthesize karaoke;
@synthesize karaokeTimer;
@synthesize checkDiskSizeTimer;
@synthesize checkPositionTimer;
@synthesize isPortrait;

- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self != nil)
    {
	}
    
    return self;
}


- (void) didReceiveMemoryWarning
{
    NSLog(@"didReceiveMemoryWarning sent to %@", self);
    
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
                                     // Release anything that's not essential, such as cached data
}


- (void) dealloc
{
    [super dealloc];
	
	[channelLabels release];
	[channelSliders release];
}


- (void) viewDidLoad
{
	channelLabels = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
						channel1Label, @"Channel-1",
						channel2Label, @"Channel-2",
						channel3Label, @"Channel-3",
						channel4Label, @"Channel-4",
						channel5Label, @"Channel-5",
						channel6Label, @"Channel-6",
						channel7Label, @"Channel-7",
						channel8Label, @"Channel-8",
						audioInputLabel, @"Channel-9", nil];
	
	channelSliders = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
						channel1Slider, @"Channel-1",
						channel2Slider, @"Channel-2",
						channel3Slider, @"Channel-3",
						channel4Slider, @"Channel-4",
						channel5Slider, @"Channel-5",
						channel6Slider, @"Channel-6",
						channel7Slider, @"Channel-7",
						channel8Slider, @"Channel-8",
						audioInputSlider, @"Channel-9", nil];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
 
    [self saveControlsValue];
    
    if(self.karaoke != nil)
    {
        if(karaokeTimer != nil)
        {
            [karaokeTimer invalidate];
            karaokeTimer = nil;
        }
        
        [self.karaokeButton setHighlighted:NO];
        [self.karaokeButtonLS setHighlighted:NO];

        [self.karaoke release];
        self.karaoke = nil;
    }
	
	[positionSliderLS removeTarget:self action:@selector(setPlayPositionEnded:) forControlEvents:UIControlEventTouchUpInside];
	
	// [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    int totLoadedChannels = 0;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	BOOL loop = [defaults boolForKey:@"PlayContinuousOn"];
	
	double maxDuration = 0.0;
	
	// Init all output channels
	for(NSInteger idx = 0; idx < 8; idx++)
	{
		NSString *channelStr = [NSString stringWithFormat:@"Channel-%d", idx + 1];
		
		NSDictionary *channelDict = [defaults objectForKey:channelStr];
		if(channelDict != nil)
		{
			NSString *url = [channelDict objectForKey:@"AudioUrl"];
			if(url == nil)
			{
				[djMixer.channels[idx] freeStuff];
			}
			else
			{
				[djMixer.channels[idx] removeLoadOperation]; // Remove the previous operation if present
				
				LoadAudioOperation *loadOperation = [[LoadAudioOperation alloc] initWithAudioFile:url mixer:djMixer loop:loop];
				[djMixer.loadAudioQueue addOperation:loadOperation];
				[djMixer.channels[idx] setLoadOperation:loadOperation];				
			}
		}
		
		UILabel *label = [channelLabels objectForKey:channelStr];
		UISlider *slider = [channelSliders objectForKey:channelStr];
		
		if(djMixer.channels[idx].loaded)
		{
			totLoadedChannels++;
			double sliderValue = [[channelDict objectForKey:@"AudioVolume"] doubleValue];
			
			[label setText:[NSString stringWithFormat:@"%@ (%d)", [channelDict objectForKey:@"AudioTitle"], djMixer.channels[idx].trackCount]];
			[slider setEnabled:YES];
			[slider setValue:sliderValue];
			
			[djMixer changeCrossFaderAmount:sliderValue forChannel:idx + 1];

			double duration = [[channelDict objectForKey:@"AudioDuration"] doubleValue];
			if(duration > maxDuration)
			{
				maxDuration = duration;
			}
		}
		else
		{
			[label setText:@""];
			[slider setEnabled:NO];
			[slider setValue:0.0];
		}
	}
	
	// Find a better way to compute duration and durationPackets internally to DJMixer
	djMixer.duration = maxDuration;
	djMixer.durationPackets = maxDuration * 44100.0;
	
	[djMixer setStartPosition:0.0];
	
	durationLabelLS.text = [NSString stringWithFormat:PLAYPOSITION_LABEL_PRECISION, maxDuration];
	positionLabelLS.text = @"0";
	positionSliderLS.value = 0.0;

	if(!djMixer.missingAudioInput)
	{
		// Init the input channel which is referenced as Channel-9 even if is very different...
		NSString *channelStr = @"Channel-9";
		NSDictionary *channelDict = [defaults objectForKey:channelStr];
		if(channelDict != nil)
		{
			double sliderValue = [[channelDict objectForKey:@"AudioVolume"] doubleValue];
				
			UISlider *slider = [channelSliders objectForKey:channelStr];
			[slider setEnabled:YES];
			[slider setValue:sliderValue];
				
			[djMixer changeCrossFaderAmount:sliderValue forChannel:9];
		}
	}
	else
	{
		[self disableAudioInput];
	}
/*
    [playButton setEnabled:(totLoadedChannels != 0)];
    [playButtonLS setEnabled:(totLoadedChannels != 0)];
*/
    [pauseSwitch setEnabled:NO];
    [pauseSwitchLS setEnabled:NO];
   
    [karaokeText setAttributedText:nil];
    [karaokeTextLS setAttributedText:nil];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"KaraokeData.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSLog(@"Karaoke file %@ is available", filePath);
        
        NSArray *data = [NSArray arrayWithContentsOfFile:filePath];
        self.karaoke = [[Karaoke alloc] initKaraoke:data];
    }
    else
    {
        NSLog(@"Karaoke file %@ is missing", filePath);
    }
	
	// Seems better to use applicationDidEnterBackground in app delegate
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    [self.karaokeButton setEnabled: (self.karaoke != nil)];
    [self.karaokeButtonLS setEnabled: (self.karaoke != nil)];
    
	[positionSliderLS addTarget:self action:@selector(setPlayPositionEnded:) forControlEvents:UIControlEventTouchUpInside];
    
	self.isPortrait = (self.interfaceOrientation == UIDeviceOrientationPortrait || self.interfaceOrientation == UIDeviceOrientationPortraitUpsideDown);
}


- (void) saveControlsValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for(int idx = 1; idx <= 9; idx++)
    {
		NSString *channelStr = [NSString stringWithFormat:@"Channel-%d", idx];

        NSDictionary *channelDict = [defaults objectForKey:channelStr];
        if(channelDict != nil)
        {
            NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:channelDict];
            
            [newDict setObject:[NSNumber numberWithDouble:[(UISlider*)[channelSliders objectForKey:channelStr] value]] forKey:@"AudioVolume"];
            
            // NSLog(@"%@", [NSNumber numberWithDouble:[sliders[idx - 1] value]]);
            
            [defaults setObject:newDict forKey:channelStr];
        }
        else
        {
            NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:channelDict];
            
            [newDict setObject:[NSNumber numberWithDouble:0.0] forKey:@"AudioVolume"];
            
            [defaults setObject:newDict forKey:channelStr];
        }
    }
    
    [defaults synchronize];
}


- (void) updateDefaults:(UISlider*)slider
{
    static NSUserDefaults *defaults = [[NSUserDefaults standardUserDefaults] retain];
   
	NSString *channelStr = [[channelSliders allKeysForObject:slider] objectAtIndex:0];
    NSDictionary *channelDict = [defaults objectForKey:channelStr];
    if(channelDict != nil)
    {
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:channelDict];            
        [newDict setObject:[NSNumber numberWithDouble:[(UISlider*)[channelSliders objectForKey:channelStr] value]] forKey:@"AudioVolume"];
            
        [defaults setObject:newDict forKey:channelStr];        
        [defaults synchronize];
    }
}


- (IBAction) changeVolume:(UISlider*)sender
{
	static NSCharacterSet *numbers = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] retain];
/*
    if(sender.tag == 9)
    {
        if(sender.value == 0.0)
        {
            NSLog(@"AUDIO INPUT OFF");
        }
        else
        {
            NSLog(@"AUDIO INPUT ON");
       }
    }
*/
	NSString *channelStr = [[channelSliders allKeysForObject:sender] objectAtIndex:0];
	NSScanner *scanner = [NSScanner scannerWithString:channelStr];
	[scanner scanUpToCharactersFromSet:numbers intoString:NULL];
	int channel;
	[scanner scanInt:&channel];
	
    [djMixer changeCrossFaderAmount:sender.value forChannel:channel];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), 
    ^{
        [self updateDefaults:sender];
    });
}


- (IBAction) playOrStop
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if([djMixer isPlaying])
    {
        [djMixer stopPlay];
        
        if([defaults boolForKey:@"KaraokeAutoOn"] && karaokeActivated)
        {
            [self doKaraoke:nil];
        }

       if([defaults boolForKey:@"RecordingAutoOn"] && djMixer.fileRecording)
        {
            [self doRecord:nil];
        }
		
		[checkPositionTimer invalidate];
		checkPositionTimer = nil;

		[playButton setTitle:@"Play" forState:UIControlStateNormal];
        [playButtonLS setTitle:@"Play" forState:UIControlStateNormal];
        
        [selectButton setEnabled:YES];
        [selectButtonLS setEnabled:YES];
        
        [pauseSwitch setEnabled:NO];       
        [pauseSwitchLS setEnabled:NO];
        
        [pauseSwitch setOn:NO];
        [pauseSwitchLS setOn:NO];
    }
    else
    {
		checkPositionTimer = [NSTimer scheduledTimerWithTimeInterval:PLAYPOSITION_TIMER_FREQUENCY target:self selector:@selector(updatePlayPosition) userInfo:(id)kCFBooleanTrue repeats:YES];

        [djMixer startPlay];
        
		if([defaults boolForKey:@"RecordingAutoOn"] && !djMixer.fileRecording)
        {
            [self doRecord:nil];
        }

        if([defaults boolForKey:@"KaraokeAutoOn"] && !karaokeActivated)
        {
            [self doKaraoke:nil];
        }

        [playButton setTitle:@"Stop" forState:UIControlStateNormal];
        [playButtonLS setTitle:@"Stop" forState:UIControlStateNormal];
        
        [selectButton setEnabled:NO];
        [selectButtonLS setEnabled:NO];
        
        [pauseSwitch setEnabled:YES];
        [pauseSwitchLS setEnabled:YES];
    }
}


- (IBAction) goSettings:(UIButton*)sender
{
    if(!self.isPortrait)
    {
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Error!"  message:@"The Settings can be accessed only with the Screen in Portrait orientation."
                                                         delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[anAlert show];        
        return;
    }

    SettingsViewController *settings = [[[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil] autorelease];
    assert(settings != nil);
    
    // Custom animated transition
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration: 0.5];    
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view.window cache:YES];
    
    [self presentViewController:settings animated:NO completion:nil];   // Show the new view
    
    [UIView commitAnimations];    // Play the animation
}


- (IBAction) doPause:(UISwitch*)sender
{
    [djMixer pause:sender.on];
}


- (void)doHighlight:(UIButton*)btn
{
    [btn setHighlighted:YES];
}


- (IBAction) doRecord:(UIButton*)sender
{
	if(djMixer.fileRecording)
	{
		[self recordStop];
	}
	else
	{
		[self recordStart];
	}
}


- (IBAction) setPlayPosition:(UISlider*)sender
{	
	double playPosition = djMixer.duration * sender.value;
	
	positionLabelLS.text = [NSString stringWithFormat:PLAYPOSITION_LABEL_PRECISION, playPosition];

	if([djMixer isPlaying])
	{
		if(!djMixer.paused)
		{
			[djMixer pause:YES];
		}
		
		[checkPositionTimer setFireDate:[NSDate distantFuture]];
		
		// ADD A TIMER to check Slider value. If it remains the same for a little then play audio from there...

		NSLog(@"Set current play position to %.1f", playPosition);
	}
	else
	{
		NSLog(@"Set start position to %.1f", playPosition);
	}
}


- (void) updatePlayPosition
{
	if(!djMixer.hasData)
	{
		[self playOrStop];

		if(YES) // Set the slider to the very end
		{
			djMixer.playPosition = djMixer.duration;
			
			[positionSliderLS setValue:1.0 animated:YES];
			positionLabelLS.text = [NSString stringWithFormat:PLAYPOSITION_LABEL_PRECISION, djMixer.playPosition];
		}
		else	// Set the slider back to beginning
		{
			djMixer.playPosition = 0.0;
			
			[positionSliderLS setValue:0.0 animated:NO];
			positionLabelLS.text = [NSString stringWithFormat:PLAYPOSITION_LABEL_PRECISION, djMixer.playPosition];
		}
	}
	else
	{
		UInt32 totalPackets = [djMixer getTotalPackets];
		djMixer.playPosition = (double)totalPackets / 44100.0;	
		double sliderPosition = 1.0 / (djMixer.duration / djMixer.playPosition);
		
		if(fabs(positionSliderLS.value - sliderPosition) > 0.0001) // Don't go inside here if nothing gonna displayed different...
		{
			[positionSliderLS setValue:sliderPosition animated:NO];
			positionLabelLS.text = [NSString stringWithFormat:PLAYPOSITION_LABEL_PRECISION, djMixer.playPosition];
		}
	}
}


- (void) setPlayPositionEnded:(UISlider*)sender
{
	double playPosition = djMixer.duration * sender.value;

	if([djMixer isPlaying])
	{
		[djMixer pause:NO];

		[djMixer setCurrentPlayPosition:playPosition];

		[checkPositionTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	}
	else
	{
		[djMixer setStartPosition:playPosition];
	}
}


- (void) recordStart
{
	AudioFileTypeID fileType = kAudioFileCAFType;
	OSStatus status = noErr;
	NSString *fileName = nil;
	
	if([self checkDiskSize:NO] < 10)
	{
		NSString *msg = @"Is not possible to start recording with less than 10 Mib of free space.";
		alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
		return;
	}
	
	NSLog(@"Starting recording...");
	
	AudioStreamBasicDescription stereoStreamFormat;
	memset(&stereoStreamFormat, 0, sizeof(stereoStreamFormat));
    stereoStreamFormat.mSampleRate        = 44100.0;
    stereoStreamFormat.mFormatID          = kAudioFormatLinearPCM;
    stereoStreamFormat.mFormatFlags       = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    stereoStreamFormat.mFramesPerPacket   = 1;
	stereoStreamFormat.mChannelsPerFrame  = 2;                    // 2 indicates stereo
    stereoStreamFormat.mBitsPerChannel    = 16;
    stereoStreamFormat.mBytesPerPacket    = 4;
	stereoStreamFormat.mBytesPerFrame     = 4;
	
    AudioStreamBasicDescription dstFormat;
	memset(&dstFormat, 0, sizeof(dstFormat));
	
	if(fileType == kAudioFileCAFType || fileType == kAudioFileWAVEType)
	{
		dstFormat.mSampleRate =       44100.0;
		dstFormat.mFormatID =         kAudioFormatLinearPCM;
		dstFormat.mFormatFlags =      kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
		dstFormat.mFramesPerPacket =  1;
		dstFormat.mChannelsPerFrame = 2;
		dstFormat.mBitsPerChannel =	  16;
		dstFormat.mBytesPerPacket =   4;
		dstFormat.mBytesPerFrame =    4;
		
		fileName = (fileType == kAudioFileCAFType ? @"record.caf" : @"record.wav");
	}
	else if(fileType == kAudioFileM4AType)
	{
		dstFormat.mChannelsPerFrame = 2;
		dstFormat.mFormatID = kAudioFormatMPEG4AAC;
		UInt32 size = sizeof(dstFormat);
		status = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &dstFormat);
		if(status != noErr)
		{
			NSLog(@"Error %ld in AudioFormatGetProperty()", status);
			return;
		}
		
		fileName = @"record.m4a";
	}
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    recordingFilePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:fileName] copy];
	NSURL *fileURL = [NSURL fileURLWithPath:recordingFilePath isDirectory:NO];
	
	ExtAudioFileRef audioFileRef;
	status = ExtAudioFileCreateWithURL((CFURLRef)fileURL, fileType, &dstFormat, NULL, kAudioFileFlags_EraseFile, &audioFileRef);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileCreateWithURL()", status);
		return;
	}
	
	status = ExtAudioFileSetProperty(audioFileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(stereoStreamFormat), &stereoStreamFormat);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileSetProperty()", status);
		return;
	}
	
	status =  ExtAudioFileWriteAsync(audioFileRef, 0, NULL);
	if(status != noErr)
	{
		NSLog(@"Error %ld in ExtAudioFileWriteAsync()", status);
		return;
	}
	
    checkDiskSizeTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(checkDiskSize:) userInfo:(id)kCFBooleanTrue repeats:YES];
	
	djMixer.recordingFile = audioFileRef;
	djMixer.fileRecording = YES;
	
    [self performSelector:@selector(doHighlight:) withObject:self.recordButton afterDelay:0];
    [self performSelector:@selector(doHighlight:) withObject:self.recordButtonLS afterDelay:0];
	
	NSLog(@"Recording started");
}


- (void) recordStop
{
	NSLog(@"Stopping recording...");
	
	[checkDiskSizeTimer invalidate];
	checkDiskSizeTimer = nil;
	
	djMixer.fileRecording = NO;
	
	ExtAudioFileRef audioFileRef = djMixer.recordingFile;
	djMixer.recordingFile = NULL;
	
	OSStatus status = ExtAudioFileDispose(audioFileRef);
	if(status != noErr)
	{
		NSLog(@"Error %d in ExtAudioFileDispose()", (int)status);
	}
	
	NSUInteger fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:recordingFilePath error:nil] fileSize];
	NSLog(@"File: %@", recordingFilePath);
	NSLog(@"File size: %u", fileSize);
	
	[recordingFilePath release];
	
    [self.recordButton setHighlighted:NO];
    [self.recordButtonLS setHighlighted:NO];
    
	NSLog(@"Recording stopped");
}


- (NSUInteger) checkDiskSize:(BOOL)showAlert
{
	NSDictionary *atDict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/" error:nil];
	NSUInteger freeSpace = [[atDict objectForKey:NSFileSystemFreeSize] unsignedIntValue] / (1024 * 1024);
	NSLog(@"Free Diskspace: %u MiB", freeSpace);
	
	if(freeSpace < 10 && showAlert)
	{
		if(djMixer.fileRecording)
		{
			[self recordStop];
		}
		
		NSString *msg = @"Is not possible to start recording with less than 10 Mib of free space.";
		alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
	}
	
	return freeSpace;
}


- (void) pause:(BOOL)flag
{
	[djMixer pause:flag];
	
	if(karaokeActivated)
	{
		if(flag)
		{
			[self karaokePause];
		}
		else
		{
			[self karaokeResume];
		}
	}
}


- (IBAction) doKaraoke:(UIButton*)sender
{
    if(karaokeActivated)
    {
        [self karaokeStop];
    }
    else
    {
        [self karaokeStart];
    }
}


- (void) karaokeStep
{
    if(self.karaoke.step == 0)
    {
        [karaokeText setAttributedText:self.karaoke.attribText];
        [karaokeText setContentOffset:CGPointMake(0, 1) animated:NO];

        [karaokeTextLS setAttributedText:self.karaoke.attribTextLS];
        [karaokeTextLS setContentOffset:CGPointMake(0, 1) animated:NO];
    }
    else
    {
        BOOL advanced = [self.karaoke advanceRedRow];
        if(advanced)
        {
            // Do for Portrait
            [karaokeText setAttributedText:self.karaoke.attribText];
                
            CGPoint position = [karaokeText contentOffset];                
            CGFloat LINE_HEIGHT = 20.2f;  // Line height is fixed for now (find a way for get it from used font).
            position.y += LINE_HEIGHT;

            [karaokeText setContentOffset:position animated:YES];
 
            // Do for Landscape
            [karaokeTextLS setAttributedText:self.karaoke.attribTextLS];
    
            position = [karaokeTextLS contentOffset];                
            CGFloat LINE_HEIGHT_LS = 31.0f;  // Line height is fixed for now (find a way for get it from used font).
            position.y += LINE_HEIGHT_LS;
                
            [karaokeTextLS setContentOffset:position animated:YES];
        }
        else
        {
            [self.karaokeButton setHighlighted:NO];
            [self.karaokeButtonLS setHighlighted:NO];
            
            [karaokeTimer invalidate];
            karaokeTimer = nil;
            
            return;
        }
    }
    
    if(++self.karaoke.step < self.karaoke.time.count)
    {
        NSTimeInterval newInterval = [[self.karaoke.time objectAtIndex:self.karaoke.step] doubleValue];
        NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:newInterval];
        [karaokeTimer setFireDate:fireDate];
    }
    else
    {
        [self.karaokeButton setHighlighted:NO];
        [self.karaokeButtonLS setHighlighted:NO];

        [karaokeTimer invalidate];
        karaokeTimer = nil;
    }
}


- (void) karaokeStart
{
    [self.karaoke resetRedRow];
    
    [karaokeText setAttributedText:nil];
    [karaokeTextLS setAttributedText:nil];
    
    NSTimeInterval interval = [[self.karaoke.time objectAtIndex:self.karaoke.step] doubleValue];
    karaokeTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(karaokeStep) userInfo:nil repeats:YES];
    
    [self performSelector:@selector(doHighlight:) withObject:self.karaokeButton afterDelay:0];
    [self performSelector:@selector(doHighlight:) withObject:self.karaokeButtonLS afterDelay:0];
    
    karaokeActivated = YES;
}


- (void) karaokeStop
{
    [self.karaokeButton setHighlighted:NO];
    [self.karaokeButtonLS setHighlighted:NO];
    
    [karaokeTimer invalidate];
    karaokeTimer = nil;
    
    karaokeActivated = NO;
}


- (void) karaokePause
{
    karaokePauseStart = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
    
    karaokePrevFireDate = [[karaokeTimer fireDate] retain];
    
    [karaokeTimer setFireDate:[NSDate distantFuture]];
}


- (void) karaokeResume
{
    double pauseTime = -[karaokePauseStart timeIntervalSinceNow];
    
    [karaokeTimer setFireDate:[karaokePrevFireDate initWithTimeInterval:pauseTime sinceDate:karaokePrevFireDate]];
    
    [karaokePauseStart release];
    
    [karaokePrevFireDate release];
}


- (void) applicationWillResignActive:(NSNotification *)notification
{
    NSLog(@"applicationWillResignActive");
	
	if([djMixer isPlaying])
    {
        [djMixer stopPlay];
	}
	
	if(djMixer.fileRecording)
	{
		[self recordStop];
	}
}


- (void) enableAudioInput
{
	if(!djMixer.missingAudioInput)
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		NSDictionary *channelDict = [defaults objectForKey:@"Channel-9"];
		
		double sliderValue = [[channelDict objectForKey:@"AudioVolume"] doubleValue];
		
		UISlider *slider = [channelSliders objectForKey:@"Channel-9"];
		[slider setEnabled:YES];
		[slider setValue:sliderValue];
		
		[djMixer changeCrossFaderAmount:sliderValue forChannel:9];
	}
}


- (void) disableAudioInput
{
	UISlider *slider = [channelSliders objectForKey:@"Channel-9"];
	
	[slider setEnabled:!djMixer.missingAudioInput];
	[slider setValue:0.0];
	
	[djMixer changeCrossFaderAmount:0.0 forChannel:9];
}


// Override to allow orientations other than the default portrait orientation.
// Called if iOS < 6
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight)
    {
        return YES;
    }
    else if(interfaceOrientation == UIDeviceOrientationPortrait)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}


// Override to allow orientations other than the default portrait orientation.
// Called if iOS >= 6
- (NSUInteger)supportedInterfaceOrientations
{
    return (UIInterfaceOrientationMaskPortrait + UIInterfaceOrientationMaskLandscape);
}


// Called if iOS >= 6
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


// Called if iOS >= 6
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    // NSLog(@"to %d", orientation);
    
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
    {
        self.view = self.landscapeView;
        self.isPortrait = NO;
    }
    else
    {
        self.view = self.portraitView;
        self.isPortrait = YES;
    }
}


// Called if iOS >= 6
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // NSLog(@"from %d to %d", fromInterfaceOrientation, self.interfaceOrientation);
}

@end
