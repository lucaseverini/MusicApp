//
//  KaraokeTableCell.m
//  MusicApp
//
//  Created by Luca Severini on 31/1/2013.
//

#import "KaraokeTableCell.h"

@implementation KaraokeTableCell

@synthesize words;
@synthesize time;

- (id) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if(self != nil)
    {
        if(style == UITableViewCellStyleDefault)
        {
            CGRect frame = CGRectMake(5, 4, self.frame.size.width - 10, 22);
            self.words = [[[UITextField alloc] initWithFrame:frame] autorelease];
            self.words.font = [UIFont boldSystemFontOfSize:18.0];
            self.words.textAlignment = NSTextAlignmentLeft;
            self.words.autocorrectionType = UITextAutocorrectionTypeNo;
            self.words.enabled = NO;
            self.words.placeholder = @"Text";
            self.words.text = @"";
            self.words.tag = 1;
            self.words.keyboardType = UIKeyboardTypeDefault;
            [self.contentView addSubview:self.words];

            frame = CGRectMake(5, 26, self.frame.size.width - 30, 15);
            self.time = [[[UITextField alloc] initWithFrame:frame] autorelease];
            self.time.font = [UIFont systemFontOfSize:13.0];
            self.time.textAlignment = NSTextAlignmentLeft;
            self.time.autocorrectionType = UITextAutocorrectionTypeNo;
            self.time.enabled = NO;
            self.time.placeholder = @"Time in seconds";
            self.time.text = @"";
            self.time.tag = 2;
            self.time.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
            [self.contentView addSubview:self.time];
        }
        else
        {
            self.textLabel.text = @"Add a new row of text";
            self.textLabel.font = [UIFont systemFontOfSize:18.0];
            self.textLabel.enabled = NO;
        }
    }
    
    return self;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) done:(id)sender
{
    NSLog(@"done");
	
    // [textField resignFirstResponder];
}

@end
