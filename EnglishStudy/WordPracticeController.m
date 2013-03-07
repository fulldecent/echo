//
//  PHORSecondViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WordPracticeController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>
#import "UIGlossyButton.h"
#import "PHOREchoRecorder.h"

@interface WordPracticeController () <PHOREchoRecorderDelegate>
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) PHOREchoRecorder *recorder;
@property (nonatomic) int workflowState;
@property (strong, nonatomic) Word *word;
@end

@implementation WordPracticeController
@synthesize starButton;
@synthesize trainingSpeakerButton;
@synthesize echoRecordButton;
@synthesize backgroundImage;
@synthesize workflowButton;

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
        self.echoRecordButton.value = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
    }  
}

- (IBAction)trainingSpeakerPressed {
    [self.recorder stopRecordingAndKeepResult:NO];
    
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1], [NSNumber numberWithFloat:1.2], nil];
    bounceAnimation.duration = 0.15;
    bounceAnimation.removedOnCompletion = NO;
    bounceAnimation.repeatCount = 2;
    bounceAnimation.autoreverses = YES;
    bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.trainingSpeakerButton.layer addAnimation:bounceAnimation forKey:@"bounce"];
    
    int index = arc4random() % [self.word.files count];
    NSString *filePath = [[self.datasource currentSoundDirectoryFilePath] stringByAppendingPathComponent:[self.word.files objectAtIndex:index]];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.pan = -0.5;
    [self.audioPlayer play];
    
    if (self.workflowState == 2 || self.workflowState == 4 || self.workflowState == 6) 
        [self performSelector:@selector(continueNextWorkflowStep:) withObject:nil afterDelay:self.audioPlayer.duration];
}

- (IBAction)echoButtonPressed {
    if (self.echoRecordButton.state == PHORRecordButtonStateRecord) {
        [self.recorder record];
    } else if (self.echoRecordButton.state == PHORRecordButtonStatePlayback) {
        [self.recorder playback];
    }

    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1], [NSNumber numberWithFloat:1.2], nil];
    bounceAnimation.duration = 0.15;
    bounceAnimation.removedOnCompletion = NO;
    bounceAnimation.repeatCount = 2;
    bounceAnimation.autoreverses = YES;
    bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.echoRecordButton.layer addAnimation:bounceAnimation forKey:@"bounce"];
    
    if (self.workflowState == 5 || self.workflowState == 7) 
        [self performSelector:@selector(continueNextWorkflowStep:) withObject:nil afterDelay:[self.recorder.duration doubleValue]];
}

- (IBAction)echoButtonReset:(id)sender
{
    [self.recorder reset];
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
            [self performSelector:@selector(trainingSpeakerPressed) withObject:nil afterDelay:WORKFLOW_DELAY];
        } else if (self.workflowState == 3) {
            [self performSelector:@selector(echoButtonPressed) withObject:nil afterDelay:WORKFLOW_DELAY];
        } else if (self.workflowState == 4 || self.workflowState == 6) {
            [self performSelector:@selector(trainingSpeakerPressed) withObject:nil afterDelay:WORKFLOW_DELAY];
        } else if (self.workflowState == 5 | self.workflowState == 7) {
            [self performSelector:@selector(echoButtonPressed) withObject:nil afterDelay:WORKFLOW_DELAY];
        } else if (self.workflowState == 8) {
            [self resetWorkflow];
        }
    }
}

- (IBAction)resetWorkflow {
    self.workflowState = 99;
    
    [UIView animateWithDuration:WORKFLOW_DELAY animations:^{
        for (int i=2; i<=8; i++)
            [self.view viewWithTag:i].alpha=1;
        for (int i=2; i<=7; i++)
            [self.view viewWithTag:i].transform = CGAffineTransformIdentity;
        self.workflowButton.alpha=1;
    }];
}

- (IBAction)checkPressed:(id)sender {
    UIBarButtonItem *check = [self.navigationItem.rightBarButtonItems objectAtIndex:1];
    
    BOOL checked = ![self.datasource wordCheckedStateForWordPractice:self];
    [self.delegate wordPractice:self setWordCheckedState:checked];
    if (checked)
        [check setImage:[UIImage imageNamed:@"checkon"]];
    else
        [check setImage:[UIImage imageNamed:@"check"]];
}

