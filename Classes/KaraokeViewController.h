//
//  KaraokeViewController.h
//  MusicApp
//
//  Created by Luca Severini on 22/1/2013.
//

#import <UIKit/UIKit.h>


@class NSIndexPath;
@class UIToolbar;
@class UITextField;
@class KaraokeTableCell;
@class KeyboardToolbarController;

@interface KaraokeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UINavigationBarDelegate, UIAlertViewDelegate>
{
    UITextField *editingTextField;
    int tapCount;
	NSMutableArray *lyricFiles;
}

@property (nonatomic, retain) IBOutlet UINavigationBar *tableBar;
@property (nonatomic, retain) IBOutlet UINavigationItem *tableBarItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *tableBarEditButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *tableBarDoneButton;
@property (nonatomic, retain) IBOutlet UILabel *karaokeTitle;
@property (nonatomic, retain) IBOutlet UITableView *karaokeTable;
@property (nonatomic, retain) IBOutlet UIButton *saveFileButton;
@property (nonatomic, retain) IBOutlet UIButton *loadFileButton;
@property (nonatomic, retain) IBOutlet UIButton *deleteFileButton;
@property (nonatomic, retain) IBOutlet UIButton *lyricsButtonNew;
@property (nonatomic, retain) IBOutlet UIButton *lyricsButtonCopy;
@property (nonatomic, retain) IBOutlet UIButton *lyricsButtonPaste;
@property (nonatomic, retain) IBOutlet UIButton *lyricsButtonDelete;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIToolbar *keyboardToolbar;
@property (nonatomic, retain) IBOutlet KeyboardToolbarController *keyboardController;

@property (nonatomic, retain) NSString *userDocDirPath;
@property (nonatomic, retain) NSMutableArray *dataSourceArray;
@property (nonatomic, retain) NSIndexPath *tableSelection;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, retain) KaraokeTableCell *activeCell;

- (IBAction) goBack:(id)sender;
- (IBAction) doPrevTextField:(id)sender;
- (IBAction) doNextTextField:(id)sender;
- (IBAction) doDoneKeybInput:(id)sender;
- (IBAction) doNextTextPosition:(id)sender;
- (IBAction) doPrevTextPosition:(id)sender;
- (IBAction) editTable:(id)sender;
- (IBAction) doSaveLyricsFile:(id)sender;
- (IBAction) doLoadLyricsFile:(id)sender;
- (IBAction) doDeleteLyricsFile:(id)sender;

- (IBAction) doNewLyrics:(id)sender;
- (IBAction) doCopyLyrics:(id)sender;
- (IBAction) doPasteLyrics:(id)sender;
- (IBAction) doDeleteLyrics:(id)sender;

- (BOOL) fileDataToLyrics:(NSString*)fileName;
- (NSData*) lyricsToFileData:(NSArray*)lyricsArray title:(NSString*)title artist:(NSString*)artist;
- (void) lyricsFileSelected:(NSNumber*)selectedIndex reference:(id)reference;
- (BOOL) stringToLyrics:(NSString*)string;

@end
