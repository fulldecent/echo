//
//  GetLessonsViewController.h
//  EnglishStudy
//
//  Created by Will Entriken on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Lesson.h"

@class GetLessonsViewController;

@protocol GetLessonsViewControllerDelegate <NSObject>
- (void)getLessonsController:(GetLessonsViewController *)controller gotStubLesson:(Lesson *)lesson;
@end

@interface GetLessonsViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) id <GetLessonsViewControllerDelegate> delegate;
@end
