//
//  DJMixerViewController.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//


#import <objc/runtime.h>
#import "MusicAppAppDelegate.h"
#import "DJMixer.h"
#import "DJMixerViewController.h"
#import "SettingsViewController.h"
#import "SelectionViewController.h"
#import "UITextScroll.h"
#import "Karaoke.h"
#import "LoadAudioOperation.h"
#import "SequencerOperation.h"


@interface UIButton (SequencerExtension)

- (void) setRecordingReference:(id)refObject;
- (id) recordingReference;

@end

@implementation UIButton (SequencerExtension)

static const char *kAssociationKey = "RecTime";

- (void) setRecordingReference:(id)refObject
{
	objc_setAssociatedObject(self, kAssociationKey, refObject, OBJC_ASSOCIATION_COPY);
}

- (id) recordingReference
{
	return objc_getAssociatedObject(self, kAssociationKey);
}

@end


#define PLAYPOSITION_LABEL_PRECISION @"%.1f"	// Show 10th of second
#define PLAYPOSITION_TIMER_FREQUENCY 0.01		// Check every 100th of second

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
@synthesize pauseButton;
@synthesize selectButton;
@synthesize karaokeButton;
@synthesize karaokeText;
@synthesize karaokeActivated;

@synthesize playButtonLS;
@synthesize pauseButtonLS;
@synthesize selectButtonLS;
@synthesize karaokeButtonLS;
@synthesize karaokeTextLS;
@synthesize positionLabelLS;
@synthesize durationLabelLS;
@synthesize positionSliderLS;
@synthesize sequencerSwitchLS;
@synthesize sequencerUndoLS;
@synthesize sequencerScrollViewLS;
@synthesize sequencerRecViewLS;
@synthesize recordingDeleteLS;
@synthesize recordingPlayLS;
@synthesize recordingShiftLS;
@synthesize recordingEnableLS;
@synthesize sequencerLabelLS;
@synthesize sequencerSliderLS;

@synthesize djMixer;
@synthesize karaoke;
@synthesize karaokeTimer;
@synthesize checkDiskSizeTimer;
@synthesize checkPositionTimer;
@synthesize updateRecViewTimer;
@synthesize isPortrait;
@synthesize sequencerButtons;


- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self != nil)
    {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
		userDocDirPath = [[paths objectAtIndex:0] copy];
	}
	
	self.sequencerButtons = [[[NSMutableArray alloc] init] autorelease];
    
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
	
	[userDocDirPath release];
	
	[sequencerButtons release];
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
						audioInputLabel, @"Playback",
						sequencerLabelLS, @"Sequencer", nil];
	
	channelSliders = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
						channel1Slider, @"Channel-1",
						channel2Slider, @"Channel-2",
						channel3Slider, @"Channel-3",
						channel4Slider, @"Channel-4",
						channel5Slider, @"Channel-5",
						channel6Slider, @"Channel-6",
						channel7Slider, @"Channel-7",
						channel8Slider, @"Channel-8",
						audioInputSlider, @"Playback",
						sequencerSliderLS, @"Sequencer", nil];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
 
    [self saveControlsValue];
    
    if(karaoke != nil)
    {
        if(karaokeTimer != nil)
        {
            [karaokeTimer invalidate];
            karaokeTimer = nil;
        }
        
        [self.karaokeButton setHighlighted:NO];
        [self.karaokeButtonLS setHighlighted:NO];

        [karaoke release];
        karaoke = nil;
    }
	
	[positionSliderLS removeTarget:self action:@selector(setPlayPositionEnded:) forControlEvents:UIControlEventTouchUpInside];
	
	// [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
	
	for(id control in sequencerButtons)
	{
		[control removeFromSuperview];
		[control release];
	}
	[sequencerButtons removeAllObjects];
	
	selectedRecording = nil;
	
	textOffset = [karaokeText contentOffset];
	textOffsetLS = [karaokeTextLS contentOffset];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	[karaokeText setContentOffset:textOffset];
	[karaokeTextLS setContentOffset:textOffsetLS];

    int totLoadedChannels = 0;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	djMixer.loop = [defaults boolForKey:@"PlayContinuousOn"];
	
	double maxDuration = 0.0;
	
	// Init all output channels
	for(NSInteger idx = 0; idx < kNumChannels; idx++)
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
				
				// ** IMPORTANT!! *****************************************
				// Verify if [[obj retain] autorelease] it works corrreclty
				// ********************************************************
				LoadAudioOperation *loadOperation = [[[[LoadAudioOperation alloc] initWithAudioFile:url] retain] autorelease];
				if(loadOperation != nil)
				{
					[djMixer.loadAudioQueue addOperation:loadOperation];
					
					[djMixer.channels[idx] setLoadOperation:loadOperation mixer:djMixer];
				}
				else
				{
					NSLog(@"Can't load audio file %@", [url lastPathComponent]);
				}
			}
		}

		UISlider *slider = [channelSliders objectForKey:channelStr];
		UILabel *label = [channelLabels objectForKey:channelStr];
		
		if(djMixer.channels[idx].loaded)
		{
			totLoadedChannels++;
			double sliderValue = [[channelDict objectForKey:@"AudioVolume"] doubleValue];
			
			[label setText:[NSString stringWithFormat:@"%@", [channelDict objectForKey:@"AudioTitle"]]];
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

	// Init the Sequencer channel
	[djMixer.sequencer freeStuff];

	[djMixer.sequencer removeLoadOperation]; // Remove the previous operation if present
		
	NSString *recordsPList = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
	SequencerOperation *sequencerOperation = [[SequencerOperation alloc] initWithRecords:recordsPList];
	assert(sequencerOperation != nil);
		
	[djMixer.loadAudioQueue addOperation:sequencerOperation];
	[djMixer.sequencer setSequencerOperation:sequencerOperation mixer:djMixer];

	NSLog(@"LoadQueue Operations: %d", [djMixer.loadAudioQueue operationCount]);

	// Find a better way to compute duration and durationPackets internally to DJMixer
	djMixer.duration = maxDuration;
	djMixer.durationPackets = maxDuration * kSamplingRate;
	
	[djMixer setStartPosition:0.0 reset:NO];
	
	durationLabelLS.text = [NSString stringWithFormat:PLAYPOSITION_LABEL_PRECISION, maxDuration];
	positionLabelLS.text = @"0";
	positionSliderLS.value = 0.0;

	if(!djMixer.missingAudioInput)
	{
		// Init the Playback channel 
		NSString *channelStr = @"Playback";
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
	
	// Init the Sequencer channel
	NSString *channelStr = @"Sequencer";
	NSDictionary *channelDict = [defaults objectForKey:channelStr];
	if(channelDict != nil)
	{
		double sliderValue = [[channelDict objectForKey:@"AudioVolume"] doubleValue];
		
		UISlider *slider = [channelSliders objectForKey:channelStr];
		[slider setEnabled:YES];
		[slider setValue:sliderValue];
		
		[djMixer changeCrossFaderAmount:sliderValue forChannel:0];
	}
/*
    [playButton setEnabled:(totLoadedChannels != 0)];
    [playButtonLS setEnabled:(totLoadedChannels != 0)];
*/
    [pauseButton setEnabled:NO];
    [pauseButtonLS setEnabled:NO];
   	
	// Seems better to use applicationDidEnterBackground in app delegate
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    [self.karaokeButton setEnabled: YES];
    [self.karaokeButtonLS setEnabled: YES];
    
	[positionSliderLS addTarget:self action:@selector(setPlayPositionEnded:) forControlEvents:UIControlEventTouchUpInside];
	
	[self updateSequencerButtons];
	
	[recordingDeleteLS setEnabled:NO];
	[recordingPlayLS setEnabled:NO];
	[recordingShiftLS setEnabled:NO];
	[recordingEnableLS setEnabled:NO];
   
	self.isPortrait = (self.interfaceOrientation == UIDeviceOrientationPortrait || self.interfaceOrientation == UIDeviceOrientationPortraitUpsideDown);
}


- (void) saveControlsValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for(int idx = 1; idx <= 10; idx++)
    {
		NSString *channelStr = idx != 10 ? [NSString stringWithFormat:@"Channel-%d", idx] : @"Playback";

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
            NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
            
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
    }
	else
	{
		NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
		
		[newDict setObject:[NSNumber numberWithDouble:[(UISlider*)[channelSliders objectForKey:channelStr] value]] forKey:@"AudioVolume"];

		[defaults setObject:newDict forKey:channelStr];
	}

	[defaults synchronize];
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
	int channel;
	NSString *channelStr = [[channelSliders allKeysForObject:sender] objectAtIndex:0];
	if([channelStr isEqualToString:@"Playback"])
	{
		channel = 9;
	}
	else if([channelStr isEqualToString:@"Sequencer"])
	{
		channel = 0;
	}
	else
	{
		NSScanner *scanner = [NSScanner scannerWithString:channelStr];
		[scanner scanUpToCharactersFromSet:numbers intoString:NULL];
		[scanner scanInt:&channel];
	}
	
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

       if([defaults boolForKey:@"RecordingAutoOff"] && djMixer.savingFile)
        {
            [self doRecord:nil];
        }
		
		[checkPositionTimer invalidate];
		checkPositionTimer = nil;

		[playButton setTitle:@"Play" forState:UIControlStateNormal];
        [playButtonLS setTitle:@"Play" forState:UIControlStateNormal];
        
        [selectButton setEnabled:YES];
        [selectButtonLS setEnabled:YES];
        
        [pauseButton setEnabled:NO];
        [pauseButtonLS setEnabled:NO];
        
        [pauseButton setHighlighted:NO];
        [pauseButtonLS setHighlighted:NO];
    }
    else
    {
		NSString *recordsFile = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
		[djMixer.sequencer.operation setRecords:recordsFile];

		checkPositionTimer = [NSTimer scheduledTimerWithTimeInterval:PLAYPOSITION_TIMER_FREQUENCY target:self selector:@selector(updatePlayPosition) userInfo:(id)kCFBooleanTrue repeats:YES];

        [djMixer startPlay];
        
		if([defaults boolForKey:@"RecordingAutoOn"] && !djMixer.savingFile)
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
        
        [pauseButton setEnabled:YES];
        [pauseButtonLS setEnabled:YES];
    }
}


