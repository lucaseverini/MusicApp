//
// MusicAppDelegate.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import "MusicAppAppDelegate.h"
#import "DJMixerViewController.h"
#import "DJMixer.h"
#import "MyNavigationController.h"


static MusicAppDelegate *sharedInstance = nil;

@implementation MusicAppDelegate

@synthesize window;
@synthesize djMixerViewController;
@synthesize karaokeData;

+ (MusicAppDelegate*) shared
{
	return sharedInstance;
}


- (id) init
{
	self = [super init];
    if(self != nil)
    {
		sharedInstance = self;
	}
	
	return self;
}


- (void) dealloc
{
	[super dealloc];
	
	sharedInstance = nil;
}


- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions 
{    	
    // NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	djMixerViewController = [[DJMixerViewController alloc] initWithNibName:@"DJMixerView" bundle:[NSBundle mainBundle]];
	
    // Init the audio
	djMixer = [[DJMixer alloc] init];
    djMixerViewController.djMixer = djMixer;

    // setRootViewController is necessary for correct multiple orientation support on iOS6
    MyNavigationController *navControl = [[MyNavigationController alloc]initWithRootViewController:djMixerViewController];
    navControl.navigationBarHidden = YES;
    [window setRootViewController:navControl];
   
    [window makeKeyAndVisible];
	
    return YES;
}


- (void) applicationWillEnterForeground:(UIApplication*)application
{
}


- (void) applicationDidEnterBackground:(UIApplication*)application
{
	NSLog(@"applicationDidEnterBackground");
/*
    if([djMixer isPlaying])
    {
        [djMixer stop];
        
        [viewController.playButton setTitle:@"Play" forState:UIControlStateNormal];
        [viewController.selectButton setEnabled:YES];
        [viewController.pauseSwitch setEnabled:NO];
     }
    
	if(djMixer.fileRecording)
	{
		[viewController recordStop];
	}
*/
	if(djMixer.isPlaying && !djMixer.paused)
	{
		djMixerViewController.pauseSwitch.on = YES;
		djMixerViewController.pauseSwitchLS.on = YES;
		
		// [viewController pause:YES];
	}
}


- (void) applicationWillTerminate:(UIApplication*)application
{
    if([djMixer isPlaying])
    {
        [djMixer stopPlay];
    }

    // Release the audio
    [djMixer release];
    djMixerViewController.djMixer = nil;

    [window release];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"Crashed"];
    [defaults synchronize];
}

@end
