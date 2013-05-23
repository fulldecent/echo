//
//  EchoWordListController.h
//  EnglishStudy
//
//  Created by Will Entriken on 6/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPracticeController.h"
#import "Lesson.h"
#import "Word.h"

@class LessonViewController;

@protocol LessonViewDelegate <NSObject>
- (void)lessonView:(LessonViewController *)controller didSaveLesson:(Lesson *)lesson;
- (void)lessonView:(LessonViewController *)controller wantsToUploadLesson:(Lesson *)lesson;
- (void)lessonView:(LessonViewController *)controller wantsToDeleteLesson:(Lesson *)lesson;
@end

@interface LessonViewController : UITableViewController <WordPracticeDataSource, WordPracticeDelegate, UITextFieldDelegate>
@property (strong, nonatomic) Lesson *lesson;
@property (weak, nonatomic) id <LessonViewDelegate> delegate;
@property (strong, nonatomic) IBOutlet UITextField *lessonLabel;
@property (strong, nonatomic) IBOutlet UITextField *detailLabel;

- (IBAction)lessonShareKitPressed:(id)sender;
- (IBAction)lessonReplyAuthorPressed:(id)sender;
- (IBAction)lessonLikePressed:(id)sender;
- (IBAction)lessonFlagPressed:(id)sender;
- (IBAction)translationReplyAuthorPressed:(id)sender;
- (IBAction)translationLikePressed:(id)sender;
- (IBAction)translationFlagPressed:(id)sender;
- (IBAction)sharePressed:(id)sender;

#pragma mark - WordPracticeDataSource
- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice;
- (BOOL)wordCheckedStateForWordPractice:(WordPracticeController *)wordPractice;

#pragma mark - WordPracticeDelegate
- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice;
- (BOOL)currentWordCanBeCheckedForWordPractice:(WordPracticeController *)wordPractice;
- (void)wordPractice:(WordPracticeController *)wordPractice setWordCheckedState:(BOOL)state;

@end
