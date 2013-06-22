//
//  SelectionViewController.h
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class UICheckBox;
@class FileTableController;
@class KaraokeViewController;

@interface SelectionViewController : UIViewController<MPMediaPickerControllerDelegate>
{
    NSString *fileTitleText;
    NSIndexPath *selectedRow;
    NSInteger channel;
	NSString *userDocDirPath;
}

@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *clearButton;
@property (nonatomic, retain) IBOutlet UITableView *fileTable;
@property (nonatomic, retain) IBOutlet FileTableController *fileTableController;
@property (nonatomic, retain) IBOutlet UILabel *versionLabel;

- (IBAction) goBack:(UIButton*)sender;
- (IBAction) doClearList:(UIButton*)sender;

- (void) doSelectFile:(NSIndexPath*)row;
- (NSURL*) copyAudioFile:(NSString*)fileUrlString to:(NSString*)folderPathString named:(NSString*)fileName;

@end
