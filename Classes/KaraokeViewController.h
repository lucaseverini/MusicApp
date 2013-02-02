//
//  KaraokeViewController.h
//  MusicApp
//
//  Created by Luca Severini on 22/1/2013.
//

#import <UIKit/UIKit.h>


static NSString *kWordsKey = @"wordsKey";
static NSString *kTimeKey = @"timeKey";
static NSString *kTypeKey = @"typeKey";

@class NSIndexPath;
@class UIToolbar;
@class UITextField;
@class KaraokeTableCell;
@class KeyboardToolbarController;

@interface KaraokeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UINavigationBarDelegate>
{
    UITextField *editingTextField;
    int tapCount;
}

@property (nonatomic, retain) IBOutlet UINavigationBar *tableBar;
@property (nonatomic, retain) IBOutlet UINavigationItem *tableBarItem;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *tableBarEditButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *tableBarDoneButton;
@property (nonatomic, retain) IBOutlet UITableView *karaokeTable;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIToolbar *keyboardToolbar;
@property (nonatomic, retain) IBOutlet KeyboardToolbarController *keyboardController;

@property (nonatomic, retain) NSMutableArray *dataSourceArray;
@property (nonatomic, retain) NSIndexPath *tableSelection;
@property (nonatomic, assign) NSUInteger selectedCellIndex;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, retain) KaraokeTableCell *activeCell;

- (IBAction) goBack:(UIButton*)sender;
- (IBAction) doPrevTextField:(id)sender;
- (IBAction) doNextTextField:(id)sender;
- (IBAction) doDoneKeybInput:(id)sender;

- (IBAction) doNextTextPosition:(id)sender;
- (IBAction) doPrevTextPosition:(id)sender;

- (IBAction) EditTable:(id)sender;

@end
