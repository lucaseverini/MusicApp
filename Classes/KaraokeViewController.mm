//
//  KaraokeViewController.mm
//  MusicApp
//
//  Created by Luca Severini on 22/1/20132.
//

#import <UIKit/UIKit.h>
#import "KaraokeViewController.h"
#import "Karaoke.h"
#import "KaraokeTableCell.h"
#import "KeyboardToolbarController.h"
#import "ActionSheetStringPicker.h"

@implementation KaraokeViewController

@synthesize tableBar;
@synthesize tableBarItem;
@synthesize tableBarEditButton;
@synthesize tableBarDoneButton;
@synthesize karaokeTable;
@synthesize backButton;
@synthesize keyboardToolbar;
@synthesize keyboardController;
@synthesize karaokeTitle;
@synthesize loadFileButton;
@synthesize saveFileButton;
@synthesize deleteFileButton;
@synthesize lyricsButtonNew;
@synthesize lyricsButtonCopy;
@synthesize lyricsButtonPaste;
@synthesize lyricsButtonDelete;
@synthesize userDocDirPath;

@synthesize tableSelection;
@synthesize dataSourceArray;
@synthesize isEditing;
@synthesize activeCell;


- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
		self.userDocDirPath = [paths objectAtIndex:0];
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
    
	[dataSourceArray insertObject:karaokeTitle.text atIndex:0];	// Insert title in array as first element
	
	if([dataSourceArray writeToFile:filePath atomically:YES])
	{
		NSLog(@"File %@ written", filePath);
	}
	else
	{
		NSLog(@"File %@ not written", filePath);
	}
    
	[dataSourceArray release];
    dataSourceArray = nil;
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
        
        self.dataSourceArray = [NSMutableArray arrayWithContentsOfFile:filePath];
		
		NSString *title = [dataSourceArray objectAtIndex:0];
		if(title == nil || ![title isKindOfClass:[NSString class]] || title.length == 0)
		{
			karaokeTitle.text = @"Untitled";
		}
		else
		{
			karaokeTitle.text = title;
		}

		if([title isKindOfClass:[NSString class]])
		{
			[dataSourceArray removeObjectAtIndex:0];
		}
	}
    else
    {
        NSLog(@"File %@ is missing", filePath);

        self.dataSourceArray = [NSMutableArray array];
    }
    
    self.editing = NO;
    
    [tableBarItem setLeftBarButtonItem:tableBarEditButton];
    
    keyboardController.hideDoneButton = YES;
}


- (IBAction) goBack:(id)sender
{
    // Because of how is implemented this table implemented both are needed
    [self setEditing:NO];
    [karaokeTable setEditing:NO animated:NO];
    
    // Custom animated transition
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration: 0.5];    
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view.window cache:YES];

    [self dismissViewControllerAnimated:NO completion:nil];  // Return back to parent view

    [UIView commitAnimations];  // Play the animation
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
    return [dataSourceArray count];
}


- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    KaraokeTableCell *cell = nil;
    
    NSUInteger row = [indexPath row];
    
    NSDictionary *rowDict = [dataSourceArray objectAtIndex:row];
    assert(rowDict != nil);
    
    NSString *rowType = [rowDict objectForKey:kTypeKey];
    assert(rowType != nil);
    
    if([rowType isEqualToString:@"Add"])
    {
        NSString *cellTextFieldID = @"addCell_ID";
        cell = (KaraokeTableCell*) [tableView dequeueReusableCellWithIdentifier:cellTextFieldID];
        if(cell == nil)
        {
            // A new cell needs to be created
            UITableViewCellStyle cellStyle = 100;
            cell = [[[KaraokeTableCell alloc] initWithStyle:cellStyle reuseIdentifier:cellTextFieldID] autorelease];
        }
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.tag = -1;
    }
    else
    {
		NSString *cellTextFieldID = @"realCell_ID";
        cell = (KaraokeTableCell*) [tableView dequeueReusableCellWithIdentifier:cellTextFieldID];
        if(cell == nil)
        {
            // A new cell needs to be created
            UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
            cell = [[[KaraokeTableCell alloc] initWithStyle:cellStyle reuseIdentifier:cellTextFieldID] autorelease];
        }
        
 		cell.tag = row;		
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.words.delegate = self;
        cell.words.text = [[dataSourceArray objectAtIndex: row] valueForKey:kWordsKey];
        cell.words.enabled = self.isEditing;
        cell.words.returnKeyType = UIReturnKeyDefault;
        
        cell.time.delegate = self;
        NSNumber *value = [[dataSourceArray objectAtIndex: row] valueForKey:kTimeKey];
        cell.time.text = (cell.words.text.length == 0) ? nil : [value stringValue];
        cell.time.enabled = self.isEditing;
        cell.time.returnKeyType = UIReturnKeyDefault;
    }
    
    return cell;
}


