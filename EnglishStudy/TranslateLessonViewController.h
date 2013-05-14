//
//  TranslateLessonViewController.h
//  Echo
//
//  Created by Will Entriken on 4/28/13.
//
//

#import <UIKit/UIKit.h>
#import "Lesson.h"

@class TranslateLessonViewController;

@protocol TranslateLessonDataSource
- (Lesson *)lessonToTranslateForTranslateLessonView:(TranslateLessonViewController *)controller;
- (void)translateLessonView:(TranslateLessonViewController *)controller didTranslate:(Lesson *)lesson into:(Lesson *)newLesson withLanguageTag:(NSString *)tag;
@end

@interface TranslateLessonViewController : UITableViewController
@property (weak, nonatomic) id<TranslateLessonDataSource> datasource;
- (IBAction)save:(id)sender;
@end