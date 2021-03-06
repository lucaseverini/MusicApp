//
//  DJMixerViewController.h
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//


@class UITextScroll;
@class DJMixer;
@class SelectionViewController;
@class Karaoke;
@class AVAudioPlayer;

@interface DJMixerViewController : UIViewController <AVAudioPlayerDelegate, UIAlertViewDelegate>
{
	DJMixer *djMixer;	
    NSDate *karaokePauseStart;
    NSDate *karaokePrevFireDate;
	UIAlertView *alert;
	NSMutableDictionary *channelLabels;
	NSMutableDictionary *channelSliders;
	BOOL wasPlaying;
	NSString *userDocDirPath;
	UIButton *selectedRecording;
	AVAudioPlayer *audioPlayer;
	CGPoint textOffset;
	CGPoint textOffsetLS;
}

@property (nonatomic, retain) IBOutlet UIView *portraitView;
@property (nonatomic, retain) IBOutlet UIView *landscapeView;

@property (nonatomic, retain) IBOutlet UISlider *channel1Slider;
@property (nonatomic, retain) IBOutlet UISlider *channel2Slider;
@property (nonatomic, retain) IBOutlet UISlider *channel3Slider;
@property (nonatomic, retain) IBOutlet UISlider *channel4Slider;
@property (nonatomic, retain) IBOutlet UISlider *channel5Slider;
@property (nonatomic, retain) IBOutlet UISlider *channel6Slider;
@property (nonatomic, retain) IBOutlet UISlider *channel7Slider;
@property (nonatomic, retain) IBOutlet UISlider *channel8Slider;
@property (nonatomic, retain) IBOutlet UISlider *audioInputSlider;
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
@property (nonatomic, retain) IBOutlet UIButton *pauseButton;
@property (nonatomic, retain) IBOutlet UIButton *karaokeButton;
@property (nonatomic, retain) IBOutlet UITextScroll *karaokeText;
@property (nonatomic, retain) IBOutlet UIButton *recordButton;

@property (nonatomic, retain) IBOutlet UIButton *playButtonLS;
@property (nonatomic, retain) IBOutlet UIButton *selectButtonLS;
@property (nonatomic, retain) IBOutlet UIButton *pauseButtonLS;
@property (nonatomic, retain) IBOutlet UIButton *karaokeButtonLS;
@property (nonatomic, retain) IBOutlet UIButton *recordButtonLS;
@property (nonatomic, retain) IBOutlet UITextScroll *karaokeTextLS;
@property (nonatomic, retain) IBOutlet UILabel *positionLabelLS;
@property (nonatomic, retain) IBOutlet UILabel *durationLabelLS;
@property (nonatomic, retain) IBOutlet UISlider *positionSliderLS;
@property (nonatomic, retain) IBOutlet UISwitch *sequencerSwitchLS;
@property (nonatomic, retain) IBOutlet UIButton *sequencerUndoLS;
@property (nonatomic, retain) IBOutlet UIScrollView *sequencerScrollViewLS;
@property (nonatomic, retain) IBOutlet UIView *sequencerRecViewLS;
@property (nonatomic, retain) IBOutlet UIButton *recordingDeleteLS;
@property (nonatomic, retain) IBOutlet UIButton *recordingPlayLS;
@property (nonatomic, retain) IBOutlet UIButton *recordingShiftLS;
@property (nonatomic, retain) IBOutlet UIButton *recordingEnableLS;
@property (nonatomic, retain) IBOutlet UILabel *sequencerLabelLS;
@property (nonatomic, retain) IBOutlet UISlider *sequencerSliderLS;

@property (nonatomic, retain) DJMixer *djMixer;
@property (nonatomic, retain) Karaoke *karaoke;
@property (nonatomic, retain) NSTimer *karaokeTimer;
@property (nonatomic, retain) NSTimer *checkDiskSizeTimer;
@property (nonatomic, retain) NSTimer *checkPositionTimer;
@property (nonatomic, retain) NSTimer *updateRecViewTimer;
@property (nonatomic, assign) BOOL isPortrait;
@property (atomic, assign) BOOL karaokeActivated;
@property (nonatomic, retain) NSMutableArray *sequencerButtons;

- (IBAction) changeVolume:(UISlider*)sender;
- (IBAction) playOrStop;
- (IBAction) doPause:(UIButton*)sender;
- (IBAction) goSettings:(UIButton*)sender;
- (IBAction) doKaraoke:(UIButton*)sender;
- (IBAction) doRecord:(UIButton*)sender;
- (IBAction) setPlayPosition:(UISlider*)sender;
- (IBAction) doPauseSequencer:(UISwitch*)sender;
- (IBAction) doUndoSequencer:(UIButton*)sender;
- (IBAction) doSelectLastRecording:(UIButton*)sender;
- (IBAction) doDeleteRecording:(UIButton*)sender;
- (IBAction) doPlayRecording:(UIButton*)sender;
- (IBAction) doShiftRecording:(UIButton*)sender;
- (IBAction) doEnableRecording:(UIButton*)sender;

- (void) pause:(BOOL)flag;
- (void) saveControlsValue;
- (void) karaokeStep;
- (void) recordStart;
- (void) recordStop;
- (NSUInteger) checkDiskSize:(BOOL)showAlert;
- (void) updatePlayPosition;
- (void) setPlayPositionEnded:(NSNotification*)notification;
- (void) enableAudioInput;
- (void) disableAudioInput;
- (void) updateSequencerButtons;

@end
