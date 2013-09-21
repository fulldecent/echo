//
//  LessonInformationViewController.h
//  Echo
//
//  Created by Will Entriken on 8/18/12.
//
//

#import <UIKit/UIKit.h>
#import "Lesson.h"

@class LessonInformationViewController;

@protocol LessonInformationViewDelegate <NSObject>
- (void)lessonInformationView:(LessonInformationViewController *)controller didSaveLesson:(Lesson *)lesson;
@end

@interface LessonInformationViewController : UITableViewController <UITextFieldDelegate>
@property (strong, nonatomic) Lesson *lesson;
@property (weak, nonatomic) id <LessonInformationViewDelegate> delegate;

@property (strong, nonatomic) IBOutlet UILabel *languageName;
@property (strong, nonatomic) IBOutlet UILabel *lessonLabel;
@property (strong, nonatomic) IBOutlet UITextField *lessonName;
@property (strong, nonatomic) IBOutlet UILabel *detailLabel;
@property (strong, nonatomic) IBOutlet UITextField *detailText;



- (IBAction)updateName:(UITextField *)sender;
- (IBAction)updateDetail:(UITextField *)sender;
- (IBAction)save:(id)sender;
@end
