//
//  Karaoke.mm
//  MusicApp
//
//  Created by Luca Severini on 21/1/2013.
//

#import "Karaoke.h"

@implementation Karaoke

@synthesize text;
@synthesize attribText;
@synthesize time;
@synthesize step;

- (void)dealloc
{
    [text release];
    [attribText release];
    [time release];
    
    [super dealloc];
}


- (id)initKaraoke:(NSArray*)Rows timing:(NSArray*)timing
{
    self = [super init];
    if(self != nil)
    {
        text = @"\rRiga 1\rRiga 2\rRiga 3\rRiga 4\rRiga 5\rRiga 6\rRiga 7\rRiga 8\rRiga 9\rRiga 10\rRiga 11\rRiga 12\r ";
        attribText = [[NSMutableAttributedString alloc] initWithString:text];
        
        NSMutableArray *tmpArray = [NSMutableArray arrayWithCapacity:100];
        for(int idx = 1; idx <= 14; idx++)
        {
            [tmpArray addObject:[NSNumber numberWithDouble:(NSTimeInterval).5]];
        }        
        time = [[NSArray alloc] initWithArray:tmpArray];

        UIFont *font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
        [attribText addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [text length])];
        
        NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
        paragraph.alignment = NSTextAlignmentCenter;
        [attribText addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [text length])];
 
        [self resetRedRow];
    }
    
    return self;
}


- (BOOL)advanceRedRow
{
    if(colorStart >= [text length])
    {
        return NO;
    }
    
    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    NSRange parRange = [text paragraphRangeForRange:NSMakeRange(colorStart, 1)];
    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:parRange];
    colorStart += parRange.length;
    
    return YES;
}


- (void)resetRedRow
{
    colorStart = 1;
    step = 0;
    
    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    NSRange parRange = [text paragraphRangeForRange:NSMakeRange(colorStart, 1)];
    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:parRange];
    colorStart += parRange.length;
}

@end