#pragma mark - doPrevTextField
- (IBAction) doPrevTextField:(id)sender
{
	if(dataSourceArray.count == 1)
	{
		return;
	}
	
	KaraokeTableCell *curCell = (KaraokeTableCell*)[[editingTextField superview] superview];
	NSIndexPath *curCellPath = [NSIndexPath indexPathForRow:curCell.tag inSection:0];

    if(editingTextField.tag == 1)	// Words field
    {
		NSInteger newRow = curCellPath.row > 0 ? curCellPath.row - 1 : dataSourceArray.count - 1;
		NSString *rowType = [[dataSourceArray objectAtIndex:newRow] objectForKey:kTypeKey];
		while([rowType isEqualToString:@"Add"])
		{
			if(--newRow < 0)
			{
				newRow = dataSourceArray.count - 1;
			}
			rowType = [[dataSourceArray objectAtIndex:newRow] objectForKey:kTypeKey];
		}
		
		NSIndexPath *newSelection = [NSIndexPath indexPathForRow:newRow inSection:0];

		NSArray *visibleCells = [karaokeTable indexPathsForVisibleRows];
		if(![visibleCells containsObject:newSelection])
		{
			[karaokeTable scrollToRowAtIndexPath:newSelection atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
		}
        
        [karaokeTable selectRowAtIndexPath:newSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:karaokeTable didSelectRowAtIndexPath:newSelection];
		
		self.activeCell = (KaraokeTableCell*)[karaokeTable cellForRowAtIndexPath:newSelection];
		
        [activeCell.time becomeFirstResponder];
    }
    else if(editingTextField.tag == 2)	// Time field
    {
		NSArray *visibleCells = [karaokeTable indexPathsForVisibleRows];
		if(![visibleCells containsObject:curCellPath])
		{
			[karaokeTable scrollToRowAtIndexPath:curCellPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
		}
		
		[karaokeTable selectRowAtIndexPath:curCellPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
		[self tableView:karaokeTable didSelectRowAtIndexPath:curCellPath];

		self.activeCell = (KaraokeTableCell*)[karaokeTable cellForRowAtIndexPath:curCellPath];
		
        [activeCell.words becomeFirstResponder];
    }
}

#pragma mark - doNextTextField
- (IBAction) doNextTextField:(id)sender
{
	if(dataSourceArray.count == 1)
	{
		return;
	}

	KaraokeTableCell *curCell = (KaraokeTableCell*)[[editingTextField superview] superview];
	NSIndexPath *curCellPath = [NSIndexPath indexPathForRow:curCell.tag inSection:0];

    if(editingTextField.tag == 1)	// Words field
    {
		NSArray *visibleCells = [karaokeTable indexPathsForVisibleRows];
		if(![visibleCells containsObject:curCellPath])
		{
			[karaokeTable scrollToRowAtIndexPath:curCellPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
		}

		[karaokeTable selectRowAtIndexPath:curCellPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
		[self tableView:karaokeTable didSelectRowAtIndexPath:curCellPath];

		self.activeCell = (KaraokeTableCell*)[karaokeTable cellForRowAtIndexPath:curCellPath];
		
        [activeCell.time becomeFirstResponder];
    }
    else if(editingTextField.tag == 2)	// Time field
    {
		NSInteger newRow = curCellPath.row < dataSourceArray.count - 1 ? curCellPath.row + 1 : 0;
		NSString *rowType = [[dataSourceArray objectAtIndex:newRow] objectForKey:kTypeKey];
		while([rowType isEqualToString:@"Add"])
		{
			if(++newRow >= dataSourceArray.count - 1)
			{
				newRow = 0;
			}
			rowType = [[dataSourceArray objectAtIndex:newRow] objectForKey:kTypeKey];
		}
		
		NSIndexPath *newSelection = [NSIndexPath indexPathForRow:newRow inSection:0];
		
		NSArray *visibleCells = [karaokeTable indexPathsForVisibleRows];
		if(![visibleCells containsObject:newSelection])
		{
			[karaokeTable scrollToRowAtIndexPath:newSelection atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
		}
        
        [karaokeTable selectRowAtIndexPath:newSelection animated:YES scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:karaokeTable didSelectRowAtIndexPath:newSelection];
		
		self.activeCell = (KaraokeTableCell*)[karaokeTable cellForRowAtIndexPath:newSelection];
		
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


- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NSUInteger row = [indexPath row];
    
    BOOL result = self.isEditing;
    
    return result;
}


- (BOOL) tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NSUInteger row = [indexPath row];
    
    BOOL result = self.isEditing;
    
    return result;
}


- (void) tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if([sourceIndexPath row] != [destinationIndexPath row])
    {
        NSLog(@"moveRowAtIndexPath from %d to %d", [sourceIndexPath row], [destinationIndexPath row]);
        
        [dataSourceArray exchangeObjectAtIndex:[sourceIndexPath row] withObjectAtIndex:[destinationIndexPath row]];
    }
}


- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(editingStyle)
    {
        case UITableViewCellEditingStyleDelete:
        {
            NSLog(@"commitEditingStyle: Delete row %d", [indexPath row]);
            
            [dataSourceArray removeObjectAtIndex:[indexPath row]];

            if([indexPath row] == [karaokeTable indexPathForCell:activeCell].row)
            {
                if(self.isEditing)
                {
                    [karaokeTable reloadData];
                }
            }
            else
            {
                NSArray *rowArray = [NSArray arrayWithObject:indexPath];
                [karaokeTable deleteRowsAtIndexPaths:rowArray withRowAnimation:UITableViewRowAnimationMiddle];
            }
        }
            break;
            
        case UITableViewCellEditingStyleInsert:
        {
            NSLog(@"commitEditingStyle: Insert row %d", [indexPath row]);
            
            id obj = [NSDictionary dictionaryWithObjectsAndKeys:@"Normal", kTypeKey, @"", kWordsKey, [NSNumber numberWithDouble:0.0], kTimeKey, nil];
            [dataSourceArray insertObject:obj atIndex:[indexPath row]];
            
            NSArray *rowArray = [NSArray arrayWithObject:indexPath];
            [karaokeTable insertRowsAtIndexPaths:rowArray withRowAnimation:UITableViewRowAnimationMiddle];
            
            //self.activeCell = (KaraokeTableCell*)[karaokeTable cellForRowAtIndexPath:indexPath];
            //[activeCell.words becomeFirstResponder];
            
            //[karaokeTable selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            //[self tableView:karaokeTable didSelectRowAtIndexPath:indexPath];
        }
            break;
            
        case UITableViewCellEditingStyleNone:
        default:
            break;
    }
}


// The editing style for a row is the kind of button displayed to the left of the cell when in editing mode.
- (UITableViewCellEditingStyle) tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // No editing style if not editing or the index path is nil.
    if (self.editing == NO || indexPath == nil)
    {
        return UITableViewCellEditingStyleNone;
    }
    
    // Determine the editing style based on whether the cell is a placeholder for adding content or already
    // existing content. Existing content can be deleted.
    NSUInteger row = [indexPath row];
    NSDictionary *rowDict = [dataSourceArray objectAtIndex:row];
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


- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.isEditing = editing;
    if(self.isEditing)
    {
        id obj = [NSDictionary dictionaryWithObjectsAndKeys:@"Add", kTypeKey, nil];
        [dataSourceArray addObject:obj];
    }
    else
    {
        NSPredicate *filter = [NSPredicate predicateWithFormat:@"typeKey = 'Add'"];
        NSArray *fakeRowArr = [dataSourceArray filteredArrayUsingPredicate:filter];
        if([fakeRowArr count] > 0)
        {
            [dataSourceArray removeObject:[fakeRowArr objectAtIndex:0]];
        }
    }
    
    [karaokeTable reloadData];
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *rowDict = [dataSourceArray objectAtIndex:[indexPath row]];
    assert(rowDict != nil);
    NSString *rowType = [rowDict objectForKey:kTypeKey];
    assert(rowType != nil);    
    if([rowType isEqualToString:@"Add"])
    {
		return;		// Don't select the placeholder row for inserting new rows
	}

    self.tableSelection = indexPath;
  
    switch (++tapCount)
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


- (void) singleTap:(NSIndexPath*)rowIndex
{
    tapCount = 0;
    
    // NSLog(@"Single tap on row %d", [rowIndex row]);
	
	self.activeCell = (KaraokeTableCell*)[karaokeTable cellForRowAtIndexPath:rowIndex];
}


- (void) doubleTap:(NSIndexPath*)rowIndex
{
    tapCount = 0;
    
    // NSLog(@"Double tap on row %d", [rowIndex row]);
    
    self.activeCell = (KaraokeTableCell*)[karaokeTable cellForRowAtIndexPath:rowIndex];
    
    if(!self.isEditing)
    {
        [self editTable:nil];
    }
}

#pragma mark - UITextField Delegate methods

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
/*
    if([[[textField superview] superview] isKindOfClass:[KaraokeTableCell class]])
    {
        KaraokeTableCell *cell = (KaraokeTableCell*)[[textField superview] superview];
		NSIndexPath *cellPath = [karaokeTable indexPathForCell:cell];
		[karaokeTable selectRowAtIndexPath:cellPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
		[self tableView:karaokeTable didSelectRowAtIndexPath:cellPath];
	}
*/
    return YES;
}


- (void) textFieldDidBeginEditing:(UITextField *)textField
{
	KaraokeTableCell *curCell = (KaraokeTableCell*)[[textField superview] superview];
	NSIndexPath *curCellPath = [NSIndexPath indexPathForRow:curCell.tag inSection:0];
	
	NSArray *visibleCells = [karaokeTable indexPathsForVisibleRows];
	if(![visibleCells containsObject:curCellPath])
	{
		[karaokeTable scrollToRowAtIndexPath:curCellPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
	}
	
	[karaokeTable selectRowAtIndexPath:curCellPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
	[self tableView:karaokeTable didSelectRowAtIndexPath:curCellPath];
		
    editingTextField = textField;
    
    [textField setInputAccessoryView:keyboardToolbar];
}


- (BOOL) textFieldShouldEndEditing:(UITextField*)textField
{
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


- (void) textFieldDidEndEditing:(UITextField*)textField
{
	KaraokeTableCell *cell = (KaraokeTableCell*)[[textField superview] superview];
    NSIndexPath *cellPath = [NSIndexPath indexPathForRow:cell.tag inSection:0];
	assert(cellPath != nil);

	if(textField.tag == 1)
    {
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionaryWithDictionary:[dataSourceArray objectAtIndex:[cellPath row]]];
        assert(rowDict != nil);
		if(![textField.text isEqualToString:[rowDict objectForKey:kWordsKey]])
		{
			[rowDict setObject:textField.text forKey:kWordsKey];
			[dataSourceArray setObject:[NSDictionary dictionaryWithDictionary:rowDict] atIndexedSubscript:[cellPath row]];
		}
    }
    else if(textField.tag == 2)
    {
        NSMutableDictionary *rowDict = [NSMutableDictionary dictionaryWithDictionary:[dataSourceArray objectAtIndex:[cellPath row]]];
        assert(rowDict != nil);
		NSString *timeStr = [[rowDict objectForKey:kTimeKey] stringValue];
		if(![textField.text isEqualToString:timeStr])
		{
			[rowDict setObject:[NSNumber numberWithDouble:[textField.text doubleValue]] forKey:kTimeKey];
			[dataSourceArray setObject:[NSDictionary dictionaryWithDictionary:rowDict] atIndexedSubscript:[cellPath row]];
		}
    }
}


- (BOOL) textFieldShouldReturn:(UITextField*)textField
{
    NSLog(@"textFieldShouldReturn: %@", textField.text);
    
    [textField resignFirstResponder];
    
	return YES;
}


- (void) keyboardWillShow:(NSNotification*)note
{
    NSDictionary* info = [note userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    karaokeTable.contentInset = contentInsets;
    karaokeTable.scrollIndicatorInsets = contentInsets;
    
    [karaokeTable scrollToRowAtIndexPath:tableSelection atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}


- (void) keyboardWillHide:(NSNotification*)note
{
    [UIView animateWithDuration:.3 animations:^(void)
    {
        karaokeTable.contentInset = UIEdgeInsetsZero;
        karaokeTable.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}


- (IBAction) editTable:(id)sender
{
    if(tableBarItem.leftBarButtonItem == tableBarEditButton)
    {
        [self setEditing:YES];                              // Set the controller as editing
        [karaokeTable setEditing:YES animated:YES];    // Set the table editing

        [tableBarItem setLeftBarButtonItem:tableBarDoneButton];
        
        backButton.enabled = NO;

		loadFileButton.hidden = YES;
		saveFileButton.hidden = YES;
		deleteFileButton.hidden = YES;

		lyricsButtonNew.hidden = NO;
		lyricsButtonCopy.hidden = NO;
		lyricsButtonPaste.hidden = NO;
 		lyricsButtonDelete.hidden = NO;
		
		self.tableSelection = nil;
	}
    else
    {
        [self setEditing:NO];                              // Set the controller as editing
        [karaokeTable setEditing:NO animated:YES];    // Set the table editing

        [tableBarItem setLeftBarButtonItem:tableBarEditButton];

        backButton.enabled = YES;

		loadFileButton.hidden = NO;
		saveFileButton.hidden = NO;
		deleteFileButton.hidden = NO;
		
		lyricsButtonNew.hidden = YES;
		lyricsButtonCopy.hidden = YES;
		lyricsButtonPaste.hidden = YES;
 		lyricsButtonDelete.hidden = YES;
	}
}


- (IBAction) doSaveLyricsFile:(id)sender
{
	UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Save Lyric" message:@"Please enter Title and Author" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
	alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput; // Two edit fields
	
	UITextField * titleTextField = [alert textFieldAtIndex:0];
	titleTextField.keyboardType = UIKeyboardTypeDefault;
	titleTextField.placeholder = @"Title";
	
	UITextField * artistTextField = [alert textFieldAtIndex:1];
	[artistTextField setSecureTextEntry:NO];
	artistTextField.keyboardType = UIKeyboardTypeDefault;
	artistTextField.placeholder = @"Artist";
	
	[alert show];
	[alert release];
}


- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	if(buttonIndex == 0)
	{
		return;
	}
	
	NSFileManager *fileMgr = [NSFileManager defaultManager];
/*
	 NSString *folderPath = [userDocDirPath stringByAppendingPathComponent:@"Lyrics"];
	 if(![fileMgr fileExistsAtPath:folderPath])
	 {
		 if(![fileMgr createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:nil])
		 {
		 NSLog(@"Can't create folder %@", folderPath);
		 return;
		 }
	 }
*/
	NSString *title = [alertView textFieldAtIndex:0].text;
	NSString *artist = [alertView textFieldAtIndex:1].text;
	NSData *fileContent = [self lyricsToFileData:dataSourceArray title:title artist:artist];
	
	NSString *fileName = [NSString stringWithFormat:@"%@.lrc", title];
	NSString *filePath = [userDocDirPath stringByAppendingPathComponent:fileName];
	if(![fileMgr createFileAtPath:filePath contents:fileContent attributes:nil])
	{
		NSLog(@"Can't create file %@", filePath);
		return;
	}
	
	karaokeTitle.text = title;
}


- (BOOL) alertViewShouldEnableFirstOtherButton:(UIAlertView*)alertView
{
    NSString *input = [[alertView textFieldAtIndex:0] text];
    if([input length] < 1 || [input length] > 50)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


- (IBAction) doLoadLyricsFile:(id)sender
{
	lyricFiles = [NSMutableArray array];
	NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:userDocDirPath error:nil];
	for(NSString *file in dirContent)
	{
		if([[file pathExtension] compare:@"lrc" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		{
			[lyricFiles  addObject:[file stringByDeletingPathExtension]];
		}
	}
	
    ActionSheetStringPicker *action = [[ActionSheetStringPicker alloc] initWithTitle:@"Select Lyrics File" rows:lyricFiles initialSelection:0 target:self successAction:@selector(lyricsFileSelected:reference:) cancelAction:nil origin:sender];
	action.doneButtonTitle = @"Load";
	[action showActionSheetPicker];
}


- (void) lyricsFileSelected:(NSNumber*)selectedIndex reference:(id)reference
{
	if(reference == loadFileButton)
	{
		NSString *lyricTitle = [lyricFiles objectAtIndex:[selectedIndex integerValue]];	
		karaokeTitle.text = lyricTitle;
		
		NSString *lyricFile = [NSString stringWithFormat:@"%@.lrc", lyricTitle];		
		if([self fileDataToLyrics:lyricFile])
		{
			NSLog(@"Loaded lyrics file %@", lyricFile);
		}
	}
	else if(reference == deleteFileButton)
	{
 		NSString *lyricFile = [NSString stringWithFormat:@"%@.lrc", [lyricFiles objectAtIndex:[selectedIndex integerValue]]];
		NSString *filePath = [userDocDirPath stringByAppendingPathComponent:lyricFile];
		if([[NSFileManager defaultManager] removeItemAtPath:filePath error:nil])
		{
			NSLog(@"Deleted lyrics file %@", lyricFile);
		}
	}
}


- (BOOL) fileDataToLyrics:(NSString*)fileName
{
	NSMutableArray *lyrics = [NSMutableArray array];
	
	NSString *filePath = [userDocDirPath stringByAppendingPathComponent:fileName];
	NSString *fileData = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	
	NSMutableCharacterSet *validCharsSet = [NSMutableCharacterSet alphanumericCharacterSet];
	[validCharsSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
	[validCharsSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
	[validCharsSet removeCharactersInString:@"] "];
		
	NSDateFormatter *dateReader = [[[NSDateFormatter alloc] init] autorelease];
	[dateReader setDateFormat:@"mm:ss:SS"];
	NSDate *startDate = [dateReader dateFromString:@"00:00:00"];
	
	NSArray *rows = [fileData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for(NSString *row in rows)
	{
		if(row.length == 0)
		{
			continue;
		}
		
		// NSLog(@"%@", row);

		NSScanner *rowScan = [NSScanner scannerWithString:row];
		NSString *timeStr = nil;
		NSTimeInterval time = 0.0;
		NSString *words = nil;
		
		if([row characterAtIndex:0] == '[')
		{
			[rowScan setScanLocation:1];
			[rowScan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"]"] intoString:&timeStr];
			if([row characterAtIndex:[rowScan scanLocation]] == ']')
			{
				[rowScan scanUpToCharactersFromSet:validCharsSet intoString:nil];
			}
			else
			{
				time = nil;
			}
		}

		if(timeStr != nil)
		{
			// Ignore all tag defined (checked on wikipedia "LRC (file format)" article)
			if([timeStr rangeOfString:@"ar:"].location == 0 ||
			   [timeStr rangeOfString:@"al:"].location == 0 ||
			   [timeStr rangeOfString:@"ti:"].location == 0 ||
			   [timeStr rangeOfString:@"au:"].location == 0 ||
			   [timeStr rangeOfString:@"length:"].location == 0 ||
			   [timeStr rangeOfString:@"by:"].location == 0 ||
			   [timeStr rangeOfString:@"offset:"].location == 0 ||
			   [timeStr rangeOfString:@"re:"].location == 0 ||
			   [timeStr rangeOfString:@"ve:"].location == 0)
			{
				[rowScan scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&words];
			}
			else
			{
				// Convert timeStr to NSTimeInterval
				NSDate *date = [dateReader dateFromString:timeStr];
				if(date != nil)
				{
					time = [date timeIntervalSinceDate:startDate];
					
					[rowScan scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&words];
				}
				else
				{
					words = row;
				}
			}
		}
		else
		{
			words = row;
		}
		
		if((words == nil || words.length == 0) && (row != [rows lastObject]))
		{
			continue;
		}
		
		words = [words stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		// NSLog(@"time:%g words:%@", time, words);
		NSDictionary *lyric = [NSDictionary dictionaryWithObjectsAndKeys:@"Normal", kTypeKey, [NSNumber numberWithFloat:time], kTimeKey, words, kWordsKey, nil];
		[lyrics addObject:lyric];
	}
	
	self.dataSourceArray = lyrics;
	[karaokeTable reloadData];
	
	return (lyrics.count > 0);
}


- (BOOL) stringToLyrics:(NSString*)string
{	
	NSMutableArray *lyrics = [NSMutableArray array];
	
	NSMutableCharacterSet *validCharsSet = [NSMutableCharacterSet alphanumericCharacterSet];
	[validCharsSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
	[validCharsSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
	[validCharsSet removeCharactersInString:@"] "];
	
	NSDateFormatter *dateReader = [[[NSDateFormatter alloc] init] autorelease];
	[dateReader setDateFormat:@"mm:ss:SS"];
	NSDate *startDate = [dateReader dateFromString:@"00:00:00"];
	
	NSArray *rows = [string componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	for(NSString *row in rows)
	{
		if(row.length == 0)
		{
			continue;
		}
		
		// NSLog(@"%@", row);
		
		NSScanner *rowScan = [NSScanner scannerWithString:row];
		NSString *timeStr = nil;
		NSTimeInterval time = 0.0;
		NSString *words = nil;
		
		if([row characterAtIndex:0] == '[')
		{
			[rowScan setScanLocation:1];
			[rowScan scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"]"] intoString:&timeStr];
			if([row characterAtIndex:[rowScan scanLocation]] == ']')
			{
				[rowScan scanUpToCharactersFromSet:validCharsSet intoString:nil];
			}
			else
			{
				time = nil;
			}
		}
		
		if(timeStr != nil)
		{
			// Ignore all tag defined (checked on wikipedia "LRC (file format)" article)
			if([timeStr rangeOfString:@"ar:"].location == 0 ||
			   [timeStr rangeOfString:@"al:"].location == 0 ||
			   [timeStr rangeOfString:@"ti:"].location == 0 ||
			   [timeStr rangeOfString:@"au:"].location == 0 ||
			   [timeStr rangeOfString:@"length:"].location == 0 ||
			   [timeStr rangeOfString:@"by:"].location == 0 ||
			   [timeStr rangeOfString:@"offset:"].location == 0 ||
			   [timeStr rangeOfString:@"re:"].location == 0 ||
			   [timeStr rangeOfString:@"ve:"].location == 0)
			{
				[rowScan scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&words];
			}
			else
			{
				// Convert timeStr to NSTimeInterval
				NSDate *date = [dateReader dateFromString:timeStr];
				if(date != nil)
				{
					time = [date timeIntervalSinceDate:startDate];
					
					[rowScan scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:&words];
				}
				else
				{
					words = row;
				}
			}
		}
		else
		{
			words = row;
		}
		
		if((words == nil || words.length == 0) && (row != [rows lastObject]))
		{
			continue;
		}
		
		words = [words stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		
		// NSLog(@"time:%g words:%@", time, words);
		NSDictionary *lyric = [NSDictionary dictionaryWithObjectsAndKeys:@"Normal", kTypeKey, [NSNumber numberWithFloat:time], kTimeKey, words, kWordsKey, nil];
		[lyrics addObject:lyric];
	}
	
	NSInteger insertRow = 0;
	if(tableSelection != nil)
	{
		insertRow = tableSelection.row;
	}
	else
	{
		for(NSDictionary *row in dataSourceArray)
		{
			if([[row objectForKey:kTypeKey] isEqualToString:@"Add"])
			{
				break;
			}
			
			insertRow++;
		}
	}
		
	for(NSDictionary *row in lyrics)
	{
		[dataSourceArray insertObject:row atIndex:insertRow++];
	}
	
	[karaokeTable reloadData];
	
	return (lyrics.count > 0);
}


- (NSData*) lyricsToFileData:(NSArray*)lyricsArray title:(NSString*)title artist:(NSString*)artist
{
	NSMutableData *fileData = [NSMutableData data];

	if([title length] > 0)
	{
		NSString *rowStr = [NSString stringWithFormat:@"[ti:%@]\r", title];
		[fileData appendData:[rowStr dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	if([artist length] > 0)
	{
		NSString *rowStr = [NSString stringWithFormat:@"[ar:%@]\r", artist];
		[fileData appendData:[rowStr dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	NSDateFormatter *timeFormat = [[[NSDateFormatter alloc] init] autorelease];
	[timeFormat setDateFormat:@"mm:ss:SS"];
	
	NSDateFormatter *dateReader = [[[NSDateFormatter alloc] init] autorelease];
	[dateReader setDateFormat:@"hh:mm:ss"];
	NSDate *startDate = [dateReader dateFromString:@"00:00:00"];

	for(NSDictionary *lyricDict in lyricsArray)
	{
		NSString *type = [lyricDict objectForKey:kTypeKey];
		if([type isEqualToString:@"Add"])
		{
			continue;
		}
		
		float seconds = [[lyricDict objectForKey:kTimeKey] floatValue];
		NSString *words = [lyricDict objectForKey:kWordsKey];
		
		NSDate *time = [startDate dateByAddingTimeInterval:seconds];
		NSString *timeStr = [timeFormat stringFromDate:time];
		
		NSString *rowStr = [NSString stringWithFormat:@"[%@] %@\r", timeStr, words];
		[fileData appendData:[rowStr dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	return fileData;
}


- (IBAction) doDeleteLyricsFile:(id)sender
{
	lyricFiles = [NSMutableArray array];
	NSArray *dirContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:userDocDirPath error:nil];
	for(NSString *file in dirContent)
	{
		if([[file pathExtension] compare:@"lrc" options:NSCaseInsensitiveSearch] == NSOrderedSame)
		{
			[lyricFiles  addObject:[file stringByDeletingPathExtension]];
		}
	}
	
    ActionSheetStringPicker *action = [[ActionSheetStringPicker alloc] initWithTitle:@"Select Lyrics File" rows:lyricFiles initialSelection:0 target:self successAction:@selector(lyricsFileSelected:reference:) cancelAction:nil origin:sender];
	action.doneButtonTitle = @"Delete";
	[action showActionSheetPicker];
}


- (IBAction) doNewLyrics:(id)sender
{
	karaokeTitle.text = @"Untitled";

	[dataSourceArray removeAllObjects];
	[dataSourceArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Add", kTypeKey, nil]];
	[karaokeTable reloadData];
}


- (IBAction) doCopyLyrics:(id)sender
{
	NSData *content = [self lyricsToFileData:dataSourceArray title:nil artist:nil];
	NSString *strData = [[[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding] autorelease];
	
	UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
	[pasteBoard setString:strData];
	
	NSLog(@"Copied to clipboard:\r%@", strData);
}


- (IBAction) doPasteLyrics:(id)sender
{
	UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
	NSString *strData = [pasteBoard string];
	
	if([self stringToLyrics:strData])
	{
		NSLog(@"Pasted from clipboard:\r%@", strData);
	}
}


- (IBAction) doDeleteLyrics:(id)sender
{
	[dataSourceArray removeAllObjects];
	[dataSourceArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"Add", kTypeKey, nil]];
	[karaokeTable reloadData];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}


// Override to allow orientations other than the default portrait orientation.
// Called if iOS >= 6
- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


// Called if iOS >= 6
- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end