- (IBAction) goSettings:(UIButton*)sender
{
    if(!self.isPortrait)
    {
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Error!"  message:@"The Settings can be accessed only with the Screen in Portrait orientation"
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


- (IBAction) doPause:(UIButton*)sender
{
	if([djMixer paused])
	{
		[djMixer pause:NO];

		[pauseButton setHighlighted:NO];
		[pauseButtonLS setHighlighted:NO];
	}
	else
	{
		[djMixer pause:YES];
		
		[self performSelector:@selector(doHighlight:) withObject:pauseButton afterDelay:0];
		[self performSelector:@selector(doHighlight:) withObject:pauseButtonLS afterDelay:0];
	}
}


- (void)doHighlight:(UIButton*)btn
{
    [btn setHighlighted:YES];
}


- (IBAction) doRecord:(UIButton*)sender
{
	if(djMixer.savingFile)
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
		wasPlaying = YES;
		
		[djMixer stopPlay];
		
		if(djMixer.savingFile)
		{
			[self recordStop];
		}
		
		if(karaokeActivated)
		{		
			[karaokeTimer setFireDate:[NSDate distantFuture]];
		}
		
		[checkPositionTimer setFireDate:[NSDate distantFuture]];

		// ADD A TIMER to check Slider value. If it remains the same for a little then play audio from there...

		// NSLog(@"Set current play position to %.1f", playPosition);
	}
	else
	{
		// NSLog(@"Set start position to %.1f", playPosition);
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
			positionLabelLS.text = [NSString stringWithFormat:PLAYPOSITION_LABEL_PRECISION, (floor(djMixer.playPosition * 10) / 10)];
		}
		else	// Set the slider back to beginning
		{
			djMixer.playPosition = 0.0;
			
			[positionSliderLS setValue:0.0 animated:NO];
			positionLabelLS.text = [NSString stringWithFormat:PLAYPOSITION_LABEL_PRECISION, (floor(djMixer.playPosition * 10) / 10)];
		}
	}
	else
	{
		UInt32 totalPackets = [djMixer getTotalPackets];
		djMixer.playPosition = (double)totalPackets / kSamplingRate;
		double sliderPosition = 1.0 / (djMixer.duration / djMixer.playPosition);
		
		if(fabs(positionSliderLS.value - sliderPosition) > 0.0001) // Don't go inside here if nothing gonna displayed different...
		{
			[positionSliderLS setValue:sliderPosition animated:NO];
			positionLabelLS.text = [NSString stringWithFormat:PLAYPOSITION_LABEL_PRECISION, (floor(djMixer.playPosition * 10) / 10)];
		}
	}
}


- (void) setPlayPositionEnded:(UISlider*)sender
{
	double playPosition = djMixer.duration * sender.value;
	
	NSLog(@"Set play position to %.1f", playPosition);
	
	[djMixer setStartPosition:playPosition reset:YES];

	if(wasPlaying)
	{
		wasPlaying = NO;
		
		[djMixer startPlay];

		[checkPositionTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:PLAYPOSITION_TIMER_FREQUENCY]];
	}
	
	[self karaokeSetPosition:playPosition];
}


- (void) updateRecView
{
	double percent = (double)djMixer.durationPackets / (double)djMixer.savingFilePackets;
	CGFloat totalWidth = positionSliderLS.bounds.size.width - 20.0;
	CGFloat barWidth = (totalWidth / percent);
	CGRect frame = sequencerRecViewLS.frame;
	frame.size.width = ceil(barWidth);
	[sequencerRecViewLS setFrame:frame];
}


- (IBAction) doPauseSequencer:(UISwitch*)sender
{
    [djMixer.sequencer pause:!sender.on];
}


- (IBAction) doUndoSequencer:(UIButton*)sender
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
			^{
				NSString *filePath = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];

				NSArray *records = [NSArray arrayWithContentsOfFile:filePath];
				if(records == nil || records.count == 0)
				{
				   return;
				}

				NSMutableArray *sortedRecords = [NSMutableArray arrayWithArray:[records sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
																			   {
																				   return [[obj1 objectForKey:@"recTime"] compare:[obj2 objectForKey:@"recTime"]];
																			   }]];
				NSDictionary *lastRecord = [sortedRecords lastObject];
				NSString *fileName = [lastRecord objectForKey:@"fileName"];					   
				[[NSFileManager defaultManager] removeItemAtPath:[userDocDirPath stringByAppendingPathComponent:fileName] error:nil];

				[sortedRecords removeLastObject];

				if([sortedRecords writeToFile:filePath atomically:YES])
				{
				   NSLog(@"%@ saved", [filePath lastPathComponent]);
				}
				else
				{
				   NSLog(@"Error saving %@", [filePath lastPathComponent]);
				   return;
				}

				BOOL wasActive = NO;
				if([djMixer.sequencer.operation isActive])
				{
				   wasActive = YES;
				   [djMixer.sequencer.operation deactivate];
				}

				[djMixer.sequencer.operation setRecords:filePath];

				[djMixer.sequencer.operation reset];

				if(wasActive && sortedRecords.count > 0)
				{
				   [djMixer.sequencer.operation activate];
				}

				dispatch_sync(dispatch_get_main_queue(),
					^{
						[self updateSequencerButtons];
						[sequencerUndoLS setNeedsDisplay];
					});
		   });
}


