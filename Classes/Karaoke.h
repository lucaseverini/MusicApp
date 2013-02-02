//
//  Karaoke.h
//  MusicApp
//
//  Created by Luca Severini on 21/1/2013.
//

#import <Foundation/Foundation.h>

@interface Karaoke : NSObject 
{
    NSUInteger colorStart;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSMutableAttributedString *attribText;
@property (nonatomic, retain) NSArray *time;
@property (nonatomic, assign) NSInteger step;

- (id)initKaraoke:(NSArray*)karaokeData;

- (BOOL)advanceRedRow;
- (void)resetRedRow;

@end
