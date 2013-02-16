//
//  SettingsViewController.h
//  MusicApp
//
//  Created by Luca Severini on 14/1/2012.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"
#import "SelectionViewController.h"
#import "KaraokeViewController.h"


@implementation SettingsViewController

@synthesize backButton;
@synthesize goKaraokeButton;
@synthesize goSelectionButton;
@synthesize versionLabel;

- (void) viewDidLoad
{        
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDict objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];    
    versionLabel.text = [NSString stringWithFormat:@"%@ %@", appName, appVersion];
}


- (void) viewWillDisappear:(BOOL)animated
{
    NSLog(@"viewWillDisappear");
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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


- (IBAction) goBack:(UIButton*)sender
{
    // Custom animated transition
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration: 0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view.window cache:YES];
    
    [self dismissViewControllerAnimated:NO completion:nil];  // Return back to parent view
    
    [UIView commitAnimations];  // Play the animation
}


- (IBAction) goKaraoke:(UIButton*)sender
{
    KaraokeViewController *karaoke = [[[KaraokeViewController alloc] initWithNibName:@"KaraokeView" bundle:nil] autorelease];
    assert(karaoke != nil);
    
    // Custom animated transition
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration: 0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view.window cache:YES];
    
    [self presentViewController:karaoke animated:NO completion:nil];   // Show the new view
    
    [UIView commitAnimations];    // Play the animation
}


- (IBAction) goSelection:(UIButton*)sender
{
    SelectionViewController *selection = [[[SelectionViewController alloc] initWithNibName:@"SelectionView" bundle:nil] autorelease];
    assert(selection != nil);
    
    // Custom animated transition
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration: 0.5];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view.window cache:YES];
    
    [self presentViewController:selection animated:NO completion:nil];   // Show the new view
    
    [UIView commitAnimations];    // Play the animation
}

@end