- (void) updateSequencerButtons
{
	NSDictionary *selectedRecord = [selectedRecording recordingReference];

	selectedRecording = nil;

	for(id control in sequencerButtons)
	{
		[control removeFromSuperview];
		[control release];
	}
	[sequencerButtons removeAllObjects];

	CGFloat startPos = 0.0;
	CGFloat width = sequencerScrollViewLS.bounds.size.width;
	double durationPackets = djMixer.durationPackets;

	NSString *filePath = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
	NSMutableArray *records = [NSMutableArray arrayWithContentsOfFile:filePath];
	if(records != nil)
	{
		int totRecords = records.count;
		
		NSMutableArray *rows = [NSMutableArray array];
		for(int idx = 0; idx < totRecords; idx++)
		{
			NSMutableArray *row = [NSMutableArray array];
			[rows addObject:row];
		}
		
		for(NSDictionary *record in records)
		{
			NSUInteger startPacket = [[record objectForKey:@"startPacket"] integerValue];
			NSUInteger endPacket = [[record objectForKey:@"endPacket"] integerValue];
			BOOL enabled = [[record objectForKey:@"enabled"] boolValue];

			double percent = (durationPackets / startPacket);
			CGFloat btnX = startPos + (width / percent);
			
			percent = durationPackets / (endPacket - startPacket);
			CGFloat btnWidth = (width / percent);
			
			UIButton *button = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
			[button addTarget:self action:@selector(selectRecording:) forControlEvents:UIControlEventTouchDown];
			button.frame = CGRectMake(btnX, 0, btnWidth, 16);
			button.backgroundColor = enabled ? [UIColor greenColor] : [UIColor redColor];
			button.alpha = 0.4;
			button.opaque = NO;
			// button.showsTouchWhenHighlighted = YES;

			NSMutableArray *row = [rows objectAtIndex:0];
			for(int idx = row.count - 1; idx >= 0; idx--)
			{
				UIButton *btn = row[idx];
				if(CGRectIntersectsRect(btn.frame, button.frame))
				{
					[self moveButtonToNextRow:btn fromRow:row rows:rows];
				}
			}
			
			[row addObject:button];
			
			[button setRecordingReference:record];
		}
		
		int filledRows = 0;
		for(int idx = 0; idx < rows.count; idx++)
		{
			if([rows[idx] count] != 0)
			{
				filledRows++;
			}
		}
		
		CGFloat yOffset = 18.0 * (filledRows - 1);
		for(int idx = 0; idx < rows.count; idx++)
		{
			NSArray *row = rows[idx];
			if(row.count != 0)
			{
				for(UIButton *btn in row)
				{
					CGRect frame = btn.frame;
					frame.origin.y += yOffset;
					[btn setFrame:frame];
					
					[sequencerScrollViewLS addSubview:btn];
					[sequencerButtons addObject:btn];
				}
				
				yOffset -= 18.0;
			}
		}
		
		CGFloat scrollHeight = filledRows * 18.0;
		sequencerScrollViewLS.contentSize = CGSizeMake(0, scrollHeight);
		sequencerScrollViewLS.contentOffset = CGPointMake(0, scrollHeight - 54.0);
		sequencerScrollViewLS.scrollEnabled = (scrollHeight > 54.0);

		[sequencerUndoLS setEnabled:(totRecords != 0)];
		
		if(selectedRecord != nil)
		{
			UIButton *recButton = [self findRecordingButton:selectedRecord];
			[self selectRecording:recButton];
		}
	}
	else
	{
		[sequencerUndoLS setEnabled:NO];
	}
}


- (UIButton*) findRecordingButton:(NSDictionary*)record
{
	if(record == nil)
	{
		return nil;
	}
	
	id recTime = [record objectForKey:@"recTime"];
	for(UIButton *btn in sequencerButtons)
	{
		if([[[btn recordingReference] objectForKey:@"recTime"] isEqual:recTime])
		{
			return btn;
		}
	}
	
	return nil;
}


- (void) moveButtonToNextRow:(UIButton*)button fromRow:(NSMutableArray*)row rows:(NSArray*)rows
{
	int nextRowIdx = [rows indexOfObject:row] + 1;
	NSMutableArray *nextRow = [rows objectAtIndex:nextRowIdx];
	
	for(UIButton *btn in nextRow)
	{
		if(CGRectIntersectsRect(btn.frame, button.frame))
		{
			[self moveButtonToNextRow:btn fromRow:nextRow rows:rows];
		}
	}
	
	[row removeObject:button];
	[nextRow addObject:button];
}


- (void) scrollViewDidScroll:(UIScrollView*)scrollView
{
	// NSLog(@"scrollViewDidScroll");
}


- (void) selectRecording:(id)sender
{
	if(selectedRecording != nil && selectedRecording != sender)
	{
		[selectedRecording setSelected:NO];
		selectedRecording.alpha = 0.4;
	}
	
	selectedRecording = sender;
	if(selectedRecording == nil)
	{
		return;
	}
	
	if(selectedRecording.selected)
	{
		[selectedRecording setSelected:NO];
		selectedRecording.alpha = 0.4;

		[recordingDeleteLS setEnabled:NO];
		[recordingPlayLS setEnabled:NO];
		[recordingShiftLS setEnabled:NO];
		[recordingEnableLS setEnabled:NO];
		
		selectedRecording = nil;
	}
	else
	{
		[selectedRecording setSelected:YES];
		selectedRecording.alpha = 0.9;
		
		NSLog(@"%@", [selectedRecording recordingReference]);
		
		[recordingDeleteLS setEnabled:YES];
		[recordingPlayLS setEnabled:YES];
		[recordingShiftLS setEnabled:YES];
		[recordingEnableLS setEnabled:YES];		

		
		BOOL enabled = [[[selectedRecording recordingReference] objectForKey:@"enabled"] boolValue];
		[recordingEnableLS setTitle:enabled ? @"Disable" : @"Enable" forState:UIControlStateNormal];
	}
}


