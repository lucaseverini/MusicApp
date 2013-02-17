//
//  DJMixerViewController.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import "MusicAppAppDelegate.h"
#import "DJMixer.h"
#import "DJMixerViewController.h"
#import "SettingsViewController.h"
#import "SelectionViewController.h"
#import "CoreText/CoreText.h"
#import "UITextScroll.h"
#import "Karaoke.h"
#import "LoadAudioOperation.h"


@implementation DJMixerViewController

@synthesize portraitView;
@synthesize landscapeView;
@synthesize channel1VolumeSlider;
@synthesize channel2VolumeSlider;
@synthesize channel3VolumeSlider;
@synthesize channel4VolumeSlider;
@synthesize channel5VolumeSlider;
@synthesize channel6VolumeSlider;
@synthesize channel7VolumeSlider;
@synthesize channel8VolumeSlider;
@synthesize audioInputVolumeSlider;
@synthesize channel1Label;
@synthesize channel2Label;
@synthesize channel3Label;
@synthesize channel4Label;
@synthesize channel5Label;
@synthesize channel6Label;
@synthesize channel7Label;
@synthesize channel8Label;
@synthesize audioInputLabel;
@synthesize playButton;
@synthesize pauseSwitch;
@synthesize selectButton;
@synthesize karaokeButton;
@synthesize karaokeText;
@synthesize karaokeActivated;

@synthesize playButtonLS;
@synthesize pauseSwitchLS;
@synthesize selectButtonLS;
@synthesize karaokeButtonLS;
@synthesize karaokeTextLS;

@synthesize djMixer;
@synthesize karaoke;
@synthesize karaokeTimer;
@synthesize isPortrait;


- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self != nil)
    {
    }
    
    return self;
}


- (void) didReceiveMemoryWarning
{
    NSLog(@"didReceiveMemoryWarning sent to %@", self);
    
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
                                     // Release anything that's not essential, such as cached data
}


- (void) dealloc
{
    [super dealloc];
}


- (void) viewDidLoad
{
    sliders[0] = channel1VolumeSlider;
    sliders[1] = channel2VolumeSlider;
    sliders[2] = channel3VolumeSlider;
    sliders[3] = channel4VolumeSlider;
    sliders[4] = channel5VolumeSlider;
    sliders[5] = channel6VolumeSlider;
    sliders[6] = channel7VolumeSlider;
    sliders[7] = channel8VolumeSlider;
    sliders[8] = audioInputVolumeSlider;
}

- (void) viewWillDisappear:(BOOL)animated
{    
    [super viewWillDisappear:animated];
 
    [self saveControlsValue];
    
    if(self.karaoke != nil)
    {
        if(karaokeTimer != nil)
        {
            [karaokeTimer invalidate];
            karaokeTimer = nil;
        }
        
        [self.karaokeButton setHighlighted:NO];
        [self.karaokeButtonLS setHighlighted:NO];

        [self.karaoke release];
        self.karaoke = nil;
    }
}


- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    int totLoadedChannels = 0;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *channelDict = [defaults objectForKey:@"Channel-1"];
    if(channelDict != nil) 
    {
        NSString *url = [channelDict objectForKey:@"AudioUrl"];
        if(url == nil)
        {
            [djMixer.loop[0] freeStuff];
        }
        else
        {
            LoadAudioOperation *loadOperation = [[LoadAudioOperation alloc] initWithAudioFile:url];
            [djMixer.loadAudioQueue addOperation:loadOperation];
            [djMixer.loop[0] setLoadOperation:loadOperation];
        }
    }
    if(djMixer.loop[0].loaded)
    {
        totLoadedChannels++;
        float sliderValue = [[channelDict objectForKey:@"AudioVolume"] floatValue];

        [channel1Label setText:[NSString stringWithFormat:@"%@ (%d)", [channelDict objectForKey:@"AudioTitle"], djMixer.loop[0].trackCount]];
        [channel1VolumeSlider setEnabled:YES];
        [channel1VolumeSlider setValue:sliderValue];
        
        [djMixer changeCrossFaderAmount:sliderValue forChannel:1];
    }
    else 
    {
        [channel1Label setText:@""];
        [channel1VolumeSlider setEnabled:NO];
        [channel1VolumeSlider setValue:0.0];
    }

    channelDict = [defaults objectForKey:@"Channel-2"];
    if(channelDict != nil) 
    {
        NSString *url = [channelDict objectForKey:@"AudioUrl"];
        if(url == nil)
        {
            [djMixer.loop[1] freeStuff];
        }
        else
        {
            [djMixer.loop[1] removeLoadOperation]; // Remove the previous operation if present

            LoadAudioOperation *loadOperation = [[LoadAudioOperation alloc] initWithAudioFile:url];
            [djMixer.loadAudioQueue addOperation:loadOperation];
            [djMixer.loop[1] setLoadOperation:loadOperation];
        }
    }
    if(djMixer.loop[1].loaded)
    {
        totLoadedChannels++;
        float sliderValue = [[channelDict objectForKey:@"AudioVolume"] floatValue];

        [channel2Label setText:[NSString stringWithFormat:@"%@ (%d)", [channelDict objectForKey:@"AudioTitle"], djMixer.loop[1].trackCount]];
        [channel2VolumeSlider setEnabled:YES];
        [channel2VolumeSlider setValue:sliderValue];
        
        [djMixer changeCrossFaderAmount:sliderValue forChannel:2];
    }
    else 
    {
        [channel2Label setText:@""];
        [channel2VolumeSlider setEnabled:NO];
        [channel2VolumeSlider setValue:0.0];
    }
    
    channelDict = [defaults objectForKey:@"Channel-3"];
    if(channelDict != nil) 
    {
        NSString *url = [channelDict objectForKey:@"AudioUrl"];
        if(url == nil)
        {
            [djMixer.loop[2] freeStuff];
        }
        else
        {
            [djMixer.loop[2] removeLoadOperation]; // Remove the previous operation if present

            LoadAudioOperation *loadOperation = [[LoadAudioOperation alloc] initWithAudioFile:url];
            [djMixer.loadAudioQueue addOperation:loadOperation];
            [djMixer.loop[2] setLoadOperation:loadOperation];
        }
    }
    if(djMixer.loop[2].loaded)
    {
        totLoadedChannels++;
        float sliderValue = [[channelDict objectForKey:@"AudioVolume"] floatValue];

        [channel3Label setText:[NSString stringWithFormat:@"%@ (%d)", [channelDict objectForKey:@"AudioTitle"], djMixer.loop[2].trackCount]];
        [channel3VolumeSlider setEnabled:YES];
        [channel3VolumeSlider setValue:sliderValue];
        
        [djMixer changeCrossFaderAmount:sliderValue forChannel:3];
    }
    else 
    {
        [channel3Label setText:@""];
        [channel3VolumeSlider setEnabled:NO];
        [channel3VolumeSlider setValue:0.0];
    }
  
    channelDict = [defaults objectForKey:@"Channel-4"];
    if(channelDict != nil) 
    {
        NSString *url = [channelDict objectForKey:@"AudioUrl"];
        if(url == nil)
        {
            [djMixer.loop[3] freeStuff];
        }
        else
        {
            [djMixer.loop[3] removeLoadOperation]; // Remove the previous operation if present

            LoadAudioOperation *loadOperation = [[LoadAudioOperation alloc] initWithAudioFile:url];
            [djMixer.loadAudioQueue addOperation:loadOperation];
            [djMixer.loop[3] setLoadOperation:loadOperation];

        }
    }
    if(djMixer.loop[3].loaded)
    {
        totLoadedChannels++;
        float sliderValue = [[channelDict objectForKey:@"AudioVolume"] floatValue];

        [channel4Label setText:[NSString stringWithFormat:@"%@ (%d)", [channelDict objectForKey:@"AudioTitle"], djMixer.loop[3].trackCount]];
        [channel4VolumeSlider setEnabled:YES];
        [channel4VolumeSlider setValue:[[channelDict objectForKey:@"AudioVolume"] floatValue]];
        
        [djMixer changeCrossFaderAmount:sliderValue forChannel:4];
    }
    else 
    {
        [channel4Label setText:@""];
        [channel4VolumeSlider setEnabled:NO];
        [channel4VolumeSlider setValue:0.0];
    }

    channelDict = [defaults objectForKey:@"Channel-5"];
    if(channelDict != nil) 
    {
        NSString *url = [channelDict objectForKey:@"AudioUrl"];
        if(url == nil)
        {
            [djMixer.loop[4] freeStuff];
        }
        else
        {
            [djMixer.loop[4] removeLoadOperation]; // Remove the previous operation if present

            LoadAudioOperation *loadOperation = [[LoadAudioOperation alloc] initWithAudioFile:url];
            [djMixer.loadAudioQueue addOperation:loadOperation];
            [djMixer.loop[4] setLoadOperation:loadOperation];
        }
    }
    if(djMixer.loop[4].loaded)
    {
        totLoadedChannels++;
        float sliderValue = [[channelDict objectForKey:@"AudioVolume"] floatValue];

        [channel5Label setText:[NSString stringWithFormat:@"%@ (%d)", [channelDict objectForKey:@"AudioTitle"], djMixer.loop[4].trackCount]];
        [channel5VolumeSlider setEnabled:YES];
        [channel5VolumeSlider setValue:sliderValue];
        
        [djMixer changeCrossFaderAmount:sliderValue forChannel:5];
    }
    else 
    {
        [channel5Label setText:@""];
        [channel5VolumeSlider setEnabled:NO];
        [channel5VolumeSlider setValue:0.0];
    }

    channelDict = [defaults objectForKey:@"Channel-6"];
    if(channelDict != nil) 
    {
        NSString *url = [channelDict objectForKey:@"AudioUrl"];
        if(url == nil)
        {
            [djMixer.loop[5] freeStuff];
        }
        else
        {
            [djMixer.loop[5] removeLoadOperation]; // Remove the previous operation if present

            LoadAudioOperation *loadOperation = [[LoadAudioOperation alloc] initWithAudioFile:url];
            [djMixer.loadAudioQueue addOperation:loadOperation];
            [djMixer.loop[5] setLoadOperation:loadOperation];
        }
    }
    if(djMixer.loop[5].loaded)
    {
        totLoadedChannels++;
        float sliderValue = [[channelDict objectForKey:@"AudioVolume"] floatValue];

        [channel6Label setText:[NSString stringWithFormat:@"%@ (%d)", [channelDict objectForKey:@"AudioTitle"], djMixer.loop[5].trackCount]];
        [channel6VolumeSlider setEnabled:YES];
        [channel6VolumeSlider setValue:sliderValue];
        
        [djMixer changeCrossFaderAmount:sliderValue forChannel:6];
    }
    else 
    {
        [channel6Label setText:@""];
        [channel6VolumeSlider setEnabled:NO];
        [channel6VolumeSlider setValue:0.0];
    }

    channelDict = [defaults objectForKey:@"Channel-7"];
    if(channelDict != nil) 
    {
        NSString *url = [channelDict objectForKey:@"AudioUrl"];
        if(url == nil)
        {
            [djMixer.loop[6] freeStuff];
        }
        else
        {
            [djMixer.loop[6] removeLoadOperation]; // Remove the previous operation if present

            LoadAudioOperation *loadOperation = [[LoadAudioOperation alloc] initWithAudioFile:url];
            [djMixer.loadAudioQueue addOperation:loadOperation];
            [djMixer.loop[6] setLoadOperation:loadOperation];
        }
    }
    if(djMixer.loop[6].loaded)
    {
        totLoadedChannels++;
        float sliderValue = [[channelDict objectForKey:@"AudioVolume"] floatValue];

        [channel7Label setText:[NSString stringWithFormat:@"%@ (%d)", [channelDict objectForKey:@"AudioTitle"], djMixer.loop[6].trackCount]];
        [channel7VolumeSlider setEnabled:YES];
        [channel7VolumeSlider setValue:sliderValue];
        
        [djMixer changeCrossFaderAmount:sliderValue forChannel:7];
    }
    else 
    {
        [channel7Label setText:@""];
        [channel7VolumeSlider setEnabled:NO];
        [channel7VolumeSlider setValue:0.0];
    }

    channelDict = [defaults objectForKey:@"Channel-8"];
    if(channelDict != nil) 
    {
        NSString *url = [channelDict objectForKey:@"AudioUrl"];
        if(url == nil)
        {
            [djMixer.loop[7] freeStuff];
        }
        else
        {
            [djMixer.loop[7] removeLoadOperation]; // Remove the previous operation if present
            
            LoadAudioOperation *loadOperation = [[LoadAudioOperation alloc] initWithAudioFile:url];
            [djMixer.loadAudioQueue addOperation:loadOperation];
            [djMixer.loop[7] setLoadOperation:loadOperation];
        }
    }
    if(djMixer.loop[7].loaded)
    {
        totLoadedChannels++;
        float sliderValue = [[channelDict objectForKey:@"AudioVolume"] floatValue];

        [channel8Label setText:[NSString stringWithFormat:@"%@ (%d)", [channelDict objectForKey:@"AudioTitle"], djMixer.loop[7].trackCount]];
        [channel8VolumeSlider setEnabled:YES];
        [channel8VolumeSlider setValue:sliderValue];
        
        [djMixer changeCrossFaderAmount:sliderValue forChannel:8];
    }
    else 
    {
        [channel8Label setText:@""];
        [channel8VolumeSlider setEnabled:NO];
        [channel8VolumeSlider setValue:0.0];
    }
    
    channelDict = [defaults objectForKey:@"Channel-9"];
    if(channelDict != nil)
    {
        [djMixer.loop[8] audioInput];
        if(djMixer.loop[8].loaded)
        {
            totLoadedChannels++;
            float sliderValue = [[channelDict objectForKey:@"AudioVolume"] floatValue];
            
            [audioInputVolumeSlider setEnabled:YES];
            [audioInputVolumeSlider setValue:sliderValue];
            
            [djMixer changeCrossFaderAmount:sliderValue forChannel:9];
        }
    }
