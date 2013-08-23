//
//  MusicAppDelegate.h
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import <UIKit/UIKit.h>

@class DJMixer;
@class DJMixerViewController;

@interface MusicAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow *window;
	BOOL wasPlaying;

	@public
    DJMixer *djMixer;
}

@property (retain, nonatomic) IBOutlet UIWindow *window;

@property (retain, nonatomic) DJMixerViewController *djMixerViewController;
@property (retain, nonatomic) NSMutableArray *karaokeData;
@property (assign, atomic) BOOL inBackGround;
@property (assign, nonatomic) NSInteger deviceIdiom;
@property (assign, nonatomic) BOOL retinaDisplay;
@property (retain, nonatomic) NSString *appVersion;

+ (MusicAppDelegate*) sharedInstance;
+ (NSInteger) deviceIdiom;
+ (BOOL) isRetinaDisplay;
+ (NSString*) appVersion;

@end

