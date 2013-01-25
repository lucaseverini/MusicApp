//
//  UICheckBox.h
//  MusicApp
//
//  Created by Luca Severini on 7-7-2012.
//

#import <Foundation/Foundation.h>

@class UIButton;

@interface UICheckBox : UIButton 
{
     BOOL checked;
}

@property (nonatomic, assign) BOOL checked;

- (BOOL) checkBoxClicked;

@end
