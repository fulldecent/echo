//
//  ProfileViewController.h
//  Echo
//
//  Created by Will Entriken on 3/16/13.
//
//

#import <UIKit/UIKit.h>
#import "DownloadLessonViewController.h"

@interface ProfileViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UITextField *name;
@property (strong, nonatomic) IBOutlet UILabel *learningLang;
@property (strong, nonatomic) IBOutlet UILabel *nativeLang;
@property (strong, nonatomic) NSString *learningLangTag;
@property (strong, nonatomic) NSString *nativeLangTag;
@property (strong, nonatomic) IBOutlet UIImageView *photo;
@property (strong, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) id<DownloadLessonViewControllerDelegate>delegate;
- (IBAction)checkIn:(id)sender;
- (IBAction)choosePhoto:(id)sender;
- (IBAction)save:(id)sender;
@end
