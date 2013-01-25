//
//  KeyboardToolbarController.h
//  HBS_NEW
//
//  Created by Luca Severini on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KeyboardToolbarController : UIViewController<UIInputViewAudioFeedback>
{
    NSArray *allButtons;
}

@property (nonatomic, retain) IBOutlet UIBarButtonItem *keyboardToolbarPrevChar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *keyboardToolbarNextChar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *keyboardToolbarPrevField;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *keyboardToolbarNextField;
@property (nonatomic) BOOL hidePrevNextCharButtons;
@property (nonatomic) BOOL hidePrevNextRowButtons;
@property (nonatomic) BOOL hidePrevNextFieldButtons;
@property (nonatomic, retain) UITextField *editingTextField;

- (IBAction) doNextTextPosition:(id)sender;
- (IBAction) doPrevTextPosition:(id)sender;

@end

