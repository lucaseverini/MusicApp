//
//  Utilities.mm
//  MusicApp
//
//  Created by Luca Severini on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <sys/time.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include "Utilities.h"

void NSLogNoNewline (NSString *format, ...)
{
    va_list args;
    va_start(args, format);
	
    NSString *string;
    string = [[NSString alloc] initWithFormat:format arguments:args];
	
    va_end(args);
	
    printf("%s", [string UTF8String]);
	
	[string release];
}


NSUInteger CurrentMillisecs (void)
{
    struct timeval time;
    gettimeofday(&time, NULL);
 
    NSUInteger millis = (time.tv_sec * 1000) + (time.tv_usec / 1000);
    
    return millis;
 }


BOOL DeleteCategoriesFolder (void)
{
    NSFileManager *fsManager = [NSFileManager defaultManager];
    
    NSURL *rootDir = GetCachesDirectory();
    NSURL *dir = [NSURL URLWithString:@"categories" relativeToURL:rootDir];
	
    if(dir != nil && [fsManager fileExistsAtPath:[dir path]])
    {  
        return [fsManager removeItemAtURL:dir error:nil];
    }
    
    return NO;
}


BOOL DeletePublicationsFolder (void)
{
	NSInteger removedCount = 0;	
    NSFileManager *fsManager = [NSFileManager defaultManager];
    
    NSURL *rootDir = GetCachesDirectory();	
    NSURL *dir = [NSURL URLWithString:@"publications" relativeToURL:rootDir];
	
    if(dir != nil && [fsManager fileExistsAtPath:[dir path]])
    {
		NSArray *dirProp = [NSArray arrayWithObjects:NSURLIsDirectoryKey, nil];
		NSDirectoryEnumerator *dirEnum = [fsManager enumeratorAtURL:dir includingPropertiesForKeys:dirProp options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
		for(NSURL *subDir in dirEnum)
		{
			NSNumber *isDirectory;
			[subDir getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
			if([isDirectory boolValue])
			{
				NSDirectoryEnumerator *subDirEnum = [fsManager enumeratorAtURL:subDir includingPropertiesForKeys:dirProp options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil];
				for(NSURL *pubDir in subDirEnum)
				{
					NSURL *pdfResDir = [NSURL URLWithString:[[pubDir path] lastPathComponent] relativeToURL:rootDir];
					if(pdfResDir != nil && [fsManager fileExistsAtPath:[pdfResDir path]])
					{
						if([fsManager removeItemAtURL:pdfResDir error:nil])
						{
							removedCount++;
						}
					}
				}
			}
		}
		
        if([fsManager removeItemAtURL:dir error:nil])
		{
			removedCount++;
		}
    }
    
    return (removedCount != 0);
}


NSURL* GetDocumentsDirectory (void)
{
    static NSURL *docsDir;
    
    if(docsDir == nil)
    {
        // Pass back the Documents dir
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        docsDir = [NSURL fileURLWithPath:[paths objectAtIndex:0] isDirectory:YES];
        
        // Pass back the Documents dir
        // rootDir = [fsManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
    }
    
    return docsDir;
    
    // Apple has changed the guidelines regarding the Documents folder
    // http://stackoverflow.com/questions/8209406/ios-5-does-not-allow-to-store-downloaded-data-in-documents-directory    
}


NSURL* GetCachesDirectory (void)
{
    static NSURL *cachesDir;
    
    if(cachesDir == nil)
    {
        // Pass back the Caches dir
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cachesDir = [NSURL fileURLWithPath:[paths objectAtIndex:0] isDirectory:YES];
    }
    
    return cachesDir;
}


UIImage* invertImage (UIImage *originalImage)
{
	UIGraphicsBeginImageContext(originalImage.size);
	CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy);
	CGRect imageRect = CGRectMake(0, 0, originalImage.size.width, originalImage.size.height);
	[originalImage drawInRect:imageRect];
	
	CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference);
	// Translate/flip the graphics context (for transforming from CG* coords to UI* coords
	CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0, originalImage.size.height);
	CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
	// Mask the image
	CGContextClipToMask(UIGraphicsGetCurrentContext(), imageRect,  originalImage.CGImage);
	CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),[UIColor whiteColor].CGColor);
	CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, originalImage.size.width, originalImage.size.height));
	UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return returnImage;
}


NSString* getPlatform (void)
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
	
    char *machine = (char*)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
	
    NSString *platform = [NSString stringWithUTF8String:machine];
	
    free(machine);
	
    return platform;
}


NSString* platformString (void)
{
    NSString* platform = getPlatform();
	
	if ([platform isEqualToString:@"iPhone1,1"])	return @"iPhone 1G";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5 (GSM)";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2 (WiFi)";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini (WiFi)";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini (GSM)";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3 (WiFi)";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3 (GSM+CDMA)";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3 (GSM)";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4 (WiFi)";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4 (GSM)";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4 (GSM+CDMA)";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
	
    return platform;
}


NSString* GetOrientationName (NSInteger orientation)
{
	switch(orientation)
	{
		default:
		case UIDeviceOrientationUnknown:
			return @"Unknown";
			
		case UIDeviceOrientationPortrait:
			return @"Portrait";
		
		case UIDeviceOrientationPortraitUpsideDown:
			return @"Portrait UpsideDown";
			
		case UIDeviceOrientationLandscapeLeft:
			return @"Landscape Left";
			
		case UIDeviceOrientationLandscapeRight:
			return @"Landscape Right";

		case UIDeviceOrientationFaceUp:
			return @"Face Up";

		case UIDeviceOrientationFaceDown:
			return @"Face Down";
	}
}


void runOnMainQueueWithoutDeadlocking (void (^block)(void))
{
    if([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}



