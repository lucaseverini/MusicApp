//
//  Karaoke.mm
//  MusicApp
//
//  Created by Luca Severini on 21/1/2013.
//

#import "Karaoke.h"
#import "KaraokeViewController.h"


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


- (id)initKaraoke:(NSArray*)karaokeData
{
    if(karaokeData == nil || karaokeData.count == 0)
    {
        NSLog(@"No Karaoke data");
        return nil;
    }

    self = [super init];
    if(self != nil)
    {
        NSMutableArray *mutTime = [NSMutableArray array];
        NSMutableString *mutText = [NSMutableString stringWithString:@"\r"];
#if 1
        for(NSDictionary *row in karaokeData)
        {
            NSString *rowText = [row objectForKey:kWordsKey];
            if(rowText == nil)
                continue;
            
            NSNumber *rowTime = [row valueForKey:kTimeKey];
            if(rowTime == nil)
                continue;
            
            [mutText appendFormat:@"%@\r", rowText];             
            [mutTime addObject:rowTime];
        }
        
        // NSLog(@"%@", mutText);
        // NSLog(@"%@", mutTime);
#else
        [mutText appendString:@"Riga 1\rRiga 2\rRiga 3\rRiga 4\rRiga 5\rRiga 6\rRiga 7\rRiga 8\rRiga 9\rRiga 10\rRiga 11\rRiga 12\r "];
        for(int idx = 0; idx < 14; idx++)
        {
            [mutTime addObject:[NSNumber numberWithDouble:(NSTimeInterval)1.0]];
        }
#endif
        text = [[NSString alloc] initWithString:mutText];
        attribText = [[NSMutableAttributedString alloc] initWithString:text];
        time = [[NSArray alloc] initWithArray:mutTime];

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