- (IBAction)fastForwardPressed:(id)sender {
    // see http://stackoverflow.com/questions/8926606/performseguewithidentifier-vs-instantiateviewcontrollerwithidentifier
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    WordPracticeController *newWordPractice = [storyboard instantiateViewControllerWithIdentifier:@"wordPractice"];
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
    
    self.echoRecordButton.state = PHORRecordButtonStateRecord;
    
    [self performSelector:@selector(continueNextWorkflowStep:) withObject:nil afterDelay:self.audioPlayer.duration];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

/*
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            [self.backgroundImage setImage:[UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"iPhoneBG" ofType:@"png"]]];
        else
            [self.backgroundImage setImage:[UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Default-Portrait" ofType:@"png"]]];
    } else {
        [self.backgroundImage setImage:[UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Default-Landscape" ofType:@"png"]]];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        self.backgroundImage.transform = CGAffineTransformIdentity;
    else 
        self.backgroundImage.transform = CGAffineTransformMakeTranslation(0, 20);
}
*/


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.word = [self.datasource currentWordForWordPractice:self];
    self.title = self.word.name;
    [self.trainingSpeakerButton setTitle:self.title forState:UIControlStateNormal];
    [self.echoRecordButton setTitle:self.title forState:UIControlStateNormal];    
    [self willAnimateRotationToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
    [super viewDidLoad];
    
    self.recorder = [[PHOREchoRecorder alloc] init];
    [self.recorder addObserver:self forKeyPath:@"microphoneLevel" options:NSKeyValueObservingOptionNew context:nil];
    self.recorder.pan = [NSNumber numberWithFloat:0.5];
    self.recorder.delegate = self;
    
    UIGlossyButton *b;
    b = (UIGlossyButton *) self.trainingSpeakerButton;
	b.tintColor = [UIColor greenColor];
	[b useWhiteLabel: YES];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 5.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 12.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];

    b = (UIGlossyButton*) self.echoRecordButton;
	b.tintColor = [UIColor grayColor];
	[b useWhiteLabel: YES];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 5.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 12.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
    
    b = (UIGlossyButton*) self.workflowButton;
	b.tintColor = [UIColor whiteColor];
	[b useWhiteLabel: YES];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 5.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 12.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
    
    // Auto play circles
    b = (UIGlossyButton*) [self.view viewWithTag: 2];
	b.tintColor = [UIColor greenColor];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 15.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 50.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];

    b = (UIGlossyButton*) [self.view viewWithTag: 3];
	b.tintColor = [UIColor grayColor];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 15.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 50.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];

    b = (UIGlossyButton*) [self.view viewWithTag: 4];
	b.tintColor = [UIColor greenColor];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 15.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 50.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];

    b = (UIGlossyButton*) [self.view viewWithTag: 5];
	b.tintColor = [UIColor grayColor];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 15.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 50.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];

    b = (UIGlossyButton*) [self.view viewWithTag: 6];
	b.tintColor = [UIColor greenColor];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 15.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 50.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];

    b = (UIGlossyButton*) [self.view viewWithTag: 7];
	b.tintColor = [UIColor grayColor];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 15.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 50.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];

    if ([self.delegate currentWordCanBeCheckedForWordPractice:self]) {
        // Set up two bar button items
        UIBarButtonItem *fastForward = self.navigationItem.rightBarButtonItem;
        UIImage *checkImage;
        if ([self.datasource wordCheckedStateForWordPractice:self])
            checkImage = [UIImage imageNamed:@"checkon"];
        else
            checkImage = [UIImage imageNamed:@"check"];
        UIBarButtonItem *check = [[UIBarButtonItem alloc] initWithImage:checkImage landscapeImagePhone:checkImage style:UIBarButtonItemStylePlain target:self action:@selector(checkPressed:)];
        self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:fastForward, check, nil];
    }
    
    
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
    
    [self performSelector:@selector(trainingSpeakerPressed) withObject:self afterDelay:0.5];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self setBackgroundImage:nil];
    [self setWorkflowButton:nil];
    [self setStarButton:nil];
    self.recorder = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.recorder removeObserver:self forKeyPath:@"microphoneLevel"];    
}

#pragma mark PHOREchoRecorderDelegate

- (void)recording:(id)recorder didFinishSuccessfully:(BOOL)success
{
    if (success) {
        self.echoRecordButton.state = PHORRecordButtonStatePlayback;
        
        if (self.workflowState == 3) 
            [self continueNextWorkflowStep:nil];
    } else {
        if (self.workflowState == 3)
            [self resetWorkflow];
    }
}

@end
