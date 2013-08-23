//
//  Utilities.h
//  MusicApp
//
//  Created by Luca Severini on 5/22/12.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Publication;

extern "C" // Avoids name mangling problems
{
    void NSLogNoNewline (NSString *format, ...);
    
    NSUInteger CurrentMillisecs (void);

    BOOL DeletePublicationDocument (Publication *pub);

    BOOL PublicationDocumentExists (Publication *pub);

    NSURL* GetDocumentsDirectory (void);
	
	NSURL* GetCachesDirectory (void);
	
	UIImage* invertImage (UIImage *originalImage);

	NSString* getPlatform (void);
	
	NSString* platformString (void);
	
	void runOnMainQueueWithoutDeadlocking (void (^block)(void));
	
	NSString* GetOrientationName (NSInteger orientation);
}