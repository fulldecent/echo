//
//  EchoWordListViewController.h
//  EnglishStudy
//
//  Created by Will Entriken on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WordPracticeController.h"
#import "Lesson.h"
#import "LanguageSelectController.h"
#import "GetLessonsViewController.h"

@interface LessonListViewController : UITableViewController <GetLessonsViewControllerDelegate, LanguageSelectControllerDelegate>
- (IBAction)reload:(UIBarButtonItem *)sender;
- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name;
@end
