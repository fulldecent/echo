    //
//  PHORSecondViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WordPracticeController.h"
#import <AVFoundation/AVFoundation.h>
#import "PHOREchoRecorder.h"
#import <QuartzCore/QuartzCore.h>
#import "Audio.h"
#import <GAI.h>
#import <GAIDictionaryBuilder.h>


@interface WordPracticeController () <PHOREchoRecorderDelegate>
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) PHOREchoRecorder *recorder;
@property (nonatomic) int workflowState;
@property (strong, nonatomic) Word *word;
@end

@implementation WordPracticeController
@synthesize trainingSpeakerButton;
@synthesize datasource = _datasource;
@synthesize delegate = _delegate;
@synthesize audioPlayer = _audioPlayer;
@synthesize workflowState = _workflowState;
@synthesize recorder = _recorder;
@synthesize word = _word;

#define WORKFLOW_DELAY 0.3

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"microphoneLevel"]) {
        self.recordGuage.value = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
    }  
}

- (void)makeItBounce:(UIView *)view
{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1], [NSNumber numberWithFloat:1.2], nil];
    bounceAnimation.duration = 0.15;
    bounceAnimation.removedOnCompletion = NO;
    bounceAnimation.repeatCount = 2;
    bounceAnimation.autoreverses = YES;
    bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

- (IBAction)trainingButtonPressed {
    [self.recorder stopRecordingAndKeepResult:NO];
    [self makeItBounce:self.trainingSpeakerButton];
  
    if (!self.word.files.count) {
        [self.navigationController popViewControllerAnimated:NO];
        return;
    }
    
    int index = arc4random() % [self.word.files count];
    Audio *chosenAudio = [self.word.files objectAtIndex:index];
    NSString *filePath = [chosenAudio filePath];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.pan = -0.5;
    [self.audioPlayer play];
    
    // Workaround because AVURLAsset needs files with file extensions
    // http://stackoverflow.com/questions/9290972/is-it-possible-to-make-avurlasset-work-without-a-file-extension
    NSFileManager *dfm = [NSFileManager defaultManager];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *tmpPath = [[documentPaths lastObject] stringByAppendingPathComponent:@"tmp.caf"];
    [dfm removeItemAtPath:tmpPath error:nil];
    [dfm linkItemAtPath:filePath toPath:tmpPath error:nil];
    
    self.trainingWaveform.audioURL = [NSURL fileURLWithPath:tmpPath];
    self.trainingWaveform.progressSamples = 0;
    [UIView animateWithDuration:self.audioPlayer.duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.trainingWaveform.progressSamples = self.trainingWaveform.totalSamples;
    } completion:^(BOOL done){
        if (done)
            self.trainingWaveform.progressSamples = 0;
    }];
    
    if (self.workflowState == 2 || self.workflowState == 4 || self.workflowState == 6) 
        [self performSelector:@selector(continueNextWorkflowStep:) withObject:nil afterDelay:self.audioPlayer.duration];
}

- (IBAction)recordButtonPressed
{
    [self makeItBounce:self.recordButton];
    [self.recorder record];
    if (self.workflowState == 5 || self.workflowState == 7)
        [self performSelector:@selector(continueNextWorkflowStep:) withObject:nil afterDelay:[self.recorder.duration doubleValue]];
}

- (IBAction)playbackButtonPressed
{
    [self makeItBounce:self.playbackButton];
    [self.recorder playback];
    if (self.workflowState == 5 || self.workflowState == 7)
        [self performSelector:@selector(continueNextWorkflowStep:) withObject:nil afterDelay:[self.recorder.duration doubleValue]];

    [UIView animateWithDuration:self.audioPlayer.duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.playbackWaveform.progressSamples = self.playbackWaveform.totalSamples;
    } completion:^(BOOL done){
        if (done)
            self.playbackWaveform.progressSamples = 0;
    }];
}

