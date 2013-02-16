//
//  DJMixerViewController.h
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import <UIKit/UIKit.h>

@class DJMixer;
@class SelectionViewController;
@class UITextScroll;
@class Karaoke;

@interface DJMixerViewController : UIViewController
{
	DJMixer *djMixer;	
    UISlider* sliders[9];
}

@property (nonatomic, retain) IBOutlet UIView *portraitView;
@property (nonatomic, retain) IBOutlet UIView *landscapeView;

@property (nonatomic, retain) IBOutlet UISlider *channel1VolumeSlider;
@property (nonatomic, retain) IBOutlet UISlider *channel2VolumeSlider;
@property (nonatomic, retain) IBOutlet UISlider *channel3VolumeSlider;
@property (nonatomic, retain) IBOutlet UISlider *channel4VolumeSlider;
@property (nonatomic, retain) IBOutlet UISlider *channel5VolumeSlider;
@property (nonatomic, retain) IBOutlet UISlider *channel6VolumeSlider;
@property (nonatomic, retain) IBOutlet UISlider *channel7VolumeSlider;
@property (nonatomic, retain) IBOutlet UISlider *channel8VolumeSlider;
@property (nonatomic, retain) IBOutlet UISlider *audioInputVolumeSlider;
@property (nonatomic, retain) IBOutlet UILabel *channel1Label;
@property (nonatomic, retain) IBOutlet UILabel *channel2Label;
@property (nonatomic, retain) IBOutlet UILabel *channel3Label;
@property (nonatomic, retain) IBOutlet UILabel *channel4Label;
@property (nonatomic, retain) IBOutlet UILabel *channel5Label;
@property (nonatomic, retain) IBOutlet UILabel *channel6Label;
@property (nonatomic, retain) IBOutlet UILabel *channel7Label;
@property (nonatomic, retain) IBOutlet UILabel *channel8Label;
@property (nonatomic, retain) IBOutlet UILabel *audioInputLabel;
@property (nonatomic, retain) IBOutlet UIButton *playButton;
@property (nonatomic, retain) IBOutlet UIButton *selectButton;
@property (nonatomic, retain) IBOutlet UISwitch *pauseSwitch;
@property (nonatomic, retain) IBOutlet UIButton *karaokeButton;
@property (nonatomic, retain) IBOutlet UITextScroll *karaokeText;

@property (nonatomic, retain) IBOutlet UIButton *playButtonLS;
@property (nonatomic, retain) IBOutlet UIButton *selectButtonLS;
@property (nonatomic, retain) IBOutlet UISwitch *pauseSwitchLS;
@property (nonatomic, retain) IBOutlet UIButton *karaokeButtonLS;
@property (nonatomic, retain) IBOutlet UITextScroll *karaokeTextLS;

@property (nonatomic, retain) DJMixer *djMixer;
@property (nonatomic, retain) Karaoke *karaoke;
@property (nonatomic, retain) NSTimer *karaokeTimer;
@property (nonatomic, assign) BOOL isPortrait;

- (IBAction) changeVolume:(UISlider*)sender;
- (IBAction) playOrStop;
- (IBAction) pause:(UISwitch*)sender;
- (IBAction) goSettings:(UIButton*)sender;
- (IBAction) doKaraoke:(UIButton*)sender;

- (void)saveControlsValue;
- (void)karaokeStep;

@end
