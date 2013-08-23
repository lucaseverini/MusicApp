//
//  Karaoke.h
//  MusicApp
//
//  Created by Luca Severini on 21/1/2013.
//


extern NSString *kWordsKey;
extern NSString *kTimeKey;
extern NSString *kTypeKey;
extern NSString *kTagKey;
extern NSString *kTextKey;

@interface Karaoke : NSObject
{
    NSUInteger colorStart;
	CGSize realFieldSize;
	CGSize realFieldSizeLS;
	CGSize tallerFieldSize;
	CGSize tallerFieldSizeLS;
}

@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSMutableAttributedString *attribText;
@property (nonatomic, retain) NSMutableAttributedString *attribTextLS;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) UIFont *fontLS;
@property (nonatomic, retain) NSArray *time;
@property (nonatomic, assign) NSInteger step;
@property (nonatomic, assign) NSInteger advancedRows;
@property (nonatomic, assign) NSInteger advancedRowsLS;

- (id) initKaraoke:(NSArray*)karaokeData portraitSize:(CGSize)size landscapeSize:(CGSize)sizeLS;

- (BOOL) advanceRedRow;
- (void) resetRedRow;

@end
