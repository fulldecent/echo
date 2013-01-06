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
#import "LanguageSelectController.h"

@class LessonViewController;

@protocol LessonViewDelegate <NSObject>
- (void)lessonView:(LessonViewController *)controller didSaveLesson:(Lesson *)lesson;
- (void)lessonView:(LessonViewController *)controller wantsToUploadLesson:(Lesson *)lesson;
- (void)lessonView:(LessonViewController *)controller wantsToDeleteLesson:(Lesson *)lesson;
@end

@interface LessonViewController : UITableViewController <WordPracticeDataSource, WordPracticeDelegate, LanguageSelectControllerDelegate, UITextFieldDelegate>
@property (strong, nonatomic) Lesson *lesson;
@property (weak, nonatomic) id <LessonViewDelegate> delegate;

- (IBAction)sendToFriendPressed:(id)sender;
- (IBAction)messagePressed:(id)sender;
- (IBAction)likePressed:(id)sender;
- (IBAction)flagPressed:(id)sender;
- (IBAction)share:(id)sender;

#pragma mark - WordPracticeDataSource
- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice;
- (NSString *)currentSoundDirectoryFilePath;
- (BOOL)wordCheckedStateForWordPractice:(WordPracticeController *)wordPractice;

#pragma mark - WordPracticeDelegate
- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice;
- (BOOL)currentWordCanBeCheckedForWordPractice:(WordPracticeController *)wordPractice;
- (void)wordPractice:(WordPracticeController *)wordPractice setWordCheckedState:(BOOL)state;

@end
