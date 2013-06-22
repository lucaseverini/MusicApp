//
//  Karaoke.mm
//  MusicApp
//
//  Created by Luca Severini on 21/1/2013.
//

#import "Karaoke.h"
#import "KaraokeViewController.h"


NSString *kWordsKey = @"wordsKey";
NSString *kTimeKey = @"timeKey";
NSString *kTypeKey = @"typeKey";

@implementation Karaoke

@synthesize text;
@synthesize attribText;
@synthesize attribTextLS;
@synthesize time;
@synthesize step;

- (void)dealloc
{
    [text release];
    [attribText release];
    [attribTextLS release];
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
        NSMutableString *mutText = [NSMutableString stringWithString:@"\r\r"];

		float prevRowTime = 0;
        for(NSDictionary *row in karaokeData)
        {
            NSString *rowText = [row objectForKey:kWordsKey];
            if(rowText == nil)
                continue;
            
			float thisRowTime = [[row valueForKey:kTimeKey] floatValue];
            NSNumber *rowTime = [NSNumber numberWithFloat:(thisRowTime - prevRowTime)];			
            if(rowTime == nil)
                continue;
			
			if([rowText isEqualToString:@"[end]"])
			{
				[mutText appendFormat:@"%@\r", @""];
				[mutTime addObject:rowTime];
				
				break;
			}
            
            [mutText appendFormat:@"%@\r", rowText];
            [mutTime addObject:rowTime];
			
			prevRowTime = thisRowTime;
        }
        
        // NSLog(@"%@", mutText);
        // NSLog(@"%@", mutTime);

        text = [[NSString alloc] initWithString:mutText];
        attribText = [[NSMutableAttributedString alloc] initWithString:text];
        attribTextLS = [[NSMutableAttributedString alloc] initWithString:text];

        UIFont *font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
        [attribText addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [text length])];
 
        font = [UIFont fontWithName:@"Helvetica-Bold" size:26.0];
        [attribTextLS addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [text length])];

        NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
        paragraph.alignment = NSTextAlignmentCenter;
        
        [attribText addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [text length])];
        [attribTextLS addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [text length])];
 
        [self resetRedRow];

        time = [[NSArray alloc] initWithArray:mutTime];
    }
    
    return self;
}


- (BOOL)advanceRedRow
{
    if(colorStart >= [text length])
    {
        return NO;
    }
    
    NSRange parRange = [text paragraphRangeForRange:NSMakeRange(colorStart, 1)];

    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:parRange];

    [attribTextLS addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    [attribTextLS addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:parRange];
    
    colorStart += parRange.length;
    
    return YES;
}


- (void)resetRedRow
{
    colorStart = 1;
    step = 0;
    
    NSRange parRange = [text paragraphRangeForRange:NSMakeRange(colorStart, 1)];

    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:parRange];

    [attribTextLS addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    [attribTextLS addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:parRange];
    
    colorStart += parRange.length;
}

@end
