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

@class WordPracticeController;

@protocol WordPracticeDataSource
- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice;
- (NSString *)currentSoundDirectoryFilePath;
- (BOOL)wordCheckedStateForWordPractice:(WordPracticeController *)wordPractice;
@end

@protocol WordPracticeDelegate
- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice;
- (BOOL)currentWordCanBeCheckedForWordPractice:(WordPracticeController *)wordPractice;
- (BOOL)wordPracticeShouldShowNextButton:(WordPracticeController *)wordPractice;
- (void)wordPractice:(WordPracticeController *)wordPractice setWordCheckedState:(BOOL)state;
@end

@interface WordPracticeController : UIViewController;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (strong, nonatomic) IBOutlet UIButton *trainingSpeakerButton;
@property (strong, nonatomic) IBOutlet PHOREchoRecordButton *echoRecordButton;
@property (strong, nonatomic) IBOutlet UIButton *workflowButton;
@property (strong, nonatomic) IBOutlet UITextView *wordDetail;
@property (weak, nonatomic) id <WordPracticeDataSource> datasource;
@property (weak, nonatomic) id <WordPracticeDelegate> delegate;

- (IBAction)trainingSpeakerPressed;
- (IBAction)echoButtonPressed;
- (IBAction)echoButtonReset:(id)sender;
- (IBAction)continueNextWorkflowStep:(id)sender;
- (IBAction)resetWorkflow;
- (IBAction)fastForwardPressed:(id)sender;

@end
