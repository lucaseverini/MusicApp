//
//  SelectionViewController.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//


#import "SelectionViewController.h"
#import "KaraokeViewController.h"
#import "UICheckBox.h"
#import "MusicAppAppDelegate.h"
#import "DJMixer.h"
#import "InMemoryAudioFile.h"
#import "SVProgressHUD.h"


@implementation SelectionViewController

@synthesize backButton;
@synthesize clearButton;
@synthesize fileTable;
@synthesize fileTableController;
@synthesize versionLabel;

- (void) viewDidLoad
{        
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [infoDict objectForKey:@"CFBundleDisplayName"];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];    
    versionLabel.text = [NSString stringWithFormat:@"%@ %@", appName, appVersion];

	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
	userDocDirPath = [[paths objectAtIndex:0] copy];
}


- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (IBAction) goBack:(UIButton*)sender
{	
    // Custom animated transition
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration: 0.5];    
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view.window cache:YES];       

    [self dismissViewControllerAnimated:NO completion:nil];  // Return back to parent view

    [UIView commitAnimations];  // Play the animation
}

    
- (IBAction) doClearList:(UIButton*)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for(int idx = 1; idx <= 8; idx++)
    {
        NSDictionary *channelDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"AudioUrl", [NSNull null], @"AudioTitle", [NSNull null], @"AudioDuration", [NSNull null], @"AudioVolume", nil];
        [defaults setObject:channelDict forKey:[NSString stringWithFormat:@"Channel-%d", idx]];
    }
    
    [defaults synchronize];
     
    [fileTable reloadData];
}


- (void) didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void) dealloc 
{
    [super dealloc];
}

#pragma mark Media item picker delegate methods

- (void) doSelectFile:(NSIndexPath*)row
{
#if TARGET_IPHONE_SIMULATOR
    
    selectedRow = row;
    channel = [selectedRow row] + 1;

    [self simulatedMediaPicker];
    
#else
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    picker.delegate					  = self;
    picker.allowsPickingMultipleItems = NO;

    selectedRow = row;
    channel = [selectedRow row] + 1;    
    picker.prompt = [NSString stringWithFormat:@"Select the Audio File to Play for Track %d", channel];
    
    // The media item picker uses the default UI style, so it needs a default-style status bar to match it visually
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    
    [self presentViewController:picker animated:YES completion:nil];
    
    [picker release];
#endif
}


// Simulated the MediaPicker dialog which is not implemented in the simulator
- (void) simulatedMediaPicker
{
    static NSArray *tracks = [[NSArray alloc] initWithObjects:@"/Users/Luca/Desktop/Music App/Tracce/Basso.wav",
                                                              @"/Users/Luca/Desktop/Music App/Tracce/Drums.wav",
                                                              @"/Users/Luca/Desktop/Music App/Tracce/GTR 2LR.wav",
                                                              @"/Users/Luca/Desktop/Music App/Tracce/GTR TeleCaster.wav",
                                                              @"/Users/Luca/Desktop/Music App/Tracce/HH.wav",
                                                              @"/Users/Luca/Desktop/Music App/Tracce/RytmhSynth.wav",
                                                              @"/Users/Luca/Desktop/Music App/Tracce/Shakers.wav",
															//@"/Users/Luca/Desktop/Music App/Tracce/Tamburine.wav",
                                                              @"/Users/Luca/Desktop/Music App/Tracce/Take On Me (Lyrics Tag).mp3",
                                                              nil];
    
    NSURL *url = [NSURL fileURLWithPath:[tracks objectAtIndex:[selectedRow row]]];
    NSLog(@"Track url: %@", url);
    AVURLAsset *songAsset = [[[AVURLAsset alloc] initWithURL:url options:nil] autorelease];
    assert(songAsset != nil);

    NSString *title = [url lastPathComponent];
    for(AVMetadataItem* item in [songAsset commonMetadata])
    {
        if([[item commonKey] isEqualToString:MPMediaItemPropertyTitle])
        {
            title = [NSString stringWithString:[item stringValue]];
            break;
        }
    }

	NSURL *copyUrl = [[self copyAudioFile:[url absoluteString] to:userDocDirPath named:nil] autorelease];
	if(copyUrl != nil)
	{
		NSNumber *duration = [NSNumber numberWithDouble:(double)songAsset.duration.value / (double)songAsset.duration.timescale];
		NSNumber *volume = [NSNumber numberWithDouble:1.0];

		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary *channelDict = [NSDictionary dictionaryWithObjectsAndKeys:[copyUrl absoluteString], @"AudioUrl", title, @"AudioTitle", duration, @"AudioDuration", volume, @"AudioVolume", nil];
		[defaults setObject:channelDict forKey:[NSString stringWithFormat:@"Channel-%d", channel]];
		[defaults synchronize];
		
		NSArray *indexes = [NSArray arrayWithObject:selectedRow];
		[fileTable reloadRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationNone];
	}
	else
	{
		NSString *messageStr = [NSString stringWithFormat:@"The track %@ can't be copied", title];
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil message:messageStr delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil] autorelease];
		[alert show];
	}
}