- (IBAction)playbackButtonHeld
{
    [self.recorder reset];
    self.recordButton.hidden = NO;
    self.playbackButton.hidden = YES;
    self.checkbox.hidden = YES;
}

- (IBAction)continueNextWorkflowStep:(id)sender
{
    self.workflowState++;    
    
    if (self.workflowState>=9 && [sender isKindOfClass:[UIButton class]]) self.workflowState = 1;
  
    if (self.workflowState==1) {
        [self doFirstWorkflowStep];
    } else if (self.workflowState<=8) {
        [UIView animateWithDuration:WORKFLOW_DELAY*2 animations:^{
            for (int i=2; i<=7; i++)
                [self.view viewWithTag:i].transform = CGAffineTransformIdentity;
            
            [self.view viewWithTag:self.workflowState].transform = CGAffineTransformMakeTranslation(0, (self.workflowState%2==1)?50:-50);
            [self.view viewWithTag:self.workflowState].alpha=0.0;
        }];
        
        if (self.workflowState == 2) {
            [self performSelector:@selector(trainingButtonPressed) withObject:nil afterDelay:WORKFLOW_DELAY];
        } else if (self.workflowState == 3) {
            [self performSelector:@selector(echoButtonPressed) withObject:nil afterDelay:WORKFLOW_DELAY];
        } else if (self.workflowState == 4 || self.workflowState == 6) {
            [self performSelector:@selector(trainingButtonPressed) withObject:nil afterDelay:WORKFLOW_DELAY];
        } else if (self.workflowState == 5 | self.workflowState == 7) {
            [self performSelector:@selector(echoButtonPressed) withObject:nil afterDelay:WORKFLOW_DELAY];
        } else if (self.workflowState == 8) {
            [self resetWorkflow];
        }
    }
}

- (IBAction)resetWorkflow {
    /*
    self.workflowState = 99;
    
    [UIView animateWithDuration:WORKFLOW_DELAY animations:^{
        for (int i=2; i<=8; i++)
            [self.view viewWithTag:i].alpha=1;
        for (int i=2; i<=7; i++)
            [self.view viewWithTag:i].transform = CGAffineTransformIdentity;
        self.workflowButton.alpha=1;
    }];
     */
}

- (IBAction)checkPressed:(id)sender {
    BOOL checked = ![self.datasource wordCheckedStateForWordPractice:self];
    [self.delegate wordPractice:self setWordCheckedState:checked];
    if (checked)
        [self.checkbox setImage:[UIImage imageNamed:@"checkon"] forState:UIControlStateNormal];
    else
        [self.checkbox setImage:[UIImage imageNamed:@"check"] forState:UIControlStateNormal];
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Usage"
                                                          action:@"Learning"
                                                           label:@"Checked word"
                                                           value:@(checked)] build]];
}

- (IBAction)fastForwardPressed {
    // see http://stackoverflow.com/questions/8926606/performseguewithidentifier-vs-instantiateviewcontrollerwithidentifier
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    WordPracticeController *newWordPractice = [storyboard instantiateViewControllerWithIdentifier:@"WordPractice"];
    [self.delegate skipToNextWordForWordPractice:self];
    newWordPractice.datasource = self.datasource;
    newWordPractice.delegate = self.delegate;
    
    // see http://stackoverflow.com/questions/410471/how-can-i-pop-a-view-from-a-uinavigationcontroller-and-replace-it-with-another-i
                                               
    // locally store the navigation controller since
    // self.navigationController will be nil once we are popped
    UINavigationController *navController = self.navigationController;
    
    // retain ourselves so that the controller will still exist once it's popped off
    //   id mySelf = self;
    //  mySelf;
    
    // Pop this controller and replace with another
    [navController popViewControllerAnimated:NO];
    [navController pushViewController:newWordPractice animated:YES];
}

