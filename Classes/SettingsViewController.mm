//
//  SettingsViewController.h
//  MusicApp
//
//  Created by Luca Severini on 14/1/2012.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"
#import "SelectionViewController.h"
#import "KaraokeViewController.h"


@interface MySwitch : UISwitch

- (id)initWithCoder:(NSCoder *)aDecoder;

-(void) setFrame:(CGRect)frame;

@end

@implementation MySwitch

- (id)initWithCoder:(NSCoder *)aDecoder
{	
	if(self = [super initWithCoder:aDecoder])
	{
	}
	
	return self;
}

-(void) setFrame:(CGRect)frame;
{
	[super setFrame:frame];
}

@end


@implementation SettingsViewController

@synthesize backButton;
@synthesize goKaraokeButton;
@synthesize goSelectionButton;
@synthesize versionLabel;
@synthesize simulatorLabel;
@synthesize playRecordedAudioButton;
@synthesize deleteRecordedAudioButton;
@synthesize autoStartKaraokeSwitch;
@synthesize autoStartRecordingSwitch;
@synthesize autoStopRecordingSwitch;
@synthesize playContinuousSwitch;
@synthesize autoSetAudioInputSwitch;

- (void) viewDidLoad
{        
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDict objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];    
    versionLabel.text = [NSString stringWithFormat:@"%@ %@", appName, appVersion];
}


- (void) viewWillDisappear:(BOOL)animated
{
	if(audioPlayers != nil)
	{
		for(AVAudioPlayer *player in audioPlayers)
		{
			if([player isPlaying])
			{
				[player stop];
			}
			
			[player release];
		}
		
		[playRecordedAudioButton setTitle:@"Play Audio" forState:UIControlStateNormal];
		[deleteRecordedAudioButton setEnabled:YES];
		[backButton setEnabled:YES];
	}

    [super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
	[playRecordedAudioButton setTitle:@"Play Audio" forState:UIControlStateNormal];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [autoStartKaraokeSwitch setOn:[defaults boolForKey:@"KaraokeAutoOn"]];
    [autoStartRecordingSwitch setOn:[defaults boolForKey:@"RecordingAutoOn"]];
    [autoStopRecordingSwitch setOn:[defaults boolForKey:@"RecordingAutoOff"]];
	[playContinuousSwitch setOn:[defaults boolForKey:@"PlayContinuousOn"]];
	[autoSetAudioInputSwitch setOn:[defaults boolForKey:@"autoSetAudioInputOn"]];
}


- (void) didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void) dealloc 
{
    [super dealloc];
}


- (IBAction) doAutoStartKaraoke:(UISwitch*)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[autoStartKaraokeSwitch isOn] forKey:@"KaraokeAutoOn"];
	[defaults synchronize];
}


- (IBAction) doAutoStartRecording:(UISwitch*)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[autoStartRecordingSwitch isOn] forKey:@"RecordingAutoOn"];
	[defaults synchronize];
}


- (IBAction) doAutoStopRecording:(UISwitch*)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[autoStopRecordingSwitch isOn] forKey:@"RecordingAutoOff"];
	[defaults synchronize];
}


- (IBAction) doPlayContinuous:(UISwitch*)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[playContinuousSwitch isOn] forKey:@"PlayContinuousOn"];
	[defaults synchronize];
}


- (IBAction) doAutoSetAudioInput:(UISwitch*)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:[autoSetAudioInputSwitch isOn] forKey:@"autoSetAudioInputOn"];
	[defaults synchronize];
}


- (IBAction) goBack:(UIButton*)sender
{
    // Custom animated transition
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration: 0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view.window cache:YES];
    
    [self dismissViewControllerAnimated:NO completion:nil];  // Return back to parent view
    
    [UIView commitAnimations];  // Play the animation
}


- (IBAction) goKaraoke:(UIButton*)sender
{
    KaraokeViewController *karaoke = [[[KaraokeViewController alloc] initWithNibName:@"KaraokeView" bundle:nil] autorelease];
    assert(karaoke != nil);
    
    // Custom animated transition
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration: 0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view.window cache:YES];
    
    [self presentViewController:karaoke animated:NO completion:nil];   // Show the new view
    
    [UIView commitAnimations];    // Play the animation
}


- (IBAction) goSelection:(UIButton*)sender
{
    SelectionViewController *selection = [[[SelectionViewController alloc] initWithNibName:@"SelectionView" bundle:nil] autorelease];
    assert(selection != nil);
    
    // Custom animated transition
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration: 0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view.window cache:YES];
    
    [self presentViewController:selection animated:NO completion:nil];   // Show the new view
    
    [UIView commitAnimations];    // Play the animation
}


