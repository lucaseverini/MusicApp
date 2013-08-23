//
//  MyNavigationController.m
//  MusicApp
//
//  Created by Luca Severini on 2/2/13.
//
//


#import "MyNavigationController.h"
#import "DJMixerViewController.h"

@implementation MyNavigationController

- (BOOL)shouldAutorotate
{
    UIViewController *topController = [self.viewControllers objectAtIndex:0];
    if([topController isKindOfClass:[DJMixerViewController class]])
    {
/*
        DJMixerViewController *controller = (DJMixerViewController*)topController;
        
        if(controller.karaokeButton.highlighted)
        {
            return YES;
        }
        else if(controller.interfaceOrientation == UIInterfaceOrientationLandscapeRight ||
                        controller.interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        {
            return YES;
        }
*/
        return YES;
    }
    
    return NO;
}

@end