- (void)doFirstWorkflowStep {
    /*
    [UIView animateWithDuration:WORKFLOW_DELAY animations:^{
        for (int i=2; i<=7; i++)
            [self.view viewWithTag:i].alpha=1;
        for (int i=2; i<=7; i++)
            [self.view viewWithTag:i].transform = CGAffineTransformIdentity;
        self.workflowButton.alpha=0;
    }];
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource:@"Next" ofType:@"aif"]];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.pan = 0;
    [self.audioPlayer play];
        
    [self performSelector:@selector(continueNextWorkflowStep:) withObject:nil afterDelay:self.audioPlayer.duration];
     */
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.word = [self.datasource currentWordForWordPractice:self];
    self.title = self.word.name;
    self.wordTitle.text = self.word.name;
    self.wordDetail.text = self.word.detail;
    self.recorder = [[PHOREchoRecorder alloc] init];
    [self.recorder addObserver:self forKeyPath:@"microphoneLevel" options:NSKeyValueObservingOptionNew context:nil];
    self.recorder.pan = [NSNumber numberWithFloat:0.5];
    self.recorder.delegate = self;
    
    [self.trainingSpeakerButton addSubview:self.trainingWaveform];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.trainingSpeakerButton.imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.trainingWaveform attribute:NSLayoutAttributeLeft multiplier:1 constant:8]];
    [self.playbackButton addSubview:self.playbackWaveform];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.playbackButton.imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.playbackWaveform attribute:NSLayoutAttributeLeft multiplier:1 constant:8]];
    [self.recordButton addSubview:self.recordGuage];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.recordButton.imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.recordGuage attribute:NSLayoutAttributeLeft multiplier:1 constant:8]];
    
    NSMutableArray *rightBarButtonItems = [[NSMutableArray alloc] init];
    if ([self.delegate wordPracticeShouldShowNextButton:self]) {
        UIBarButtonItem *fastForward = self.navigationItem.rightBarButtonItem;
        [rightBarButtonItems addObject:fastForward];
    }
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    
    /*
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
//    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
//    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,
  //                          sizeof(audioRouteOverride), &audioRouteOverride);
*/
    
    // see http://stackoverflow.com/questions/2246374/low-recording-volume-in-combination-with-avaudiosessioncategoryplayandrecord
    NSError *setCategoryErr = nil;
    NSError *activationErr  = nil;
    //Set the general audio session category
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: &setCategoryErr];
    
    //Make the default sound route for the session be to use the speaker
    UInt32 doChangeDefaultRoute = 1;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof (doChangeDefaultRoute), &doChangeDefaultRoute);
    
    //Activate the customized audio session
    [[AVAudioSession sharedInstance] setActive: YES error: &activationErr];
    
    [self performSelector:@selector(trainingButtonPressed) withObject:self afterDelay:0.5];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.screenName = @"WordPracticeController";
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.recorder removeObserver:self forKeyPath:@"microphoneLevel"];
    [super viewWillDisappear:animated];
}

#pragma mark PHOREchoRecorderDelegate

- (void)recording:(id)recorder didFinishSuccessfully:(BOOL)success
{
    if (success) {
        self.recordButton.hidden = YES;
        self.playbackButton.hidden = NO;
        self.playbackWaveform.audioURL = [NSURL fileURLWithPath:[self.recorder getAudioDataFilePath]];
        [self.playbackWaveform setNeedsLayout]; // TODO: BUG UPSTREAM
        
        if ([self.delegate currentWordCanBeCheckedForWordPractice:self]) {
            BOOL checked = [self.datasource wordCheckedStateForWordPractice:self];
            if (checked)
                [self.checkbox setImage:[UIImage imageNamed:@"checkon"] forState:UIControlStateNormal];
            else
                [self.checkbox setImage:[UIImage imageNamed:@"check"] forState:UIControlStateNormal];
            self.checkbox.hidden = NO;
        }
        
        if (self.workflowState == 3) 
            [self continueNextWorkflowStep:nil];
    } else {
        if (self.workflowState == 3)
            [self resetWorkflow];
    }
}

@end
