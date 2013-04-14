//
//  SelectionViewController.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SelectionViewController.h"
#import "KaraokeViewController.h"
#import "UICheckBox.h"
#import "MusicAppAppDelegate.h"
#import "DJMixer.h"
#import "InMemoryAudioFile.h"


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
        NSDictionary *channelDict = [NSDictionary dictionaryWithObjectsAndKeys:nil, @"AudioUrl", nil, @"AudioTitle", nil, @"AudioDuration", nil, @"AudioVolume", nil];     
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
    picker.prompt = [NSString stringWithFormat:@"Select Audio File to Play for Channel %d", channel];
    
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
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:[tracks objectAtIndex:[selectedRow row]]];
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

    NSNumber *duration = [NSNumber numberWithDouble:(double)songAsset.duration.value / (double)songAsset.duration.timescale];
    NSNumber *volume = [NSNumber numberWithDouble:1.0];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *channelDict = [NSDictionary dictionaryWithObjectsAndKeys:[url absoluteString], @"AudioUrl", title, @"AudioTitle", duration, @"AudioDuration", volume, @"AudioVolume", nil];
    [defaults setObject:channelDict forKey:[NSString stringWithFormat:@"Channel-%d", channel]];
    [defaults synchronize];
    
    NSArray *indexes = [NSArray arrayWithObject:selectedRow];
    [fileTable reloadRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
}


// Invoked when the user taps the Done button in the media item picker after having chosen one or more media items to play.
- (void) mediaPicker:(MPMediaPickerController*)mediaPicker didPickMediaItems:(MPMediaItemCollection*)mediaItemCollection
{    
	// Dismiss the media item picker.
	[self dismissViewControllerAnimated:YES completion:nil];
    
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    
    if([mediaItemCollection count] == 0)
        return;
    
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
            NSString *messageStr = [NSString stringWithFormat:@"The track %@ can't be read or played.", title];
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:nil message:messageStr delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil] autorelease];
            [alert show];
            return;
        }
/*
        NSString* lyrics = [songAsset lyrics];
        NSLog(@"Lyrics: (%d chars)", lyrics.length);
 
        NSArray *metaData = [songAsset commonMetadata];
        NSLog(@"MetaData: %@", metaData);
        for(AVMetadataItem* item in metaData)
        {
            NSString *key = [item commonKey];
            NSString *value = [item stringValue];
            NSLog(@"key = %@, value = %@", key, value);
        }
*/        
        // Retain objs going to be added to dictionary to avoid later problems
        // [url retain];
        // [title retain];
        // [duration retain];
        // [volume retain];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];        
        NSDictionary *channelDict = [NSDictionary dictionaryWithObjectsAndKeys:url, @"AudioUrl", title, @"AudioTitle", duration, @"AudioDuration", volume, @"AudioVolume", nil];
        [defaults setObject:channelDict forKey:[NSString stringWithFormat:@"Channel-%d", channel]];
        [defaults synchronize];

        NSArray *indexes = [NSArray arrayWithObject:selectedRow];
        [fileTable reloadRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else
    {
        NSLog(@"File is not of type MPMediaTypeMusic");
    }
}


// Invoked when the user taps the Done button in the media item picker having chosen zero media items to play
- (void) mediaPickerDidCancel:(MPMediaPickerController*)mediaPicker 
{
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
}


// Never called for now
- (void) exportMP3:(NSURL*)url toFileUrl:(NSString*)fileURL
{
    AVURLAsset *asset=[[[AVURLAsset alloc] initWithURL:url options:nil] autorelease];
    AVAssetReader *reader=[[[AVAssetReader alloc] initWithAsset:asset error:nil] autorelease];
    NSMutableArray *myOutputs =[[[NSMutableArray alloc] init] autorelease];
    for(id track in [asset tracks])
    {
        AVAssetReaderTrackOutput *output=[AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:nil];
        [myOutputs addObject:output];   
        [reader addOutput:output];
    }
    [reader startReading];
    NSFileHandle *fileHandle ;
    NSFileManager *fm=[NSFileManager defaultManager];
    if(![fm fileExistsAtPath:fileURL])
    {
        [fm createFileAtPath:fileURL contents:[[[NSData alloc] init] autorelease] attributes:nil];
    }
    fileHandle=[NSFileHandle fileHandleForUpdatingAtPath:fileURL];    
    [fileHandle seekToEndOfFile];
    
    AVAssetReaderOutput *output=[myOutputs objectAtIndex:0];
    int totalBuff=0;
    while(YES)
    {
        CMSampleBufferRef ref=[output copyNextSampleBuffer];
        if(ref==NULL)
            break;
        //copy data to file
        //read next one
        AudioBufferList audioBufferList;
        NSMutableData *data=[[NSMutableData alloc] init];
        CMBlockBufferRef blockBuffer;
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(ref, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
        
        for( int y=0; y<audioBufferList.mNumberBuffers; y++ )
        {
            AudioBuffer audioBuffer = audioBufferList.mBuffers[y];
            Float32 *frame = (Float32*)audioBuffer.mData;
            
            //  Float32 currentSample = frame[i];
            [data appendBytes:frame length:audioBuffer.mDataByteSize];
            
            //  written= fwrite(frame, sizeof(Float32), audioBuffer.mDataByteSize, f);
            ////NSLog(@"Wrote %d", written);
            
        }
        totalBuff++;
        CFRelease(blockBuffer);
        CFRelease(ref);
        [fileHandle writeData:data];
        //  //NSLog(@"writting %d frame for amounts of buffers %d ", data.length, audioBufferList.mNumberBuffers);
        [data release];
    }
    //  NSLog(@"total buffs %d", totalBuff);
    //  fclose(f);
    [fileHandle closeFile];
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