- (IBAction) doSelectLastRecording:(UIButton*)sender
{
	NSString *filePath = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
	
	NSArray *records = [NSArray arrayWithContentsOfFile:filePath];
	if(records == nil || records.count == 0)
	{
		return;
	}
	
	NSMutableArray *sortedRecords = [NSMutableArray arrayWithArray:[records sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
																	{
																		return [[obj1 objectForKey:@"recTime"] compare:[obj2 objectForKey:@"recTime"]];
																	}]];
	NSDictionary *lastRecord = [sortedRecords lastObject];
	if(lastRecord != nil)
	{
		id recTime = [lastRecord objectForKey:@"recTime"];
		for(UIButton *btn in sequencerButtons)
		{
			if([[[btn recordingReference] objectForKey:@"recTime"] isEqual:recTime])
			{
				if(selectedRecording != btn)
				{
					[self selectRecording:btn];
				}
				
				break;
			}
		}
	}
}


- (IBAction) doDeleteRecording:(UIButton*)sender
{
	NSUInteger foundIdx = [self getRecordingIndex:selectedRecording];
	if(foundIdx != NSNotFound)
	{
		NSString *filePath = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
		NSMutableArray *records = [NSMutableArray arrayWithContentsOfFile:filePath];
		if(records.count == 0)
		{
			return;
		}
		
		NSDictionary *record = [records objectAtIndex:foundIdx];
		
		NSString *fileName = [record objectForKey:@"fileName"];
		NSString *recordingPath = [userDocDirPath stringByAppendingPathComponent:fileName];		

		NSFileManager *fileMgr = [NSFileManager defaultManager];
		NSError *error = nil;
		if(![fileMgr removeItemAtPath:recordingPath error:&error])
		{
			NSLog(@"Error %@ removing audio file %@", [error description], recordingPath);
		}

		[records removeObjectAtIndex:foundIdx];
		
		if([records writeToFile:filePath atomically:YES])
		{
			NSLog(@"%@ saved", [filePath lastPathComponent]);
		}
		else
		{
			NSLog(@"Error saving %@", [filePath lastPathComponent]);
		}

		[selectedRecording setSelected:NO];
		selectedRecording.alpha = 0.4;
		selectedRecording = nil;

		[recordingDeleteLS setEnabled:NO];
		[recordingPlayLS setEnabled:NO];
		[recordingShiftLS setEnabled:NO];
		[recordingEnableLS setEnabled:NO];
		
		[self updateSequencerButtons];
	}
}


- (IBAction) doPlayRecording:(UIButton*)sender
{
	if(audioPlayer != nil)
	{
		[audioPlayer stop];
		
		[self audioPlayerDidFinishPlaying:audioPlayer successfully:YES];

		return;
	}
	
	if(selectedRecording == nil)
	{
		return;
	}
	
	NSDictionary *record = [selectedRecording recordingReference];	
	NSString *fileName = [record objectForKey:@"fileName"];
	NSURL *fileURL = [NSURL fileURLWithPath:[userDocDirPath stringByAppendingPathComponent:fileName] isDirectory:NO];
	if(fileURL == nil)
	{
		return;
	}
	
	NSError *error = nil;
	audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
	if(audioPlayer == nil)
	{
		NSLog(@"Error %@ in AVAudioPlayer initialization", [error description]);
		
		NSString *msg = [NSString stringWithFormat:@"The audio file %@ can't be played.\rError %@", fileName, [error description]];
		alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
		
		return;
	}
	
	[audioPlayer setDelegate:self];
	
	if(![audioPlayer prepareToPlay] || [audioPlayer duration] == 0.0)
	{
		NSString *msg = [NSString stringWithFormat:@"The audio file %@ is empty or unplayable", fileName ];
		alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
		
		[audioPlayer release];
		audioPlayer = nil;

		return;
	}
	
	if([audioPlayer play])
	{
		NSLog(@"Playing %@...", fileName);

		[recordingPlayLS setTitle:@"Stop" forState:UIControlStateNormal];
	}
	else
	{
		[audioPlayer release];
		audioPlayer = nil;
		
		NSString *msg = [NSString stringWithFormat:@"The audio file %@ can't be played", fileName ];
		alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
	}
}


- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
	NSLog(@"Playing completed");

	[audioPlayer release];
	audioPlayer = nil;
	
	[recordingPlayLS setTitle:@"Play" forState:UIControlStateNormal];
}


- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError*)error
{
	NSLog(@"Error %@ playing", [error description]);
	
	[audioPlayer release];
	audioPlayer = nil;
	
	[recordingPlayLS setTitle:@"Play" forState:UIControlStateNormal];
}


