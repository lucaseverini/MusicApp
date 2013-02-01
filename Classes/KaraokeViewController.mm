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

static NSString *kWordsKey = @"wordsKey";
static NSString *kTimeKey = @"timeKey";
static NSString *kViewKey = @"viewKey";
static NSString *kTypeKey = @"typeKey";

static NSMutableArray *gData;

@implementation KaraokeViewController

@synthesize karaokeTable;
@synthesize editText;
@synthesize editTime;
@synthesize addButton;
@synthesize removeButton;
@synthesize backButton;
@synthesize keyboardToolbar;

@synthesize dataSourceArray;
@synthesize selectedCellIndex;
@synthesize isEditing;
@synthesize activeCell;


- (void) viewDidLoad
{
    [super viewDidLoad];
    
    if(gData == nil)
    {
        gData = [[NSMutableArray alloc] init];
        
        id obj = [NSDictionary dictionaryWithObjectsAndKeys:@"Normal", kTypeKey, @"", kWordsKey, [NSNumber numberWithDouble:0.0], kTimeKey, nil];
        [gData addObject:obj];
  	}
    self.dataSourceArray = gData;
    
    self.editing = NO;
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
    if(self.isEditing)
    {
        // Because of how is implemented this table implemented both are needed
        [self setEditing:NO];
        [self.karaokeTable setEditing:YES animated:NO];
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
    
    if(gData == nil)
    {
        [gData release];
        gData = nil;
  	}
    self.dataSourceArray = gData;
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
        cell.words.returnKeyType = UIReturnKeyDone;
        
        cell.time.delegate = self;
        NSNumber *value = [[self.dataSourceArray objectAtIndex: row] valueForKey:kTimeKey];
        cell.time.text = (cell.words.text.length == 0) ? nil : [ value stringValue];
        cell.time.enabled = self.isEditing;
        cell.time.returnKeyType = UIReturnKeyDone;
    }
    
    return cell;
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
            [self.karaokeTable reloadData];
        }
            break;
            
        case UITableViewCellEditingStyleInsert:
        {
            NSLog(@"commitEditingStyle: Insert row %d", [indexPath row]);
            
            id obj = [NSDictionary dictionaryWithObjectsAndKeys:@"Normal", kTypeKey, @"", kWordsKey, [NSNumber numberWithDouble:0.0], kTimeKey, nil];
            [self.dataSourceArray insertObject:obj atIndex:[indexPath row]];
            [self.karaokeTable reloadData];
            
            activeCell = (KaraokeTableCell*)[self.karaokeTable cellForRowAtIndexPath:indexPath];
            
            [activeCell.words becomeFirstResponder];
            
            [self.karaokeTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
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
    
    activeCell = nil;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NSUInteger row = [indexPath row];
    tableSelection = indexPath;
    tapCount++;
    
    switch (tapCount)
    {
        case 1: // single tap
            [self performSelector:@selector(singleTap) withObject: nil afterDelay: .4];
            break;
            
        case 2: // double tap
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(singleTap) object:nil];
            [self performSelector:@selector(doubleTap) withObject: nil];
            break;
            
        default:
            break;
    }
    
    // we row this to top
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}


- (void)singleTap
{
    tapCount = 0;
    
    NSUInteger row = [tableSelection row];
    NSLog(@"Single tap on row %d", row);
}


- (void)doubleTap
{
    tapCount = 0;
    
    NSUInteger row = [tableSelection row];
    NSLog(@"Double tap on row %d", row);
    
    // Because of how is implemented this table implemented both are needed
    [self setEditing:YES];                              // Set the controller as editing
    [self.karaokeTable setEditing:YES animated:YES];    // Set the table editing
}

#pragma mark - UITextField Delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    // The textfield's superview's superview is TextField Cell
    if([[[textField superview] superview] isKindOfClass:[KaraokeTableCell class]])
    {
        activeCell = (KaraokeTableCell*)[[textField superview] superview];
    }
    
    textField.inputAccessoryView = keyboardToolbar;
    
    return YES;
}


- (BOOL)textFieldShouldEndEditing:(UITextField*)textField
{
    NSLog(@"textFieldDidEndEditing: %@", textField.text);
    
    NSString *text = textField.text;
    
    if(textField.tag == 1)
    {
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
        double value = [text doubleValue];
        if(text.length == 0 || (value < 0.0 || value > 300))
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!" message:@"The Time must be defined and between 0 and 300 seconds." delegate:self
                                                  cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            return NO;
        }
    }
    
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


@end