/*
    [playButton setEnabled:(totLoadedChannels != 0)];
    [playButtonLS setEnabled:(totLoadedChannels != 0)];
*/
    [pauseSwitch setEnabled:NO];
    [pauseSwitchLS setEnabled:NO];
   
    [karaokeText setAttributedText:nil];
    [karaokeTextLS setAttributedText:nil];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"KaraokeData.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSLog(@"Karaoke file %@ is available", filePath);
        
        NSArray *data = [NSArray arrayWithContentsOfFile:filePath];
        self.karaoke = [[Karaoke alloc] initKaraoke:data];
    }
    else
    {
        NSLog(@"Karaoke file %@ is missing", filePath);
    }

    [self.karaokeButton setEnabled: (self.karaoke != nil)];
    [self.karaokeButtonLS setEnabled: (self.karaoke != nil)];
    
    self.isPortrait = (self.interfaceOrientation == UIDeviceOrientationPortrait || self.interfaceOrientation == UIDeviceOrientationPortraitUpsideDown);
}


- (void) saveControlsValue
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    int totChannels = sizeof(sliders) / sizeof(UISlider*);
    for(int idx = 1; idx <= totChannels; idx++)
    {
        NSDictionary *channelDict = [defaults objectForKey:[NSString stringWithFormat:@"Channel-%d", idx]];
        if(channelDict != nil)
        {
            NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:channelDict];
            
            [newDict setObject:[NSNumber numberWithFloat:[sliders[idx - 1] value]] forKey:@"AudioVolume"];
            
            // NSLog(@"%@", [NSNumber numberWithFloat:[sliders[idx - 1] value]]);
            
            [defaults setObject:newDict forKey:[NSString stringWithFormat:@"Channel-%d", idx]];
        }
        else
        {
            NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:channelDict];
            
            [newDict setObject:[NSNumber numberWithFloat:0.0] forKey:@"AudioVolume"];
            
            [defaults setObject:newDict forKey:[NSString stringWithFormat:@"Channel-%d", idx]];
        }
    }
    
    [defaults synchronize];
}