// Invoked when the user taps the Done button in the media item picker after having chosen one or more media items to play.
- (void) mediaPicker:(MPMediaPickerController*)mediaPicker didPickMediaItems:(MPMediaItemCollection*)mediaItemCollection
{    
	// Dismiss the media item picker.
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	
	if([mediaItemCollection count] == 0)
	{
		return;
	}
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSString *channelStr = [NSString stringWithFormat:@"Channel-%d", channel];	
	NSDictionary *channelDict = [defaults objectForKey:channelStr];
	if(channelDict != nil)
	{
		NSString *UrlStr = [channelDict objectForKey:@"AudioUrl"];
		NSURL *oldAudioUrl = [NSURL URLWithString:UrlStr];
		
		if([[NSFileManager defaultManager] fileExistsAtPath:[oldAudioUrl path]])
		{		
			[[NSFileManager defaultManager] removeItemAtURL:oldAudioUrl error:nil];			
			if([[NSFileManager defaultManager] fileExistsAtPath:[oldAudioUrl absoluteString]])
			{
				NSLog(@"File %@ not deleted", [oldAudioUrl path]);
			}
		}
	}
	
	MPMediaItem *audioFile = [[mediaItemCollection items]objectAtIndex:0];
	assert(audioFile != nil);
	NSInteger type = [[audioFile valueForProperty:MPMediaItemPropertyMediaType] integerValue];
	
	if(type == MPMediaTypeMusic)
	{
		NSString *url = [[audioFile valueForProperty:MPMediaItemPropertyAssetURL] absoluteString];
		NSString *title = [audioFile valueForProperty:MPMediaItemPropertyTitle];
		NSNumber *duration = [audioFile valueForProperty:MPMediaItemPropertyPlaybackDuration];
		NSNumber *volume = [NSNumber numberWithDouble:1.0];

		AVURLAsset *songAsset = [[[AVURLAsset alloc] initWithURL:[NSURL URLWithString:url] options:nil] autorelease];
		assert(songAsset != nil);        
		BOOL isReadable = [songAsset isReadable];
		BOOL isPlayable = [songAsset isPlayable];
		if(!isReadable || !isPlayable)
		{
			NSString *messageStr = [NSString stringWithFormat:@"The track %@ can't be read or played", title];
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil message:messageStr delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil] autorelease];
			[alert show];
			return;
		}
		
		[SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Copying the Audio File\r%@", title] maskType:SVProgressHUDMaskTypeClear];
				
		__block NSURL *copyUrl = nil;
		dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, NULL);
		dispatch_async(globalQueue,
		^{
			copyUrl = [self copyAudioFile:url to:userDocDirPath named:title];
			
			[SVProgressHUD dismissWithAnimation];
			
			// Sleep for a while to avoid a graphical glitch when the selected table row redraws
			[NSThread sleepForTimeInterval:1.0];

			if(copyUrl != nil)
			{
				NSDictionary *channelDict = [NSDictionary dictionaryWithObjectsAndKeys:[copyUrl absoluteString], @"AudioUrl", title, @"AudioTitle", duration, @"AudioDuration", volume, @"AudioVolume", nil];
				[defaults setObject:channelDict forKey:[NSString stringWithFormat:@"Channel-%d", channel]];
				[defaults synchronize];
				
				NSArray *indexes = [NSArray arrayWithObject:selectedRow];
				[fileTable reloadRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationNone];
			}
			else
			{				
				dispatch_sync(dispatch_get_main_queue(),
				^{
					NSString *messageStr = [NSString stringWithFormat:@"The Audio File %@ can't be copied", title];
					UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil message:messageStr delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil] autorelease];
					[alert show];
				});
			}
		});
	}
	else
	{
		NSLog(@"File is not of type MPMediaTypeMusic");
	}
}