- (IBAction) doShiftRecording:(UIButton*)sender
{
	NSUInteger foundIdx = [self getRecordingIndex:selectedRecording];
	if(foundIdx != NSNotFound)
	{
		NSString *filePath = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
		NSArray *records = [NSArray arrayWithContentsOfFile:filePath];
		if(records.count == 0)
		{
			return;
		}

		NSMutableDictionary *record = [records objectAtIndex:foundIdx];
		
		NSNumber *posTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
		[record setObject:posTime forKey:@"posTime"];

		NSArray *sortedRecords = [records sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
								  {
									  int result = [[obj1 objectForKey:@"posTime"] compare:[obj2 objectForKey:@"posTime"]];
									  
									  return result;
								  }];

		if([sortedRecords writeToFile:filePath atomically:YES])
		{
			NSLog(@"%@ saved", [filePath lastPathComponent]);
		}
		else
		{
			NSLog(@"Error saving %@", [filePath lastPathComponent]);
		}
				
		[self updateSequencerButtons];
	}
}


- (IBAction) doEnableRecording:(UIButton*)sender
{
	NSUInteger foundIdx = [self getRecordingIndex:selectedRecording];
	if(foundIdx != NSNotFound)
	{
		NSString *filePath = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
		NSMutableArray *records = [NSMutableArray arrayWithContentsOfFile:filePath];
		if(records.count == 0)
		{
			return;
		}
		
		NSMutableDictionary *record = [records objectAtIndex:foundIdx];

		BOOL enabled = [[record objectForKey:@"enabled"] boolValue];
		[record setObject:[NSNumber numberWithBool:!enabled] forKey:@"enabled"];
		
		if([records writeToFile:filePath atomically:YES])
		{
			NSLog(@"%@ saved", [filePath lastPathComponent]);
		}
		else
		{
			NSLog(@"Error saving %@", [filePath lastPathComponent]);
		}
				
		[self updateSequencerButtons];
	}
}


- (NSUInteger) getRecordingIndex:(UIButton*)recordingBtn
{
	if(recordingBtn == nil)
	{
		return NSNotFound;
	}
	
	NSString *filePath = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
	NSArray *records = [NSArray arrayWithContentsOfFile:filePath];
	if(records.count == 0)
	{
		return NSNotFound;
	}
	
	NSDictionary *record = [recordingBtn recordingReference];
	if(record == nil)
	{
		return NSNotFound;
	}
	
	NSPredicate *filter = [NSPredicate predicateWithFormat:@"(recTime == %@)", [record objectForKey:@"recTime"]];
	NSUInteger index = [records indexOfObjectPassingTest:
						   ^(id obj, NSUInteger idx, BOOL *stop)
						   {
							   return [filter evaluateWithObject:obj];
						   }];
	return index;
}


- (void) recordStart
{
	AudioFileTypeID fileType = kAudioFileCAFType;
	OSStatus status = noErr;
	NSString *fileName = nil;
	
	if([self checkDiskSize:NO] < 10)
	{
		NSString *msg = @"Is not possible to start recording with less than 10 Mib of free space";
		alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
		return;
	}
	
	NSLog(@"Starting recording...");
	
	AudioStreamBasicDescription stereoStreamFormat;
	memset(&stereoStreamFormat, 0, sizeof(stereoStreamFormat));
    stereoStreamFormat.mSampleRate        = kSamplingRate;
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
		dstFormat.mSampleRate =       kSamplingRate;
		dstFormat.mFormatID =         kAudioFormatLinearPCM;
		dstFormat.mFormatFlags =      kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
		dstFormat.mFramesPerPacket =  1;
		dstFormat.mChannelsPerFrame = 2;
		dstFormat.mBitsPerChannel =	  16;
		dstFormat.mBytesPerPacket =   4;
		dstFormat.mBytesPerFrame =    4;
		
		fileName = (fileType == kAudioFileCAFType ? @"recording.caf" : @"recording.wav");
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
		
		fileName = @"recording.m4a";
	}
	
    NSString *filePath = [userDocDirPath stringByAppendingPathComponent:fileName];
	NSURL *fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
	
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
	
	djMixer.savingFileRef = audioFileRef;
	djMixer.savingFileUrl = fileURL;
	djMixer.savingFileStartPacket = -1;
	djMixer.savingFilePackets = 0;
	djMixer.savingFile = YES;
	
    [self performSelector:@selector(doHighlight:) withObject:self.recordButton afterDelay:0];
    [self performSelector:@selector(doHighlight:) withObject:self.recordButtonLS afterDelay:0];
	
	double percent = (double)djMixer.durationPackets / (double)djMixer->durationPacketsIndex;
	CGFloat startPos = positionSliderLS.frame.origin.x + 10.0;
	CGFloat totalWidth = positionSliderLS.bounds.size.width - 20.0;
	CGFloat xPos = startPos + (totalWidth / percent);
	CGRect frame = sequencerRecViewLS.frame;
	frame.origin.x = xPos;
	frame.size.width = 0;
	[sequencerRecViewLS setFrame:frame];
	sequencerRecViewLS.hidden = NO;
	
	[sequencerUndoLS setEnabled:NO];
	
	updateRecViewTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateRecView) userInfo:nil repeats:YES];
	
	NSLog(@"Recording started");
}


