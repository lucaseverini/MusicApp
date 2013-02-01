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

@interface KaraokeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
{
    UITextField *editingTextField;
    int tapCount;
    NSIndexPath *tableSelection;
}

@property (nonatomic, retain) IBOutlet UITableView *karaokeTable;
@property (nonatomic, retain) IBOutlet UITextField *editText;
@property (nonatomic, retain) IBOutlet UITextField *editTime;
@property (nonatomic, retain) IBOutlet UIButton *addButton;
@property (nonatomic, retain) IBOutlet UIButton *removeButton;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIToolbar *keyboardToolbar;

@property (nonatomic, retain) NSMutableArray *dataSourceArray;
@property (nonatomic, assign) NSUInteger selectedCellIndex;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, retain) KaraokeTableCell *activeCell;

- (IBAction) goBack:(UIButton*)sender;
- (IBAction) doPrevTextField:(id)sender;
- (IBAction) doNextTextField:(id)sender;
- (IBAction) doDoneKeybInput:(id)sender;

- (IBAction) doNextTextPosition:(id)sender;
- (IBAction) doPrevTextPosition:(id)sender;

@end
