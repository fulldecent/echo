//
//  PHORFirstViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GuessingViewController.h"
#import "SoundGuessingGame.h"
#import <AVFoundation/AVFoundation.h>
#import "UIGlossyButton.h"

@interface GuessingViewController ()
@property (nonatomic, strong) SoundGuessingGame *game;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
- (void)loadQuestion;
@end

@implementation GuessingViewController
@synthesize numberOfCorrect = _numberOfCorrect;
@synthesize numberOfTotal = _numberOfTotal;
@synthesize separator = _separator;
@synthesize backgroundImage = _backgroundImage;
@synthesize playButton = _playPressed;
@synthesize option1Button = _option1Button;
@synthesize option2Button = _option2Button;
@synthesize option3Button = _option3Button;
@synthesize option4Button = _option4Button;
@synthesize game = _game;
@synthesize audioPlayer = _audioPlayer;

- (SoundGuessingGame *)game
{
    if (!_game) _game = [[SoundGuessingGame alloc] init];
    return _game;
}

- (void)playSoundPressed
{
    NSURL *url = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource:self.game.currentSound ofType:@""]];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [self.audioPlayer play];
    
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1], [NSNumber numberWithFloat:1.2], nil];
    bounceAnimation.duration = 0.15;
    bounceAnimation.removedOnCompletion = NO;
    bounceAnimation.repeatCount = 2;
    bounceAnimation.autoreverses = YES;    
    bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.playButton.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

- (IBAction)optionPressed:(UIButton *)sender {
    NSInteger option = [sender tag]-1;
    NSInteger correctAnswer = [self.game makeGuess:option];
    BOOL correct = correctAnswer == option;
 
#define FULLPOINTS 10.0
    UIColor *color = [UIColor colorWithHue:self.game.correctAnswers*1.0/3.0/FULLPOINTS
                                saturation:1.0
                                brightness:1.0
                                     alpha:1.0];
    
    self.numberOfCorrect.text = [NSString stringWithFormat:@"%i", self.game.correctAnswers, nil];
    self.numberOfCorrect.textColor = color;
    self.numberOfCorrect.alpha = 1;
    self.numberOfTotal.text = [NSString stringWithFormat:@"%i", self.game.totalAnswers, nil];
    self.numberOfTotal.alpha = 1;
    self.separator.alpha = 1;
        
    // KEYFRAME ANIMATE CORRECT / INCORRECT SCORE COUNT
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.5], [NSNumber numberWithFloat:1.1], 
                              [NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:1.0], nil];
    bounceAnimation.duration = 0.3;
    bounceAnimation.removedOnCompletion = NO;
        
    if (correct) [self.numberOfCorrect.layer addAnimation:bounceAnimation forKey:@"bounce"];
    else [self.numberOfTotal.layer addAnimation:bounceAnimation forKey:@"bounce"];
    
    // KEYFRAME ANIMATE EACH OPTION
    CAKeyframeAnimation *fadeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1], [NSNumber numberWithFloat:0.3], 
                              [NSNumber numberWithFloat:0.3], [NSNumber numberWithFloat:1.0], nil];
    fadeAnimation.duration = 1.0;
    fadeAnimation.removedOnCompletion = NO;
    
    for (int i=0; i<self.game.currentQuestion.count; i++) {
        if (i != correctAnswer) {
            [[self.view viewWithTag:i+1].layer addAnimation:fadeAnimation forKey:@"fade"];
            [(UIButton *)[self.view viewWithTag:i+1] setTitle:@"" forState:UIControlStateNormal];
            if ([self.view viewWithTag:i+1] == sender) {
                sender.tintColor = [UIColor redColor];
            }
        }
        else if ([self.view viewWithTag:i+1] == sender) {
            sender.tintColor = [UIColor greenColor];
        }
    }
    
    // END OF GAME -- FADE OUT SCORE COUNT
    if (!self.game.gameInProgress) {
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1.0], [NSNumber numberWithFloat:1.5], 
                                  [NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1.0], nil];
        bounceAnimation.duration = 0.6;
        bounceAnimation.removedOnCompletion = NO;
        
        [self.numberOfCorrect.layer addAnimation:bounceAnimation forKey:@"bounce"];
        [self.separator.layer addAnimation:bounceAnimation forKey:@"bounce"];
        [self.numberOfTotal.layer addAnimation:bounceAnimation forKey:@"bounce"];
        
        [UIView animateWithDuration:1 animations:^{self.numberOfCorrect.alpha = 0;}];
        [UIView animateWithDuration:1 animations:^{self.separator.alpha = 0;}];
        [UIView animateWithDuration:1 animations:^{self.numberOfTotal.alpha = 0;}];
    }
    
    [self performSelector:@selector(loadQuestion) withObject:self afterDelay:1.0];
//    [self loadQuestion];
}

- (void)loadQuestion
{
    NSArray *question = self.game.currentQuestion;
    
    for (int i=1; i<=question.count; i++) {
        [self.view viewWithTag:i].hidden = NO;
        [(UIButton *)[self.view viewWithTag:i] setTitle:[question objectAtIndex:i-1] forState:UIControlStateNormal];
        [(UIButton *)[self.view viewWithTag:i] setTintColor:[UIColor blackColor]];
        [[self.view viewWithTag:i] setNeedsDisplay];
    }
    
    for (int i=question.count+1; i<=4; i++) {
        [self.view viewWithTag:i].hidden = YES;
    }
       
    if (self.game.gameInProgress) [self playSoundPressed];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            [self.backgroundImage setImage:[UIImage imageWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"Default" ofType:@"png"]]];
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

- (void)viewDidLoad
{
    [self willAnimateRotationToInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation] duration:0];
    [super viewDidLoad];
    
	UIGlossyButton *b;
    b = (UIGlossyButton*) [self.view viewWithTag: 1];
	b.tintColor = [UIColor blackColor];
	[b useWhiteLabel: YES];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 5.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 12.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
    
    b = (UIGlossyButton*) [self.view viewWithTag: 2];
	b.tintColor = [UIColor blackColor];
	[b useWhiteLabel: YES];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 5.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 12.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
    
    b = (UIGlossyButton*) [self.view viewWithTag: 3];
	b.tintColor = [UIColor blackColor];
	[b useWhiteLabel: YES];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 5.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 12.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
    
    b = (UIGlossyButton*) [self.view viewWithTag: 4];
	b.tintColor = [UIColor blackColor];
	[b useWhiteLabel: YES];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 5.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 12.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
    
    b = (UIGlossyButton*) [self.view viewWithTag: 9];
	b.tintColor = [UIColor greenColor];
	[b useWhiteLabel: YES];
	b.backgroundOpacity = 0.7;
	b.innerBorderWidth = 5.0f;
	b.buttonBorderWidth = 0.0f;
	b.buttonCornerRadius = 12.0f;
	[b setGradientType: kUIGlossyButtonGradientTypeSolid];
	[b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
    
    [self loadQuestion];

}

/*
- (void)awakeFromNib
{   
    [super awakeFromNib];
    [self loadQuestion];
} */

- (void)viewDidUnload
{
    [self setGame:nil];
    [self setPlayButton:nil];
    [self setOption1Button:nil];
    [self setOption2Button:nil];
    [self setOption3Button:nil];
    [self setOption4Button:nil];
    [self setNumberOfCorrect:nil];
    [self setNumberOfTotal:nil];
    [self setSeparator:nil];
    [self setBackgroundImage:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

@end
