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

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) DJMixerViewController *djMixerViewController;
@property (nonatomic, retain) NSMutableArray *karaokeData;
@property (atomic, assign) BOOL inBackGround;

+ (MusicAppDelegate*) shared;

@end