- (void) updateDefaults:(UISlider*)slider
{
    // Faster this way...
    static NSUserDefaults *defaults;
    if(defaults == nil)
        defaults = [NSUserDefaults standardUserDefaults];
    
    int idx = slider.tag;
    NSDictionary *channelDict = [defaults objectForKey:[NSString stringWithFormat:@"Channel-%d", idx]];
    if(channelDict != nil)
    {
        NSMutableDictionary *newDict = [NSMutableDictionary dictionaryWithDictionary:channelDict];
            
        [newDict setObject:[NSNumber numberWithFloat:[sliders[idx - 1] value]] forKey:@"AudioVolume"];
            
        [defaults setObject:newDict forKey:[NSString stringWithFormat:@"Channel-%d", idx]];
        
        [defaults synchronize];
    }
}


- (IBAction) changeVolume:(UISlider*)sender
{
/*
    if(sender.tag == 9)
    {
        if(sender.value == 0.0)
        {
            NSLog(@"AUDIO INPUT OFF");
        }
        else
        {
            NSLog(@"AUDIO INPUT ON");
       }
    }
*/    
    [djMixer changeCrossFaderAmount:sender.value forChannel:sender.tag];
    
    // Delay execution of my block for 2 seconds.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), 
    ^{
        [self updateDefaults:sender];
    });
}


