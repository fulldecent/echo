//
//  IntroViewController.h
//  Echo
//
//  Created by Will Entriken on 11/24/12.
//
//

#import <UIKit/UIKit.h>
#import "UIGlossyButton.h"

@interface IntroViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *nameField;
- (IBAction)nameChanged:(UITextField *)sender;
@property (strong, nonatomic) IBOutletCollection(UIGlossyButton) NSArray *languageButtons;

@end
