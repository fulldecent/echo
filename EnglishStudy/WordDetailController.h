//
//  PHORAddAWordViewController.h
//  EnglishStudy
//
//  Created by Will Entriken on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Word.h"
#import "PHOREchoRecorder.h"

@class WordDetailController;

@protocol WordDetailControllerDelegate <NSObject>
- (NSString *)wordDetailControllerSoundDirectoryFilePath:(WordDetailController *)controller;
- (BOOL)wordDetailController:(WordDetailController *)controller canEditWord:(Word*)word;
@optional
- (void)wordDetailController:(WordDetailController *)controller didSaveWord:(Word *)word;
- (BOOL)wordDetailController:(WordDetailController *)controller canReplyWord:(Word*)word;
@end

@interface WordDetailController : UITableViewController <UITextFieldDelegate, PHOREchoRecorderDelegate>

@property (strong, nonatomic) Word *word;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *actionButton;
- (IBAction)echoButtonPressed:(id)sender;
- (IBAction)echoButtonReset:(id)sender;
- (IBAction)resetButtonPressed:(UIButton *)sender;
- (IBAction)validate;
- (IBAction)updateName:(id)sender;
- (IBAction)updateDetail:(id)sender;
- (IBAction)save;
@property (weak, nonatomic) id <WordDetailControllerDelegate> delegate;
@end