- (IBAction) playOrStop
{
	if([djMixer isPlaying])
    {
        [djMixer stop];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if([defaults boolForKey:@"KaraokeAutoOn"] && karaokeActivated)
        {
            [self doKaraoke:nil];
        }

        [playButton setTitle:@"Play" forState:UIControlStateNormal];
        [playButtonLS setTitle:@"Play" forState:UIControlStateNormal];
        
        [selectButton setEnabled:YES];
        [selectButtonLS setEnabled:YES];
        
        [pauseSwitch setEnabled:NO];       
        [pauseSwitchLS setEnabled:NO];
        
        [pauseSwitch setOn:NO];
        [pauseSwitchLS setOn:NO];
        
        [self pause:pauseSwitch];        
    }
    else
    {
        [djMixer play];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if([defaults boolForKey:@"KaraokeAutoOn"] && !karaokeActivated)
        {
            [self doKaraoke:nil];
        }

        [playButton setTitle:@"Stop" forState:UIControlStateNormal];
        [playButtonLS setTitle:@"Stop" forState:UIControlStateNormal];
        
        [selectButton setEnabled:NO];
        [selectButtonLS setEnabled:NO];
        
        [pauseSwitch setEnabled:YES];
        [pauseSwitchLS setEnabled:YES];
    }
}


- (IBAction) goSettings:(UIButton*)sender
{
    if(!self.isPortrait)
    {
		UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Error!"  message:@"The Settings can be accessed only with the Screen in Portrait orientation."
                                                         delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[anAlert show];        
        return;
    }

    SettingsViewController *settings = [[[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil] autorelease];
    assert(settings != nil);
    
    // Custom animated transition
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration: 0.5];    
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view.window cache:YES];
    
    [self presentViewController:settings animated:NO completion:nil];   // Show the new view
    
    [UIView commitAnimations];    // Play the animation
}


- (void)doHighlight:(UIButton*)btn
{
    [btn setHighlighted:YES];
}


- (IBAction) pause:(UISwitch*)sender
{
    [djMixer pause:sender.on];
    
    if(karaokeActivated)
    {
        if(sender.on)
        {
            [self karaokePause];
        }
        else
        {
            [self karaokeResume];
        }
    }
}


- (IBAction) doKaraoke:(UIButton*)sender
{
    if(karaokeActivated)
    {
        [self karaokeStop];
    }
    else
    {
        [self karaokeStart];
    }
}


