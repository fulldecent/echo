//
//  IntroViewController.h
//  Echo
//
//  Created by Will Entriken on 11/24/12.
//
//

#import <UIKit/UIKit.h>
#import "Lesson.h"
#import "DownloadLessonViewController.h"
#import "GAITrackedViewController.h"

@class IntroViewController;

@interface IntroViewController : GAITrackedViewController
@property (weak, nonatomic) id<DownloadLessonViewControllerDelegate> delegate;
- (IBAction)languageButtonClicked:(UIButton *)sender;
@end
