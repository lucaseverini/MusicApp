//
//  UICheckBox.m
//  MusicApp
//
//  Created by Luca Severini on 7-7-2012.
//


#import "UICheckBox.h"


@implementation UICheckBox

@synthesize checked;

- (id) initWithFrame:(CGRect)frame
{    
    if((self = [super initWithFrame:frame]))
    {
        self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        
        [self setImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
        
        [self addTarget:self action:@selector(checkBoxClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self;
        
}

- (BOOL) checkBoxClicked
{
    if(self.checked == NO)
    {
        self.checked = YES;
        [self setImage:[UIImage imageNamed:@"checkbox_full.png"] forState:UIControlStateNormal];
    }
    else
	{
        self.checked = NO;
        [self setImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
    }
    
    return checked;
}

- (void) dealloc
{
    [super dealloc];
}

@end
