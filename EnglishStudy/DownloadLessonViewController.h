//
//  DownloadLessonsViewController.h
//  Echo
//
//  Created by Will Entriken on 2/11/13.
//
//

#import <UIKit/UIKit.h>
#import "Lesson.h"

@class DownloadLessonViewController;

@protocol DownloadLessonViewControllerDelegate <NSObject>
- (void)downloadLessonViewController:(UIViewController *)controller gotStubLesson:(Lesson *)lesson;
@end

@interface DownloadLessonViewController : UITableViewController
@property (weak, nonatomic) id<DownloadLessonViewControllerDelegate> delegate;
@end
