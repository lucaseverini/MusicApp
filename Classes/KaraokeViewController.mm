//
//  KaraokeViewController.mm
//  MusicApp
//
//  Created by Luca Severini on 22/1/20132.
//

#import <UIKit/UIKit.h>
#import "KaraokeViewController.h"
#import "KaraokeTableCell.h"
#import "KeyboardToolbarController.h"


@implementation KaraokeViewController

@synthesize tableBar;
@synthesize tableBarItem;
@synthesize tableBarEditButton;
@synthesize tableBarDoneButton;
@synthesize karaokeTable;
@synthesize backButton;
@synthesize keyboardToolbar;
@synthesize keyboardController;

@synthesize tableSelection;
@synthesize dataSourceArray;
@synthesize selectedCellIndex;
@synthesize isEditing;
@synthesize activeCell;


- (id)initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
    }
    
    return self;
}


- (void) viewDidLoad
{
    [super viewDidLoad];
}


- (void) viewDidUnload
{
    [super viewDidUnload];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"KaraokeData.plist"];
    
    if(self.dataSourceArray.count > 0)
    {
        if([self.dataSourceArray writeToFile:filePath atomically:YES])
        {
            NSLog(@"File %@ written", filePath);
        }
        else
        {
            NSLog(@"File %@ not written", filePath);
        }
    }
    else
    {
        if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            NSError *error;
            if(![[NSFileManager defaultManager] removeItemAtPath:filePath error:&error])
            {
                NSLog(@"Unable to delete file: %@", [error localizedDescription]);
            }
        }
    }
    
    [self.dataSourceArray release];
    self.dataSourceArray = nil;
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"KaraokeData.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSLog(@"File %@ is available", filePath);
        
        self.dataSourceArray = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
    }
    else
    {
        NSLog(@"File %@ is missing", filePath);

        self.dataSourceArray = [[NSMutableArray alloc] init];
    }
    
    self.editing = NO;
    
    [self.tableBarItem setLeftBarButtonItem:self.tableBarEditButton];
    
    self.keyboardController.hideDoneButton = YES;
}


- (IBAction) goBack:(UIButton*)sender
{
    if(self.isEditing)
    {
        // Because of how is implemented this table implemented both are needed
        [self setEditing:NO];
        [self.karaokeTable setEditing:NO animated:NO];
    }
    
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
    // Return the number of rows in the list.
    return [self.dataSourceArray count];
}


- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    KaraokeTableCell *cell = nil;
    
    NSUInteger row = [indexPath row];
    
    NSDictionary *rowDict = [self.dataSourceArray objectAtIndex:row];
    assert(rowDict != nil);
    
    NSString *rowType = [rowDict objectForKey:kTypeKey];
    assert(rowType != nil);
    
    if([rowType isEqualToString:@"Add"])
    {
        NSString *kCellTextFieldID = @"addCell_ID";
        cell = (KaraokeTableCell*) [tableView dequeueReusableCellWithIdentifier:kCellTextFieldID];
        if(cell == nil)
        {
            // a new cell needs to be created
            UITableViewCellStyle cellStyle = 100;
            cell = [[KaraokeTableCell alloc] initWithStyle:cellStyle reuseIdentifier:kCellTextFieldID];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else
    {
        NSString *kCellTextFieldID = @"realCell_ID";
        cell = (KaraokeTableCell*) [tableView dequeueReusableCellWithIdentifier:kCellTextFieldID];
        if(cell == nil)
        {
            // a new cell needs to be created
            UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
            cell = [[KaraokeTableCell alloc] initWithStyle:cellStyle reuseIdentifier:kCellTextFieldID];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.words.delegate = self;
        cell.words.text = [[self.dataSourceArray objectAtIndex: row] valueForKey:kWordsKey];
        cell.words.enabled = self.isEditing;
        cell.words.returnKeyType = UIReturnKeyDefault;
        
        cell.time.delegate = self;
        NSNumber *value = [[self.dataSourceArray objectAtIndex: row] valueForKey:kTimeKey];
        cell.time.text = (cell.words.text.length == 0) ? nil : [ value stringValue];
        cell.time.enabled = self.isEditing;
        cell.time.returnKeyType = UIReturnKeyDefault;
    }
    
    return cell;
}


- (IBAction) doPrevTextField:(id)sender
{
    if(editingTextField.tag == 1)
    {
        // [activeCell.time becomeFirstResponder];
    }
    else if(editingTextField.tag == 2)
    {
        [activeCell.words becomeFirstResponder];
    }
}


- (IBAction) doNextTextField:(id)sender
{
    if(editingTextField.tag == 1)
    {
        [activeCell.time becomeFirstResponder];
    }
    else if(editingTextField.tag == 2)
    {
        [self.tableSelection autorelease];
        
        NSIndexPath *newSelection;
        
        if((self.dataSourceArray.count - 1) > self.tableSelection.row + 1)
        {
            newSelection = [NSIndexPath indexPathForRow:self.tableSelection.row + 1 inSection:0];
        }
        else
        {
            newSelection = [NSIndexPath indexPathForRow:0 inSection:0];
        }
        
        [self.karaokeTable selectRowAtIndexPath:newSelection animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self tableView:self.karaokeTable didSelectRowAtIndexPath:newSelection];
        
        [activeCell.words becomeFirstResponder];
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


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NSUInteger row = [indexPath row];
    
    BOOL result = self.isEditing;
    
    return result;
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NSUInteger row = [indexPath row];
    
    BOOL result = self.isEditing;
    
    return result;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if([sourceIndexPath row] != [destinationIndexPath row])
    {
        NSLog(@"moveRowAtIndexPath from %d to %d", [sourceIndexPath row], [destinationIndexPath row]);
        
        [self.dataSourceArray exchangeObjectAtIndex:[sourceIndexPath row] withObjectAtIndex:[destinationIndexPath row]];
    }
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(editingStyle)
    {
        case UITableViewCellEditingStyleDelete:
        {
            NSLog(@"commitEditingStyle: Delete row %d", [indexPath row]);
            
            [self.dataSourceArray removeObjectAtIndex:[indexPath row]];

            if([indexPath row] == [self.karaokeTable indexPathForCell:activeCell].row)
            {
                if(self.isEditing)
                {
                    [self.karaokeTable reloadData];
                }
            }
            else
            {
                NSArray *rowArray = [NSArray arrayWithObject:indexPath];
                [self.karaokeTable deleteRowsAtIndexPaths:rowArray withRowAnimation:UITableViewRowAnimationMiddle];
            }
        }
            break;
            
        case UITableViewCellEditingStyleInsert:
        {
            NSLog(@"commitEditingStyle: Insert row %d", [indexPath row]);
            
            id obj = [NSDictionary dictionaryWithObjectsAndKeys:@"Normal", kTypeKey, @"", kWordsKey, [NSNumber numberWithDouble:0.0], kTimeKey, nil];
            [self.dataSourceArray insertObject:obj atIndex:[indexPath row]];
            
            NSArray *rowArray = [NSArray arrayWithObject:indexPath];
            [self.karaokeTable insertRowsAtIndexPaths:rowArray withRowAnimation:UITableViewRowAnimationMiddle];
            
            //activeCell = (KaraokeTableCell*)[self.karaokeTable cellForRowAtIndexPath:indexPath];
            //[activeCell.words becomeFirstResponder];
            
            //[self.karaokeTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            //[self tableView:self.karaokeTable didSelectRowAtIndexPath:indexPath];
        }
            break;
            
        case UITableViewCellEditingStyleNone:
        default:
            break;
    }
}


// The editing style for a row is the kind of button displayed to the left of the cell when in editing mode.
- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // No editing style if not editing or the index path is nil.
    if (self.editing == NO || indexPath == nil)
    {
        return UITableViewCellEditingStyleNone;
    }
    
    // Determine the editing style based on whether the cell is a placeholder for adding content or already
    // existing content. Existing content can be deleted.
    NSUInteger row = [indexPath row];
    NSDictionary *rowDict = [self.dataSourceArray objectAtIndex:row];
    assert(rowDict != nil);
    NSString *rowType = [rowDict objectForKey:kTypeKey];
    assert(rowType != nil);
    
    if([rowType isEqualToString:@"Add"])
    {
		return UITableViewCellEditingStyleInsert;
	}
    else
	{
		return UITableViewCellEditingStyleDelete;
	}
    
    return UITableViewCellEditingStyleNone;
}


- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.selectedCellIndex = 0;
    
    self.isEditing = editing;
    if(self.isEditing)
    {
        id obj = [NSDictionary dictionaryWithObjectsAndKeys:@"Add", kTypeKey, nil];
        [self.dataSourceArray addObject:obj];
    }
    else
    {
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"typeKey = 'Add'"];
        NSArray *fakeRowArr = [self.dataSourceArray filteredArrayUsingPredicate:filter];
        if([fakeRowArr count] > 0)
        {
            [self.dataSourceArray removeObject:[fakeRowArr objectAtIndex:0]];
        }
    }
    
    [self.karaokeTable reloadData];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.tableSelection = [indexPath copy];
    NSLog(@"didSelectRowAtIndexPath: %@", self.tableSelection);
    
    tapCount++;
    switch (tapCount)
    {
        case 1: // single tap
            [self performSelector:@selector(singleTap:) withObject:indexPath afterDelay: .4];
            break;
            
        case 2: // double tap
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(singleTap) object:nil];
            [self performSelector:@selector(doubleTap:) withObject:indexPath];
            break;
            
        default:
            break;
    }
}


