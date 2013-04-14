//
//  FileTableController.m
//  MusicApp
//
//  Created by Luca Severini on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileTableController.h"


@interface UIView (GetController)

- (UIViewController*) viewController;

@end

@implementation UIView (GetController)

- (UIViewController*) viewController;
{
    id nextResponder = [self nextResponder];
    if([nextResponder isKindOfClass:[UIViewController class]]) 
    {
        return nextResponder;
    } 
    else 
    {
        return nil;
    }
}

@end


@implementation FileTableController

@synthesize tabView;


- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 8;
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

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *channelDict = [defaults objectForKey:[NSString stringWithFormat:@"Channel-%d", cellIdx + 1]];
    if(channelDict != nil && [channelDict objectForKey:@"AudioTitle"] != nil) 
    {        
        NSString *text = [[NSString alloc ] initWithFormat:@"%@ (%.1f secs)", [channelDict objectForKey:@"AudioTitle"], [[channelDict objectForKey:@"AudioDuration"] doubleValue]];
 
        cell.tag = 1;
        cell.textLabel.text = text;
        cell.textLabel.textColor = [UIColor blackColor];
        
        // cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    else 
    {
        cell.tag = 0;
        cell.textLabel.text = [NSString stringWithFormat:@"Track %d", cellIdx + 1];
        cell.textLabel.textColor = [UIColor lightGrayColor];
        
        // cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }

    return cell;
}


- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
}


- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath 
{
    UIViewController *parentViewController = [[[self tableView] superview] viewController];
    [parentViewController performSelector:@selector(doSelectFile:) withObject:[indexPath retain]];
}


// Override to support conditional editing of the table view.
// This only needs to be implemented if you are going to be returning NO
// for some items. By default, all items are editable.
- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath 
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *channelDict = [defaults objectForKey:[NSString stringWithFormat:@"Channel-%d", [indexPath row] + 1]];
    if(channelDict != nil && [channelDict objectForKey:@"AudioTitle"] != nil) 
    {        
        return YES;     // Return YES if you want the specified item to be editable/deletable.
    }
    else
    {
        return NO;
    }
}

/*
- (BOOL) tableView:(UITableView*)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath*)indexPath 
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *channelDict = [defaults objectForKey:[NSString stringWithFormat:@"Channel-%d", [indexPath row] + 1]];
    if(channelDict != nil && [channelDict objectForKey:@"AudioTitle"] != nil) 
    {        
        return YES;     // Return YES if you want the specified item to be changeable for the position.
    }
    else
    {
        return NO;
    }
}


- (BOOL) tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{ 
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *channelDict = [defaults objectForKey:[NSString stringWithFormat:@"Channel-%d", [indexPath row] + 1]];
    if(channelDict != nil && [channelDict objectForKey:@"AudioTitle"] != nil) 
    {        
        return YES;     // Return YES if you want the specified item to be changeable for the position.
    }
    else
    {
        return NO;
    }
}
*/

// ***
// Why the first tap on the list is lost after the delete button is showed? Bug?
// ***
- (void) tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete) 
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];    
        NSDictionary *channelDict = [NSDictionary dictionaryWithObjectsAndKeys:nil, @"AudioUrl", nil, @"AudioTitle", nil, @"AudioDuration", nil, @"AudioVolume", nil];     
        [defaults setObject:channelDict forKey:[NSString stringWithFormat:@"Channel-%d", [indexPath row] + 1]];
        [defaults synchronize];
		 
		NSArray *indexes = [NSArray arrayWithObject:indexPath];
        [tableView reloadRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
    }    
}

/*
- (NSIndexPath*) tableView:(UITableView*)tableView willSelectRowAtIndexPath:(NSIndexPath*)indexPath;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *channelDict = [defaults objectForKey:[NSString stringWithFormat:@"Channel-%d", [indexPath row] + 1]];
    if(channelDict != nil && [channelDict objectForKey:@"AudioTitle"] != nil) 
    {        
        return nil;     // Not selectable
    }
    else
    {
        return indexPath;
    }
}
*/

@end
