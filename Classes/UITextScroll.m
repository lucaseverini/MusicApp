//
//  UITextScroll.m
//  MusicApp
//
//  Created by Luca Severini on 20-1-2013.
//

#import "UITextScroll.h"


@implementation UITextScroll

- (id)initWithCoder:(NSCoder*)aDecoder
{
    if((self = [super initWithCoder:aDecoder]))
    {
        [self setContentInset:UIEdgeInsetsMake(-1, 0, 0, 0)];
    }
    
    return self;
}

@end