- (NSURL*) copyAudioFile:(NSString*)fileUrlString to:(NSString*)folderPathString named:(NSString*)fileName
{
	NSError *error = nil;

	NSURL *fileURL = [NSURL URLWithString:fileUrlString];
	
	if(fileName == nil)
	{
		fileName = [fileURL lastPathComponent];
	}

	fileName = [fileName stringByDeletingPathExtension];
	fileName = [fileName stringByAppendingPathExtension:@"caf"];
	
	NSString *copyPath = [userDocDirPath stringByAppendingPathComponent:fileName];
	
	[[NSFileManager defaultManager] removeItemAtPath:copyPath error:nil];
	
	AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
	if(asset == nil)
	{
		return nil;
	}
	
	AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:&error];
	if(error != nil)
	{
		NSLog(@"Error %@ in assetReaderWithAsset", error);
		return nil;
	}
	
	AVAssetReaderOutput *readerOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:asset.tracks audioSettings:nil];
	if(![assetReader canAddOutput:readerOutput])
	{
		NSLog(@"Can't add AVAssetReaderOutput");
		return nil;
	}
	[assetReader addOutput: readerOutput];	
	
	NSURL *copyUrl = [[NSURL alloc] initFileURLWithPath:copyPath];
	AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:copyUrl fileType:AVFileTypeCoreAudioFormat error:&error];
	if(error != nil)
	{
		NSLog (@"Error %@ in assetWriterWithURL", error);
		
		[copyUrl release];
		return nil;
	}
	
	AudioChannelLayout channelLayout;
	memset(&channelLayout, 0, sizeof(AudioChannelLayout));
	channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
	NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
											[NSNumber numberWithFloat:kSamplingRate], AVSampleRateKey,
											[NSNumber numberWithInt:2], AVNumberOfChannelsKey,
											[NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
											[NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
											[NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
											[NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
											[NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey, nil];
	
	AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:outputSettings];
	if([assetWriter canAddInput:assetWriterInput])
	{
		[assetWriter addInput:assetWriterInput];
	}
	else
	{
		NSLog (@"Can't add AVAssetWriterInput");

		[copyUrl release];
		return nil;
	}
	assetWriterInput.expectsMediaDataInRealTime = NO;
	
	[assetWriter startWriting];
	[assetReader startReading];
	
	AVAssetTrack *track = [asset.tracks objectAtIndex:0];
	CMTime startTime = CMTimeMake (0, track.naturalTimeScale);
	[assetWriter startSessionAtSourceTime: startTime];

	NSLog(@"Copying %@ to %@...", fileUrlString, copyPath);
	
	__block BOOL fileCopied = NO;
	dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, NULL);
	[assetWriterInput requestMediaDataWhenReadyOnQueue:globalQueue usingBlock:
	^{
		// The block will be called repeatedly by GCD, but we still need to make sure that the writer input is able to accept new samples.
		while(assetWriterInput.readyForMoreMediaData)
		{
			CMSampleBufferRef nextBuffer = [readerOutput copyNextSampleBuffer];
			if(nextBuffer != nil)
			{
				// Append buffer
				[assetWriterInput appendSampleBuffer: nextBuffer];
			}
			else
			{
				// Done!
				[assetWriterInput markAsFinished];
				
				[assetWriter finishWritingWithCompletionHandler:^{}];
				[assetReader cancelReading];
				
				NSLog (@"Done");

				fileCopied = YES;
				break;
			}
		}
	}];
	
	while(!fileCopied)
	{
		[NSThread sleepForTimeInterval:0.1];
	}
			
	NSDictionary *outputFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:copyPath error:nil];
	if([outputFileAttributes fileSize] == 0)
	{
		[copyUrl release];
		return nil;
	}
	else
	{
		return copyUrl;
	}
}


// Invoked when the user taps the Done button in the media item picker having chosen zero media items to play
- (void) mediaPickerDidCancel:(MPMediaPickerController*)mediaPicker 
{
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}


// Override to allow orientations other than the default portrait orientation.
// Called if iOS >= 6
- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


// Called if iOS >= 6
- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end


