//
//  SettingsViewController.h
//  MusicApp
//
//  Created by Luca Severini on 14/2/2012.
//

#import <UIKit/UIKit.h>

@class KaraokeViewController;

@interface SettingsViewController : UIViewController

@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *goKaraokeButton;
@property (nonatomic, retain) IBOutlet UIButton *goSelectionButton;
@property (nonatomic, retain) IBOutlet UILabel *versionLabel;
@property (nonatomic, retain) IBOutlet UILabel *simulatorLabel;

- (IBAction) goBack:(UIButton*)sender;
- (IBAction) goKaraoke:(UIButton*)sender;
- (IBAction) goSelection:(UIButton*)sender;

@end
