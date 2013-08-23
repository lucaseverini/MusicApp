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
NSString *kTagKey = @"tagKey";
NSString *kTextKey = @"textKey";

@implementation Karaoke

@synthesize text;
@synthesize attribText;
@synthesize attribTextLS;
@synthesize font;
@synthesize fontLS;
@synthesize time;
@synthesize step;
@synthesize advancedRows;
@synthesize advancedRowsLS;


- (void) dealloc
{
    [text release];
    [attribText release];
    [attribTextLS release];
    [time release];
    
    [super dealloc];
}


- (id) initKaraoke:(NSArray*)karaokeData portraitSize:(CGSize)size landscapeSize:(CGSize)sizeLS
{
    if(karaokeData == nil || karaokeData.count == 0)
    {
        NSLog(@"No Karaoke data");
        return nil;
    }

    self = [super init];
    if(self != nil)
    {
		realFieldSize = size;
		realFieldSizeLS = sizeLS;

		tallerFieldSize = CGSizeMake(size.width, size.height + 100.0);
		tallerFieldSizeLS = CGSizeMake(sizeLS.width, sizeLS.height + 100.0);

        NSMutableArray *mutTime = [NSMutableArray array];
        NSMutableString *mutText = [NSMutableString stringWithString:@"\r\r"];

		float prevRowTime = 0;
        for(NSDictionary *row in karaokeData)
        {
			if(![row isKindOfClass:[NSDictionary class]])
			{
				continue;
			}
			
            NSString *rowText = [row objectForKey:kWordsKey];
            if(rowText == nil)
			{
                continue;
			}
            
			float thisRowTime = [[row valueForKey:kTimeKey] floatValue];
            NSNumber *rowTime = [NSNumber numberWithFloat:(thisRowTime - prevRowTime)];			
            if(rowTime == nil)
			{
                continue;
			}
			
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
 
        text = [[NSString alloc] initWithString:mutText];
		
        attribText = [[NSMutableAttributedString alloc] initWithString:text];
        attribTextLS = [[NSMutableAttributedString alloc] initWithString:text];

        font = [UIFont fontWithName:@"Helvetica-Bold" size:16.0];
        [attribText addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [text length])];
 
        fontLS = [UIFont fontWithName:@"Helvetica-Bold" size:26.0];
        [attribTextLS addAttribute:NSFontAttributeName value:fontLS range:NSMakeRange(0, [text length])];

        NSMutableParagraphStyle *paragraph = [[[NSMutableParagraphStyle alloc] init] autorelease];
        paragraph.alignment = NSTextAlignmentCenter;
        
        [attribText addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [text length])];
        [attribTextLS addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, [text length])];
 
        [self resetRedRow];

        time = [[NSArray alloc] initWithArray:mutTime];
    }
    
    return self;
}


- (BOOL) advanceRedRow
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

	NSString *textRow = [text substringWithRange:parRange];

	colorStart += parRange.length;
	step++;		
	
	CGSize stringSize = [textRow sizeWithFont:font constrainedToSize:tallerFieldSize lineBreakMode:NSLineBreakByWordWrapping];
	// NSLog(@"%@", NSStringFromCGSize(stringSize));
	advancedRows = stringSize.height / font.lineHeight;
	if(advancedRows > 3)
	{
		stringSize = [textRow sizeWithFont:font constrainedToSize:realFieldSize lineBreakMode:NSLineBreakByTruncatingTail];
		advancedRows = stringSize.height / font.lineHeight;
	}
	// Compensate for the padding of UITextView (8+8 pixels)
	if(advancedRows == 1 && realFieldSize.width - stringSize.width < 16.0)
	{
		advancedRows++;
	}

	stringSize = [textRow sizeWithFont:fontLS constrainedToSize:tallerFieldSizeLS lineBreakMode:NSLineBreakByWordWrapping];
	advancedRowsLS = stringSize.height / fontLS.lineHeight;
	if(advancedRows > 3)
	{
		stringSize = [textRow sizeWithFont:fontLS constrainedToSize:realFieldSizeLS lineBreakMode:NSLineBreakByTruncatingTail];
		advancedRowsLS = stringSize.height / fontLS.lineHeight;
	}
	// Compensate for the padding of UITextView (8+8 pixels)
	if(advancedRowsLS == 1 && realFieldSizeLS.width - stringSize.width < 16.0)
	{
		advancedRowsLS++;
	}
	
	return YES;
}


- (void) resetRedRow
{
    colorStart = 1;
    step = 0;
	advancedRows = 0;
	advancedRowsLS = 0;
    
    NSRange parRange = [text paragraphRangeForRange:NSMakeRange(colorStart, 1)];

    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    [attribText addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:parRange];

    [attribTextLS addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(0, [text length])];
    [attribTextLS addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:parRange];
    
    colorStart += parRange.length;
}

@end
