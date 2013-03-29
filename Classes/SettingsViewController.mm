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

- (void) viewDidLoad
{        
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDict objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];    
    versionLabel.text = [NSString stringWithFormat:@"%@ %@", appName, appVersion];
}


- (void) viewWillDisappear:(BOOL)animated
{
	if([audioPlayer isPlaying])
	{
		[audioPlayer stop];

		[audioPlayer release];
		audioPlayer = nil;
		
		[playRecordedAudioButton setTitle:@"Play Recorded Audio" forState:UIControlStateNormal];
		[deleteRecordedAudioButton setEnabled:YES];
	}

    [super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"record.caf"];
	if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		[playRecordedAudioButton setEnabled:YES];
		[deleteRecordedAudioButton setEnabled:YES];
	}
	else
	{
		[playRecordedAudioButton setEnabled:NO];
		[deleteRecordedAudioButton setEnabled:NO];
	}
    
	[playRecordedAudioButton setTitle:@"Play Recorded Audio" forState:UIControlStateNormal];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [autoStartKaraokeSwitch setOn:[defaults boolForKey:@"KaraokeAutoOn"]];
    [autoStartRecordingSwitch setOn:[defaults boolForKey:@"RecordingAutoOn"]];
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
	if(audioPlayer == nil)
	{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
		NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"record.caf"];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath isDirectory:NO];
		if(fileURL == nil)
		{
			return;
		}
		
		NSError *error = nil;
		audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
		if(audioPlayer == nil)
		{
			NSLog(@"Error %@ in AVAudioPlayer initialization", [error description]);

			NSString *msg = [NSString stringWithFormat:@"The recorded audio can't be played.\rError %@.", [error description]];
			alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
			[alert show];
			return;
		}
		
		[audioPlayer setDelegate:self];

		if(![audioPlayer prepareToPlay] || [audioPlayer duration] == 0.0)
		{
			NSString *msg = @"The recorded audio is empty or unusable.";
			alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
			[alert show];
			return;
		}

		if([audioPlayer play])
		{
			NSLog(@"Playing %@...", [filePath lastPathComponent]);
		}
		else
		{
			NSString *msg = @"The recorded audio can't be played.";
			alert = [[[UIAlertView alloc] initWithTitle:@"Error!" message:msg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
			[alert show];
			return;
		}
		
		[playRecordedAudioButton setTitle:@"Stop Playing" forState:UIControlStateNormal];
		[deleteRecordedAudioButton setEnabled:NO];
	}
	else
	{
		if([audioPlayer isPlaying])
		{
			[audioPlayer stop];
		}
		
		[audioPlayer release];
		audioPlayer = nil;		

		[playRecordedAudioButton setTitle:@"Play Recorded Audio" forState:UIControlStateNormal];
		[deleteRecordedAudioButton setEnabled:YES];
	}
}


- (void) audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
	NSLog(@"Playing completed");

	[audioPlayer release];
	audioPlayer = nil;

	[playRecordedAudioButton setTitle:@"Play Recorded Audio" forState:UIControlStateNormal];
	[deleteRecordedAudioButton setEnabled:YES];
}


- (void) audioPlayerDecodeErrorDidOccur:(AVAudioPlayer*)player error:(NSError*)error
{
	NSLog(@"Error %@ playing", [error description]);

	[audioPlayer release];
	audioPlayer = nil;
	
	[playRecordedAudioButton setTitle:@"Play Recorded Audio" forState:UIControlStateNormal];
	[deleteRecordedAudioButton setEnabled:YES];
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
		NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"record.caf"];
		if([fileMgr fileExistsAtPath:filePath])
		{
			NSError *error = nil;
			if([fileMgr removeItemAtPath:filePath error:&error])
			{
				[playRecordedAudioButton setEnabled:NO];
				[deleteRecordedAudioButton setEnabled:NO];
			}
			else
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


