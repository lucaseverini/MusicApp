//
//  SettingsViewController.h
//  MusicApp
//
//  Created by Luca Severini on 14/2/2012.
//


@class KaraokeViewController;
@class AVAudioPlayer;

@interface SettingsViewController : UIViewController <AVAudioPlayerDelegate, UIAlertViewDelegate>
{
	NSMutableArray	*audioPlayers;
	UIAlertView *alert;
}

@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *goKaraokeButton;
@property (nonatomic, retain) IBOutlet UIButton *goSelectionButton;
@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) IBOutlet UILabel *simulatorLabel;
@property (nonatomic, retain) IBOutlet UIButton *playRecordedAudioButton;
@property (nonatomic, retain) IBOutlet UIButton *deleteRecordedAudioButton;
@property (nonatomic, retain) IBOutlet UISwitch *autoStartKaraokeSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *autoStartRecordingSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *autoStopRecordingSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *playContinuousSwitch;
@property (nonatomic, retain) IBOutlet UISwitch *autoSetAudioInputSwitch;

- (IBAction) goBack:(UIButton*)sender;
- (IBAction) goKaraoke:(UIButton*)sender;
- (IBAction) goSelection:(UIButton*)sender;
- (IBAction) doPlayRecordedAudio:(UIButton*)sender;
- (IBAction) doDeleteRecordedAudio:(UIButton*)sender;
- (IBAction) doAutoStartKaraoke:(UISwitch*)sender;
- (IBAction) doAutoStartRecording:(UISwitch*)sender;
- (IBAction) doAutoStopRecording:(UISwitch*)sender;
- (IBAction) doPlayContinuous:(UISwitch*)sender;
- (IBAction) doAutoSetAudioInput:(UISwitch*)sender;

@end
