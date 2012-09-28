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
- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice;
@end

@interface WordPracticeController : UIViewController;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *starButton;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (strong, nonatomic) IBOutlet UIButton *trainingSpeakerButton;
@property (strong, nonatomic) IBOutlet PHOREchoRecordButton *echoRecordButton;
@property (strong, nonatomic) IBOutlet UIButton *workflowButton;
@property (weak, nonatomic) id <WordPracticeDataSource> datasource;

- (IBAction)trainingSpeakerPressed;
- (IBAction)echoButtonPressed;
- (IBAction)echoButtonReset:(id)sender;
- (IBAction)continueNextWorkflowStep:(id)sender;
- (IBAction)resetWorkflow;
- (IBAction)fastForwardPressed:(id)sender;

@end
