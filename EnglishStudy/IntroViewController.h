//
//  IntroViewController.h
//  Echo
//
//  Created by Will Entriken on 11/24/12.
//
//

#import <UIKit/UIKit.h>
#import "UIGlossyButton.h"
#import "Lesson.h"

@class IntroViewController;

@protocol IntroViewControllerDelegate <NSObject>
- (void)introViewController:(IntroViewController *)controller gotStubLesson:(Lesson *)lesson;
#warning reuse downloadviewcontrollerdelegate
@end

@interface IntroViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *nameField;
@property (strong, nonatomic) IBOutletCollection(UIGlossyButton) NSArray *languageButtons;
@property (weak, nonatomic) id<IntroViewControllerDelegate> delegate;
- (IBAction)nameChanged:(UITextField *)sender;
- (IBAction)languageButtonClicked:(UIButton *)sender;
@end