- (IBAction) doPlayRecordedAudio:(UIButton*)sender
{
	if(audioPlayers == nil)
	{		
		NSFileManager *fileMgr = [NSFileManager defaultManager];

		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
		NSArray *dirFiles = [fileMgr contentsOfDirectoryAtPath:[paths objectAtIndex:0] error:nil];
		NSArray *audioFiles = [dirFiles filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(self ENDSWITH '.caf') OR (self ENDSWITH '.wav') OR (self ENDSWITH '.m4a')"]];
		if(audioFiles.count == 0)
		{
			NSString *msg = @"No Audio Files to play.";
			alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
			[alert show];
			return;
		}
		
		audioPlayers = [[NSMutableArray alloc] init];

		for(NSString *fileName in audioFiles)
		{
			NSURL *fileURL = [NSURL fileURLWithPath:[[paths objectAtIndex:0] stringByAppendingPathComponent:fileName] isDirectory:NO];
			if(fileURL == nil)
			{
				continue;
			}
			
			NSError *error = nil;
			AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
			if(player == nil)
			{
				NSLog(@"Error %@ in AVAudioPlayer initialization", [error description]);

				NSString *msg = [NSString stringWithFormat:@"The audio file %@ can't be played.\rError %@.", fileName, [error description]];
				alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
				[alert show];
				break;
			}
			
			[player setDelegate:self];

			if(![player prepareToPlay] || [player duration] == 0.0)
			{
				NSString *msg = [NSString stringWithFormat:@"The audio file %@ is empty or unplayable.", fileName ];
				alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
				[alert show];
			}

			if([player play])
			{
				NSLog(@"%d] Play %@", (audioPlayers.count + 1), fileName);
				
				[audioPlayers addObject:player];
			}
			else
			{
				[player release];
				
				NSString *msg = [NSString stringWithFormat:@"The audio file %@ can't be played.", fileName ];
				alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
				[alert show];
			}			
		}
		
		if(audioPlayers.count != 0)
		{			
			[playRecordedAudioButton setTitle:@"Stop Playing" forState:UIControlStateNormal];
			[deleteRecordedAudioButton setEnabled:NO];
			[backButton setEnabled:NO];
		}
		else
		{
			[audioPlayers release];
			audioPlayers = nil;
		}
	}
	else
	{
		for(AVAudioPlayer *player in audioPlayers)
		{
			if([player isPlaying])
			{
				[player stop];
			}
			
			[player release];
		}
		
		[audioPlayers release];
		audioPlayers = nil;
		
		[playRecordedAudioButton setTitle:@"Play Audio" forState:UIControlStateNormal];
		[deleteRecordedAudioButton setEnabled:YES];
		[backButton setEnabled:YES];
	}
}


- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
	[player release];
	
	[audioPlayers removeObject:player];
	if(audioPlayers.count == 0)
	{
		NSLog(@"Playing completed");
	
		[audioPlayers release];
		audioPlayers = nil;

		[playRecordedAudioButton setTitle:@"Play Audio" forState:UIControlStateNormal];
		[deleteRecordedAudioButton setEnabled:YES];
		[backButton setEnabled:YES];
	}
}


- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError*)error
{
	NSLog(@"Error %@ playing", [error description]);

	[player release];
	
	[audioPlayers removeObject:player];
	if(audioPlayers.count == 0)
	{
		NSLog(@"Playing completed");
		
		[audioPlayers release];
		audioPlayers = nil;
		
		[playRecordedAudioButton setTitle:@"Play Audio" forState:UIControlStateNormal];
		[deleteRecordedAudioButton setEnabled:YES];
		[backButton setEnabled:YES];
	}
}


- (IBAction) doDeleteRecordedAudio:(UIButton*)sender
{	
	NSString *msg = @"Do you really want do delete the Recorded Audio?";
	alert = [[[UIAlertView alloc] initWithTitle:@"Confirmation" message:msg delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];
	[alert show];
}


- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == 1)
	{
		NSFileManager *fileMgr = [NSFileManager defaultManager];

		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);		
		NSArray *dirFiles = [fileMgr contentsOfDirectoryAtPath:[paths objectAtIndex:0] error:nil];
		for(NSString *fileName in dirFiles)
		{
			NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
			
			NSError *error = nil;
			if(![fileMgr removeItemAtPath:filePath error:&error])
			{
				NSLog(@"Error %@ removing audio file %@", [error description], filePath);
				
				NSString *msg = [NSString stringWithFormat:@"The recorded audio can't be deleted.\rError %@.", [error description]];
				alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
				[alert show];
			}
		}
	}
	
	alert = nil;
}


- (void) applicationWillResignActive:(NSNotification *)notification
{
    NSLog(@"applicationWillResignActive");
	
	if(alert != nil)
	{
		[alert dismissWithClickedButtonIndex:0 animated:NO];
		alert = nil;
	}
}


- (void) alertViewCancel:(UIAlertView *)alertView
{
	NSLog(@"alertViewCancel");

	if(alert != nil)
	{
		[alert dismissWithClickedButtonIndex:0 animated:NO];
		alert = nil;
	}
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}


// Override to allow orientations other than the default portrait orientation.
// Called if iOS >= 6
- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


// Called if iOS >= 6
- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end