- (void) karaokeStep
{
    if(self.karaoke.step == 0)
    {
        [karaokeText setAttributedText:self.karaoke.attribText];
        [karaokeText setContentOffset:CGPointMake(0, 1) animated:NO];

        [karaokeTextLS setAttributedText:self.karaoke.attribTextLS];
        [karaokeTextLS setContentOffset:CGPointMake(0, 1) animated:NO];
    }
    else
    {
        BOOL advanced = [self.karaoke advanceRedRow];
        if(advanced)
        {
            // Do for Portrait
            [karaokeText setAttributedText:self.karaoke.attribText];
                
            CGPoint position = [karaokeText contentOffset];                
            CGFloat LINE_HEIGHT = 20.2f;  // Line height is fixed for now (find a way for get it from used font).
            position.y += LINE_HEIGHT;

            [karaokeText setContentOffset:position animated:YES];
 
            // Do for Landscape
            [karaokeTextLS setAttributedText:self.karaoke.attribTextLS];
    
            position = [karaokeTextLS contentOffset];                
            CGFloat LINE_HEIGHT_LS = 31.0f;  // Line height is fixed for now (find a way for get it from used font).
            position.y += LINE_HEIGHT_LS;
                
            [karaokeTextLS setContentOffset:position animated:YES];
        }
        else
        {
            [self.karaokeButton setHighlighted:NO];
            [self.karaokeButtonLS setHighlighted:NO];
            
            [karaokeTimer invalidate];
            karaokeTimer = nil;
            
            return;
        }
    }
    
    if(++self.karaoke.step < self.karaoke.time.count)
    {
        NSTimeInterval newInterval = [[self.karaoke.time objectAtIndex:self.karaoke.step] doubleValue];
        NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:newInterval];
        [karaokeTimer setFireDate:fireDate];
    }
    else
    {
        [self.karaokeButton setHighlighted:NO];
        [self.karaokeButtonLS setHighlighted:NO];

        [karaokeTimer invalidate];
        karaokeTimer = nil;
    }
}


- (void) karaokeStart
{
    [self.karaoke resetRedRow];
    
    [karaokeText setAttributedText:nil];
    [karaokeTextLS setAttributedText:nil];
    
    NSTimeInterval interval = [[self.karaoke.time objectAtIndex:self.karaoke.step] doubleValue];
    karaokeTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(karaokeStep) userInfo:nil repeats:YES];
    
    [self performSelector:@selector(doHighlight:) withObject:self.karaokeButton afterDelay:0];
    [self performSelector:@selector(doHighlight:) withObject:self.karaokeButtonLS afterDelay:0];
    
    karaokeActivated = YES;
}


- (void) karaokeStop
{
    [self.karaokeButton setHighlighted:NO];
    [self.karaokeButtonLS setHighlighted:NO];
    
    [karaokeTimer invalidate];
    karaokeTimer = nil;
    
    karaokeActivated = NO;
}


- (void) karaokePause
{
    karaokePauseStart = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
    
    karaokePrevFireDate = [[karaokeTimer fireDate] retain];
    
    [karaokeTimer setFireDate:[NSDate distantFuture]];
}


- (void) karaokeResume
{
    float pauseTime = -[karaokePauseStart timeIntervalSinceNow];
    
    [karaokeTimer setFireDate:[karaokePrevFireDate initWithTimeInterval:pauseTime sinceDate:karaokePrevFireDate]];
    
    [karaokePauseStart release];
    
    [karaokePrevFireDate release];
}


// Override to allow orientations other than the default portrait orientation.
// Called if iOS < 6
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if(interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight)
    {
        return YES;
    }
    else if(interfaceOrientation == UIDeviceOrientationPortrait)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}


// Override to allow orientations other than the default portrait orientation.
// Called if iOS >= 6
- (NSUInteger)supportedInterfaceOrientations
{
    return (UIInterfaceOrientationMaskPortrait + UIInterfaceOrientationMaskLandscape);
}


// Called if iOS >= 6
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


// Called if iOS >= 6
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
    NSLog(@"to %d", orientation);
    
    if(orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
    {
        self.view = self.landscapeView;
        self.isPortrait = NO;
    }
    else
    {
        self.view = self.portraitView;
        self.isPortrait = YES;
    }
}


// Called if iOS >= 6
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    NSLog(@"from %d to %d", fromInterfaceOrientation, self.interfaceOrientation);
}

@end