- (void)singleTap:(NSIndexPath*)rowIndex
{
    tapCount = 0;
    
    NSLog(@"Single tap on row %d", [rowIndex row]);

    self.activeCell = (KaraokeTableCell*)[self.karaokeTable cellForRowAtIndexPath:rowIndex];
}


- (void)doubleTap:(NSIndexPath*)rowIndex
{
    tapCount = 0;
    
    NSLog(@"Double tap on row %d", [rowIndex row]);
    
    self.activeCell = (KaraokeTableCell*)[self.karaokeTable cellForRowAtIndexPath:rowIndex];
    
    if(!self.isEditing)
    {
        [self EditTable:nil];
    }
}

#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // The textfield's superview's superview is TextField Cell
    if([[[textField superview] superview] isKindOfClass:[KaraokeTableCell class]])
    {
        activeCell = (KaraokeTableCell*)[[textField superview] superview];
    }

    editingTextField = textField;
    
    [textField setInputAccessoryView:keyboardToolbar];
}


- (BOOL)textFieldShouldEndEditing:(UITextField*)textField
{
    NSLog(@"textFieldDidEndEditing: %@", textField.text);
/*
    if(textField.tag == 1)
    {
        NSString *text = textField.text;
        if(text.length == 0)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"The Text can't be empty" delegate:self
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            
            [textField becomeFirstResponder];
            return NO;
        }
    }
    else if(textField.tag == 2)
    {
        NSString *text = textField.text;
        double value = [text doubleValue];
        if(text.length == 0 || (value < 0.0 || value > 300))
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"The value for the Time must be defined and between 0 and 300 seconds."
                                                           delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return NO;
        }
    }
*/   
    return YES;
}


- (void)textFieldDidEndEditing:(UITextField*)textField
{
    NSLog(@"textFieldDidEndEditing: %@", textField.text);
    
    NSIndexPath *cellPath = [self.karaokeTable indexPathForCell:activeCell];
    
    if(textField.tag == 1)
    {
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionaryWithDictionary:[self.dataSourceArray objectAtIndex:[cellPath row]]];
        assert(rowDict != nil);
        [rowDict setObject:textField.text forKey:kWordsKey];
        [self.dataSourceArray setObject:[NSDictionary dictionaryWithDictionary:rowDict] atIndexedSubscript:[cellPath row]];
    }
    else if(textField.tag == 2)
    {
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionaryWithDictionary:[self.dataSourceArray objectAtIndex:[cellPath row]]];
        assert(rowDict != nil);
        [rowDict setObject:[NSNumber numberWithDouble:[textField.text doubleValue]] forKey:kTimeKey];
        [self.dataSourceArray setObject:[NSDictionary dictionaryWithDictionary:rowDict] atIndexedSubscript:[cellPath row]];
    }
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    NSLog(@"textFieldShouldReturn: %@", textField.text);
    
    [textField resignFirstResponder];
    
	return YES;
}


- (void)keyboardWillShow:(NSNotification*)note
{
    NSDictionary* info = [note userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.karaokeTable.contentInset = contentInsets;
    self.karaokeTable.scrollIndicatorInsets = contentInsets;
    
    NSIndexPath *addRowPath = [NSIndexPath indexPathForRow:self.tableSelection.row + 1 inSection:0];
    [self.karaokeTable scrollToRowAtIndexPath:addRowPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}


- (void)keyboardWillHide:(NSNotification*)note
{
    [UIView animateWithDuration:.3 animations:^(void)
    {
        self.karaokeTable.contentInset = UIEdgeInsetsZero;
        self.karaokeTable.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}


- (IBAction) EditTable:(id)sender
{
    if(self.tableBarItem.leftBarButtonItem == self.tableBarEditButton)
    {
        [self setEditing:YES];                              // Set the controller as editing
        [self.karaokeTable setEditing:YES animated:YES];    // Set the table editing

        [self.tableBarItem setLeftBarButtonItem:self.tableBarDoneButton];
    }
    else
    {
        [self setEditing:NO];                              // Set the controller as editing
        [self.karaokeTable setEditing:NO animated:YES];    // Set the table editing

        [self.tableBarItem setLeftBarButtonItem:self.tableBarEditButton];
    }
}

@end