- (void) recordStop
{
	NSLog(@"Stopping recording...");
	
	[updateRecViewTimer invalidate];
	sequencerRecViewLS.hidden = YES;
		
	djMixer.savingFile = NO;
	
	// [NSThread sleepForTimeInterval:0.2];
	
	[self.recordButton setHighlighted:NO];
	[self.recordButtonLS setHighlighted:NO];
	
	[sequencerUndoLS setEnabled:YES];

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),
	^{	
		OSStatus status = ExtAudioFileDispose(djMixer.savingFileRef);
		if(status != noErr)
		{
			NSLog(@"Error %d in ExtAudioFileDispose()", (int)status);
		}
		
		djMixer.savingFileRef = NULL;

		NSFileManager *fileMgr = [NSFileManager defaultManager];
		NSString *filePath = [djMixer.savingFileUrl path];
		
		NSInteger startPacket = djMixer.savingFileStartPacket;
		NSInteger endPacket = startPacket + djMixer.savingFilePackets;
		double duration = (double)(endPacket - startPacket) / kSamplingRate;
				
		NSString *fileName = [filePath lastPathComponent];
		NSString *fileExt = [fileName pathExtension];
		NSString *newFileName = [NSString stringWithFormat:@"record-%d-%d.%@", startPacket, endPacket, fileExt];
		NSString *newFilePath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
		[fileMgr moveItemAtPath:filePath toPath:newFilePath error:nil];

		NSUInteger fileSize = [[fileMgr attributesOfItemAtPath:newFilePath error:nil] fileSize];
		NSLog(@"File: %@", newFilePath);
		NSLog(@"File size: %u", fileSize);
				
		[checkDiskSizeTimer invalidate];
		checkDiskSizeTimer = nil;

		NSLog(@"Recording stopped");
		
		filePath = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
		NSMutableArray *records = [NSMutableArray arrayWithContentsOfFile:filePath];
		if(records == nil)
		{
			records = [NSMutableArray array];
		}
		
		NSNumber *recTime = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
		NSDictionary *lastRec = [NSDictionary dictionaryWithObjectsAndKeys:newFileName, @"fileName", [NSNumber numberWithInteger:startPacket], @"startPacket", [NSNumber numberWithInteger:endPacket], @"endPacket", recTime, @"recTime", recTime, @"posTime", [NSNumber numberWithDouble:duration], @"duration", [NSNumber numberWithBool:YES], @"enabled", nil];
		[records addObject:lastRec];
		
		NSArray *sortedRecords = [records sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
											{
												int result = [[obj1 objectForKey:@"posTime"] compare:[obj2 objectForKey:@"posTime"]];
												return result;
											}];
		
		if([sortedRecords writeToFile:filePath atomically:YES])
		{
			NSLog(@"%@ saved", [filePath lastPathComponent]);
		}
		else
		{
			NSLog(@"Error saving %@", [filePath lastPathComponent]);
		}
		
		BOOL wasActive = NO;
		if([djMixer.sequencer.operation isActive])
		{
			wasActive = YES;
			[djMixer.sequencer.operation deactivate];
		}
		 
		NSString *recordsPList = [userDocDirPath stringByAppendingPathComponent:@"Records.plist"];
		[djMixer.sequencer.operation setRecords:recordsPList];
		
		NSUInteger packetPosition = djMixer.playPosition * kSamplingRate;
		[djMixer.sequencer.operation reset:packetPosition];

		if(wasActive && sortedRecords.count > 0)
		{
			[djMixer.sequencer.operation activate];
		}

		dispatch_sync(dispatch_get_main_queue(),
					   ^{
							[self updateSequencerButtons];
							[sequencerUndoLS setNeedsDisplay];
					   });
	});
}


- (NSUInteger) checkDiskSize:(BOOL)showAlert
{
	NSDictionary *atDict = [[NSFileManager defaultManager] attributesOfFileSystemForPath:@"/" error:nil];
	NSUInteger freeSpace = [[atDict objectForKey:NSFileSystemFreeSize] unsignedIntValue] / (1024 * 1024);
	NSLog(@"Free Diskspace: %u MiB", freeSpace);
	
	if(freeSpace < 10 && showAlert)
	{
		if(djMixer.savingFile)
		{
			[self recordStop];
		}
		
		NSString *msg = @"Is not possible to start recording with less than 10 Mib of free space";
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
       [self karaokeStart:djMixer.playPosition];
    }
}


- (void) karaokeStep
{
	BOOL rowAdvanced = [karaoke advanceRedRow];
	if(rowAdvanced)
	{
		// Do for Portrait
		[karaokeText setAttributedText:karaoke.attribText];
			
		CGPoint position = [karaokeText contentOffset];                
		position.y += (karaoke.font.lineHeight * karaoke.advancedRows);

		[karaokeText setContentOffset:position animated:YES];

		// Do for Landscape
		[karaokeTextLS setAttributedText:karaoke.attribTextLS];

		position = [karaokeTextLS contentOffset];                
		position.y += (karaoke.fontLS.lineHeight * karaoke.advancedRowsLS);
			
		[karaokeTextLS setContentOffset:position animated:YES];
	}
     
    if(karaoke.step < karaoke.time.count)
    {
        NSTimeInterval newInterval = [[karaoke.time objectAtIndex:karaoke.step] doubleValue];
        [karaokeTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:newInterval]];
    }
    else
    {
        [karaokeTimer setFireDate:[NSDate distantFuture]];
    }
}


