//
//  PHORSecondViewController.h
//  EnglishStudy
//
//  Created by Will Entriken on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "F3BarGauge.h"
#import "PHOREchoRecordButton.h"
#import "Word.h"
#import "GAITrackedViewController.h"
#import "FDWaveformView.h"

@class WordPracticeController;

@protocol WordPracticeDataSource
- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice;
- (BOOL)wordCheckedStateForWordPractice:(WordPracticeController *)wordPractice;
@end

@protocol WordPracticeDelegate
- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice;
- (BOOL)currentWordCanBeCheckedForWordPractice:(WordPracticeController *)wordPractice;
- (BOOL)wordPracticeShouldShowNextButton:(WordPracticeController *)wordPractice;
- (void)wordPractice:(WordPracticeController *)wordPractice setWordCheckedState:(BOOL)state;
@end

@interface WordPracticeController : GAITrackedViewController;
@property (strong, nonatomic) IBOutlet UILabel *wordTitle;
@property (strong, nonatomic) IBOutlet UITextView *wordDetail;
@property (strong, nonatomic) IBOutlet UIButton *trainingSpeakerButton;
@property (strong, nonatomic) IBOutlet FDWaveformView *trainingWaveform;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet UIButton *playbackButton;
@property (strong, nonatomic) IBOutlet FDWaveformView *playbackWaveform;
@property (weak, nonatomic) id <WordPracticeDataSource> datasource;
@property (weak, nonatomic) id <WordPracticeDelegate> delegate;

- (IBAction)trainingButtonPressed;
- (IBAction)recordButtonPressed;
- (IBAction)playbackButtonPressed;
- (IBAction)playbackButtonHeld;
- (IBAction)resetWorkflow;
- (IBAction)fastForwardPressed:(id)sender;

@end
