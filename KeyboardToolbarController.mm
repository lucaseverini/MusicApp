//
//  KeyboardToolbarController.mm
//  HBS_NEW
//
//  Created by Luca Severini on 6/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "KeyboardToolbarController.h"


@implementation KeyboardToolbarController

@synthesize keyboardToolbarPrevChar;
@synthesize keyboardToolbarNextChar;
@synthesize keyboardToolbarPrevField;
@synthesize keyboardToolbarNextField;
@synthesize keyboardToolbarDone;
@synthesize hidePrevNextCharButtons;
@synthesize hidePrevNextFieldButtons;
@synthesize hideDoneButton;
@synthesize editingTextField;


- (void) viewWillAppear:(BOOL)animated
{
    allButtons = [((UIToolbar*)self.view).items copy];  // Copy all the original buttons on the toolbar
    
    NSMutableArray *buttons = [NSMutableArray arrayWithArray:allButtons];
    
    if(hidePrevNextCharButtons)
    {
        [buttons removeObject:keyboardToolbarPrevChar];
        [buttons removeObject:keyboardToolbarNextChar];

        // Remove the spacing
        [buttons removeObjectAtIndex:0];
    }

    if(hidePrevNextFieldButtons)
    {
        [buttons removeObject:keyboardToolbarPrevField];
        [buttons removeObject:keyboardToolbarNextField];
    }
    
    if(hideDoneButton)
    {
        [buttons removeObject:keyboardToolbarDone];
    }
    
    ((UIToolbar*)self.view).items = buttons;                // Set the buttons on the toolbar

    [super viewWillAppear:animated];    
}


- (void) viewDidDisappear:(BOOL)animated
{
    ((UIToolbar*)self.view).items = allButtons;             // Restore all the original buttons on the toolbar
    
    [super viewDidDisappear:animated]; 
}


- (IBAction) doNextTextPosition:(id)sender
{
    UITextRange *curRange = [editingTextField selectedTextRange];
    if(curRange != nil)
    {
        UITextPosition *newPosition = [editingTextField positionFromPosition:curRange.end offset:1];
        if(newPosition != nil)
        {
            [[UIDevice currentDevice] playInputClick];
            
            UITextRange *newRange = [editingTextField textRangeFromPosition:newPosition toPosition:newPosition];
            [editingTextField setSelectedTextRange:newRange];
        }
    }
}


- (IBAction) doPrevTextPosition:(id)sender
{
    UITextRange *curRange = [editingTextField selectedTextRange];
    if(curRange != nil)
    {
        UITextPosition *newPosition = [editingTextField positionFromPosition:curRange.start offset:-1];
        if(newPosition != nil)
        {
            [[UIDevice currentDevice] playInputClick];
            
            UITextRange *newRange = [editingTextField textRangeFromPosition:newPosition toPosition:newPosition];    
            [editingTextField setSelectedTextRange:newRange];
        }
    }
}

@end