- (void) karaokeStart:(NSTimeInterval)startPosition
{
	NSLog(@"karaokeStart: %g", startPosition);

	[karaokeText setAttributedText:nil];
    [karaokeTextLS setAttributedText:nil];
    
    NSString *karaokePList = [userDocDirPath stringByAppendingPathComponent:@"KaraokeData.plist"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:karaokePList])
    {
        NSLog(@"Karaoke file %@ is missing", karaokePList);
		return;
    }

	NSLog(@"Karaoke file %@ is available", karaokePList);
	
	if(karaoke != nil)
	{
		[karaoke release];
		karaoke = nil;
	}
	
	NSArray *data = [NSArray arrayWithContentsOfFile:karaokePList];
	
	karaoke = [[Karaoke alloc] initKaraoke:data portraitSize:karaokeText.contentSize landscapeSize:karaokeTextLS.contentSize];

    [karaoke resetRedRow];
    
	// Do for Portrait
	[karaokeText setAttributedText:karaoke.attribText];
	CGPoint position = [karaokeText contentOffset];
	[karaokeText setContentOffset:position animated:YES];

	// Do for Landscape
	[karaokeTextLS setAttributedText:karaoke.attribTextLS];
	position = [karaokeTextLS contentOffset];
	[karaokeTextLS setContentOffset:position animated:YES];

	NSInteger step = 0;
	NSTimeInterval interval = 0.0;
	for(NSNumber *time in karaoke.time)
	{
		interval += [time doubleValue];

		if(interval >= startPosition)
		{
			interval -= startPosition;
			break;
		}
		
		step++;
	}
	
	[self setKaraokeStep:step];
	
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


- (void) setKaraokeStep:(NSInteger)step
{
	NSLog(@"setKaraokeStep: %d", step);

	if(step >= karaoke.step)
	{
		NSInteger stepsForward = step - karaoke.step;
		
		for(int idx = karaoke.step; idx < step; idx++)
		{
			if(![karaoke advanceRedRow])
			{
				break;
			}
		}

		// Do for Portrait
		CGPoint position = [karaokeText contentOffset];		
		for(int idx = 0; idx < stepsForward; idx++)
		{
			position.y += (karaoke.font.lineHeight * karaoke.advancedRows);
		}

		[karaokeText setAttributedText:karaoke.attribText];
		[karaokeText setContentOffset:position animated:NO];

		// Do for Landscape
		position = [karaokeTextLS contentOffset];
		for(int idx = 0; idx < stepsForward; idx++)
		{
			position.y += (karaoke.fontLS.lineHeight * karaoke.advancedRowsLS);
		}
		
		[karaokeTextLS setAttributedText:karaoke.attribTextLS];
		[karaokeTextLS setContentOffset:position animated:NO];
	}
	else
	{
		NSInteger stepsBack = karaoke.step - step;
		
		[karaoke resetRedRow];
		
		for(int idx = 0; idx < step; idx++)
		{
			if(![karaoke advanceRedRow])
			{
				break;
			}
		}
		
		// Do for Portrait
		CGPoint position = [karaokeText contentOffset];
		for(int idx = 0; idx < stepsBack; idx++)
		{
			position.y -= (karaoke.font.lineHeight * karaoke.advancedRows);

		}
		
		[karaokeText setAttributedText:karaoke.attribText];
		[karaokeText setContentOffset:position animated:NO];
		
		// Do for Landscape
		position = [karaokeTextLS contentOffset];
		for(int idx = 0; idx < stepsBack; idx++)
		{
			position.y -= (karaoke.fontLS.lineHeight * karaoke.advancedRowsLS);
		}
		
		[karaokeTextLS setAttributedText:karaoke.attribTextLS];
		[karaokeTextLS setContentOffset:position animated:NO];
	}
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


- (void) karaokeSetPosition:(NSTimeInterval)position
{
    NSLog(@"karaokeSetPosition: %g", position);
	
	if(karaokeActivated)
	{
		[karaokeTimer setFireDate:[NSDate distantFuture]];
	}
	
	NSInteger step = 0;
	NSTimeInterval interval = 0.0;
	for(NSNumber *time in karaoke.time)
	{
		interval += [time doubleValue];
		
		if(interval >= position)
		{
			interval -= position;
			break;
		}
		
		step++;
	}
	
	[self setKaraokeStep:step];
	
	if(karaokeActivated)
	{
		[karaokeTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]];
	}
}


- (void) applicationWillResignActive:(NSNotification *)notification
{
    NSLog(@"applicationWillResignActive");
	
	if([djMixer isPlaying])
    {
        [djMixer stopPlay];
	}
	
	if(djMixer.savingFile)
	{
		[self recordStop];
	}
}


- (void) enableAudioInput
{
	if(!djMixer.missingAudioInput)
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		NSDictionary *channelDict = [defaults objectForKey:@"Playback"];
		
		double sliderValue = [[channelDict objectForKey:@"AudioVolume"] doubleValue];
		
		UISlider *slider = [channelSliders objectForKey:@"Playback"];
		[slider setEnabled:YES];
		[slider setValue:sliderValue];
		
		[djMixer changeCrossFaderAmount:sliderValue forChannel:9];
	}
}


- (void) disableAudioInput
{
	UISlider *slider = [channelSliders objectForKey:@"Playback"];
	
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
		
		[self updateSequencerButtons];
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
