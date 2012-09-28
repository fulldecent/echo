//
//  PHORFirstViewController.h
//  EnglishStudy
//
//  Created by Will Entriken on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GuessingViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutlet UIButton *option1Button;
@property (strong, nonatomic) IBOutlet UIButton *option2Button;
@property (strong, nonatomic) IBOutlet UIButton *option3Button;
@property (strong, nonatomic) IBOutlet UIButton *option4Button;
- (IBAction)playSoundPressed;
- (IBAction)optionPressed:(UIButton *)sender;
@property (strong, nonatomic) IBOutlet UILabel *numberOfCorrect;
@property (strong, nonatomic) IBOutlet UILabel *numberOfTotal;
@property (strong, nonatomic) IBOutlet UILabel *separator;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImage;




@end
