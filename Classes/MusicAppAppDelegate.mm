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

@implementation MusicAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize karaokeData;


- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions 
{    	
    // NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	viewController = [[DJMixerViewController alloc] initWithNibName:@"DJMixerView" bundle:[NSBundle mainBundle]];
	
    // Init the audio
	djMixer = [[DJMixer alloc] init];
    viewController.djMixer = djMixer;

    // setRootViewController is necessary for correct multiple orientation support on iOS6
    MyNavigationController *navControl = [[MyNavigationController alloc]initWithRootViewController:viewController];
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
    if([djMixer isPlaying])
    {
        [djMixer stop];
        
        [viewController.playButton setTitle:@"Play" forState:UIControlStateNormal];
        [viewController.selectButton setEnabled:YES];
        [viewController.pauseSwitch setEnabled:NO];
     }
    
    [viewController saveControlsValue];
}


- (void) applicationWillTerminate:(UIApplication*)application
{
    if([djMixer isPlaying])
    {
        [djMixer stop];
    }

    // Release the audio
    [djMixer release];
    viewController.djMixer = nil;

    [window release];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"Crashed"];
    [defaults synchronize];
}


- (void) dealloc 
{
    [super dealloc];
}


@end
