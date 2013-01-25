//
//  MusicAppAppDelegate.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import "MusicAppAppDelegate.h"
#import "DJMixerViewController.h"
#import "DJMixer.h"

@implementation MusicAppAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions 
{    	
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSInteger buffers = [defaults integerForKey:@"Buffers"];
    if(buffers == 0)
    {
        buffers = kNumberRecordBuffers;
        
        [defaults setInteger:buffers forKey:@"Buffers"];
        [defaults synchronize];
    }
    
    float duration = [defaults floatForKey:@"Duration"];
    if(duration == 0.0)
    {
        duration = kBufferDurationSeconds;
        
        [defaults setFloat:duration forKey:@"Duration"];
        [defaults synchronize];
    }

	viewController = [[DJMixerViewController alloc] initWithNibName:@"DJMixerView" bundle:[NSBundle mainBundle]];
	
    // Init the audio
	djMixer = [[DJMixer alloc] init];
    viewController.djMixer = djMixer;

	[window addSubview:viewController.view];
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
