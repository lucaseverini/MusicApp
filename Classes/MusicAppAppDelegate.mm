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
#import "Utilities.h"


static MusicAppDelegate *sharedInstance = nil;

@implementation MusicAppDelegate

@synthesize window;
@synthesize djMixerViewController;
@synthesize karaokeData;
@synthesize inBackGround;
@synthesize retinaDisplay;
@synthesize deviceIdiom;
@synthesize appVersion;

- (id) init
{
	self = [super init];
    if(self != nil)
    {
		sharedInstance = self;

		deviceIdiom = [[UIDevice currentDevice] userInterfaceIdiom];
		
		CGSize screenSize = [[UIScreen mainScreen] currentMode].size;
		if(deviceIdiom == UIUserInterfaceIdiomPad)
		{
			retinaDisplay = (screenSize.height >= 1536.0);
		}
		else
		{
			retinaDisplay = (screenSize.height >= 640.0);
		}
		
		NSDictionary *pList = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"]];
		appVersion = [[NSString alloc] initWithFormat:@"Version %@ (built %s %s)", [pList objectForKey:@"CFBundleShortVersionString"], __DATE__, __TIME__];
	}
	
	return self;
}


- (void) dealloc
{
	[super dealloc];
	
	[appVersion release];
	
	sharedInstance = nil;
}


- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions 
{    	
	[Crashlytics startWithAPIKey:kCrashlyticsAPIKey];
	
	NSLog(@"App %@ %@ launched", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"], appVersion);
	
#if TARGET_IPHONE_SIMULATOR
	NSLog(@"App folder: %@", NSHomeDirectory());
#endif // TARGET_IPHONE_SIMULATOR
	
	NSLog(@"Device name: %@", [[UIDevice currentDevice] name]);
	NSLog(@"Device model: %@", [[UIDevice currentDevice] model]);
	NSLog(@"Localized model: %@", [[UIDevice currentDevice] localizedModel]);
	NSLog(@"System version: %@", [[UIDevice currentDevice] systemVersion]);
	NSLog(@"Platform: %@", platformString());
	NSLog(@"UI idiom: %d %@", deviceIdiom, deviceIdiom == UIUserInterfaceIdiomPhone ? @"(iPhone)" : @"(iPad)");
	
	CGSize screenSize = [[UIScreen mainScreen] currentMode].size;
	NSLog(@"Screen size: %gx%g %@", screenSize.width, screenSize.height, retinaDisplay ? @"(Retina)" : @"");
	
	NSLog(@"Screen scale: %g", [UIScreen mainScreen].scale);
	
	NSInteger orientation = [UIApplication sharedApplication].statusBarOrientation;
	NSLog(@"Orientation: %d (%@)", orientation, GetOrientationName(orientation));

	djMixerViewController = [[DJMixerViewController alloc] initWithNibName:@"DJMixerView" bundle:[NSBundle mainBundle]];
	
    // Init the audio
	djMixer = [[DJMixer alloc] init];
    djMixerViewController.djMixer = djMixer;
	
    // setRootViewController is necessary for correct multiple orientation support on iOS6
    MyNavigationController *navControl = [[[MyNavigationController alloc] initWithRootViewController:djMixerViewController] autorelease];
    navControl.navigationBarHidden = YES;
    [window setRootViewController:navControl];
	
    [window makeKeyAndVisible];

	return YES;
}


- (void) applicationDidBecomeActive:(UIApplication*)application;
{
	NSLog(@"applicationDidBecomeActive");

	if(wasPlaying)
	{
		[djMixer pause:NO];
		// [djMixer startPlay];
	}
}


- (void) applicationWillResignActive:(UIApplication*)application;
{
	NSLog(@"applicationWillResignActive");
	
	if(djMixer.isPlaying && !djMixer.paused)
	{
		wasPlaying = YES;
		
		[djMixer pause:YES];
		// [djMixer stopPlay];
	}
	else
	{
		wasPlaying = NO;
	}
}


- (void) applicationWillEnterForeground:(UIApplication*)application
{
	inBackGround = NO;

	NSLog(@"applicationWillEnterForeground");
/*
	if(wasPlaying)
	{
		[djMixer startPlay];
	}
*/
}


- (void) applicationDidEnterBackground:(UIApplication*)application
{
	inBackGround = YES;
	
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
/*
	if(djMixer.isPlaying && !djMixer.paused)
	{
		wasPlaying = YES;
		
		[djMixer stopPlay];
	}
	else
	{
		wasPlaying = NO;
	}
*/
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


+ (MusicAppDelegate*) sharedInstance
{
	return sharedInstance;
}


+ (NSInteger) deviceIdiom
{
	return sharedInstance.deviceIdiom;
}


+ (BOOL) isRetinaDisplay
{
	return sharedInstance.retinaDisplay;
}


+ (NSString*) appVersion
{
	return sharedInstance.appVersion;
}

@end
