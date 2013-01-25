//
//  KaraokeViewController.mm
//  MusicApp
//
//  Created by Luca Severini on 22/1/20132.
//

#import <UIKit/UIKit.h>
#import "KaraokeViewController.h"
#import "KeyboardToolbarController.h"

@implementation KaraokeViewController

@synthesize karaokeTable;
@synthesize editText;
@synthesize editTime;
@synthesize addButton;
@synthesize removeButton;
@synthesize backButton;
@synthesize keyboardToolbar;

- (void) viewDidLoad
{        
}


- (void) viewWillDisappear:(BOOL)animated
{
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (IBAction) goBack:(UIButton*)sender
{	
    // Custom animated transition
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration: 0.5];    
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view.window cache:YES];       

    [self dismissViewControllerAnimated:NO completion:nil];  // Return back to parent view

    [UIView commitAnimations];  // Play the animation
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}


- (void) didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void) dealloc 
{
    [super dealloc];
}


- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}


- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *CellIdentifier = @"TableCell";
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil)
	{
 		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
 	}
    
    NSInteger cellIdx = [indexPath row];
    
    NSString *text = [[NSString alloc ] initWithFormat:@"%d", cellIdx];
    cell.textLabel.text = text;
    
    return cell;
}


- (BOOL) textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    
    return NO;
}


- (void) textFieldDidBeginEditing:(UITextField*)textField
{
    editingTextField = textField;
/*
    KeyboardToolbarController *controller = (KeyboardToolbarController*)[keyboardToolbar nextResponder];
    assert(controller != nil);
    controller.editingTextField = textField;
    controller.hidePrevNextRowButtons = YES;
*/    
    [textField setInputAccessoryView:keyboardToolbar];
}


- (void)textFieldDidEndEditing:(UITextField*)textField
{
    editingTextField = nil;
}


- (IBAction) doPrevTextField:(id)sender
{
    if(editingTextField == editText)
    {
        [editTime becomeFirstResponder];
    }
    else if(editingTextField == editTime)
    {
        [editText becomeFirstResponder];
    }
}


- (IBAction) doNextTextField:(id)sender
{
    if(editingTextField == editText)
    {
        [editTime becomeFirstResponder];
    }
    else if(editingTextField == editTime)
    {
        [editText becomeFirstResponder];
    }
}


- (IBAction) doDoneKeybInput:(id)sender
{
    [editingTextField resignFirstResponder];
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


- (BOOL) resignFirstResponder
{
    return YES;
}

@end


