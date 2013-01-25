//
//  DJMixerViewController.mm
//  MusicApp
//
//  Created by Luca Severini on 6/1/2012.
//

#import "DJMixer.h"
#import "DJMixerViewController.h"
#import "SelectionViewController.h"
#import "CoreText/CoreText.h"
#import "UITextScroll.h"
#import "Karaoke.h"

@implementation DJMixerViewController

@synthesize djMixer;
@synthesize playButton;
@synthesize pauseSwitch;
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
@synthesize selectButton;
@synthesize karaokeButton;
@synthesize karaokeText;
@synthesize karaoke;
@synthesize karaokeTimer;

- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self != nil)
    {
    }
    
    return self;
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
    
    [karaokeTimer invalidate];
    karaokeTimer = nil;

    [self.karaoke release];
    self.karaoke = nil;
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
            [djMixer.loop[0] freeBuffers];
        }
        else
        {
            [djMixer.loop[0] mediaItemUrl:url];
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
            [djMixer.loop[1] freeBuffers];
        }
        else
        {
            [djMixer.loop[1] mediaItemUrl:url];
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
            [djMixer.loop[2] freeBuffers];
        }
        else
        {
            [djMixer.loop[2] mediaItemUrl:url];
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
            [djMixer.loop[3] freeBuffers];
        }
        else
        {
            [djMixer.loop[3] mediaItemUrl:url];
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
            [djMixer.loop[4] freeBuffers];
        }
        else
        {
            [djMixer.loop[4] mediaItemUrl:url];
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
            [djMixer.loop[5] freeBuffers];
        }
        else
        {
            [djMixer.loop[5] mediaItemUrl:url];
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
            [djMixer.loop[6] freeBuffers];
        }
        else
        {
            [djMixer.loop[6] mediaItemUrl:url];
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
            [djMixer.loop[7] freeBuffers];
        }
        else
        {
            [djMixer.loop[7] mediaItemUrl:url];
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

    [playButton setEnabled:(totLoadedChannels != 0)];
    [pauseSwitch setEnabled:NO];
    
    [karaokeText setAttributedText:nil];
    
    self.karaoke = [[Karaoke alloc] initKaraoke:nil timing:nil];
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
    dispatch_async(dispatch_get_current_queue(), 
    ^{
        [self updateDefaults:sender];
    });
}


- (IBAction) pause:(UISwitch*)sender
{
    [djMixer pause:sender.on];
}


- (IBAction) playOrStop
{
	if([djMixer isPlaying])
    {
        [djMixer stop];
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
        
        [selectButton setEnabled:YES];
        [pauseSwitch setEnabled:NO];
       
        [pauseSwitch setOn:NO];
        [self pause:pauseSwitch];
    }
    else
    {
        [djMixer play];
        [playButton setTitle:@"Stop" forState:UIControlStateNormal];
        
        [selectButton setEnabled:NO];
        [pauseSwitch setEnabled:YES];
    }
}


- (IBAction) selectTracks:(UIButton*)sender
{
    if(selViewController == nil)
    {
        selViewController = [[SelectionViewController alloc] initWithNibName:@"SelectionView" bundle:nil];
        assert(selViewController != nil);
    }
    
    // Custom animated transition
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration: 0.5];    
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view.window cache:YES];
    
    [self presentModalViewController:selViewController animated:NO];   // Show the new view
    
    [UIView commitAnimations];    // Play the animation
    
    // self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;  // Set the style for the transition when is back
    
    // selViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;  // Set the animation transition style    
    // [self presentModalViewController:selViewController animated:YES];               // Show the new view
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}


- (void) didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void) dealloc 
{
    if(selViewController != nil)
    {
        [selViewController release];
        selViewController = nil;
    }
        
    [super dealloc];
}


- (IBAction) doKaraoke:(UIButton*)sender
{
    if(karaokeTimer == nil)
    {
        [self.karaoke resetRedRow];
        
        [karaokeText setAttributedText:nil];
    
        NSTimeInterval interval = [[self.karaoke.time objectAtIndex:self.karaoke.step] doubleValue];
        karaokeTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(karaokeStep) userInfo:nil repeats:YES];
    }
}


- (void)karaokeStep
{
    if(self.karaoke.step == 0)
    {
        [karaokeText setAttributedText:self.karaoke.attribText];
  
        [karaokeText setContentOffset:CGPointMake(0, 1) animated:NO];
    }
    else
    {
        BOOL advanced = [self.karaoke advanceRedRow];
        if(advanced)
        {
            [karaokeText setAttributedText:self.karaoke.attribText];
            
            CGPoint position = [karaokeText contentOffset];
            
            CGFloat LINE_HEIGHT = 20.2f;  // Line height is fixed for now (find a way for get it from used font).
            position.y += LINE_HEIGHT;

            [karaokeText setContentOffset:position animated:YES];
        }
        else
        {        
            [karaokeTimer invalidate];
            karaokeTimer = nil;
            
            return;
        }
    }
    
    self.karaoke.step++;
    
    NSTimeInterval newInterval = [[self.karaoke.time objectAtIndex:self.karaoke.step] doubleValue];
    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:newInterval];
    [karaokeTimer setFireDate:fireDate];
}

@end
