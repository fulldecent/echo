//
//  IntroViewController.m
//  Echo
//
//  Created by Will Entriken on 11/24/12.
//
//

#import "IntroViewController.h"
#import "Profile.h"
#import "MBProgressHUD.h"
#import "LanguageSelectController.h"
#import "NetworkManager.h"

@interface IntroViewController() <MBProgressHUDDelegate, LanguageSelectControllerDelegate, UITextFieldDelegate>
- (void)saveName:(NSString *)name andLanguageWithTag:(NSString *)tag;
@property (strong, nonatomic) MBProgressHUD *hud;
@end

@implementation IntroViewController
@synthesize hud = _hud;
@synthesize delegate = _delegate;

- (IBAction)languageButtonClicked:(UIButton *)sender
{
    if (sender.tag == 1)
        [self saveName:self.nameField.text andLanguageWithTag:@"en"];
    if (sender.tag == 2)
        [self saveName:self.nameField.text andLanguageWithTag:@"es"];
    if (sender.tag == 3)
        [self saveName:self.nameField.text andLanguageWithTag:@"cmn"];
}

- (void)saveName:(NSString *)name andLanguageWithTag:(NSString *)tag
{
    Profile *me = [Profile currentUserProfile];
    me.username = name;
    me.learningLanguageTag = tag;
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = @"Sending...";
    
    [me syncOnlineOnSuccess:^
     {
         NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
         NSArray *recommendedLessons = networkManager.recommendedLessons;
         NSLog(@"%@", recommendedLessons);
         
         for (NSString *lessonJSON in recommendedLessons) {
             NSData *data = [lessonJSON dataUsingEncoding:NSUTF8StringEncoding];
             NSDictionary *packed = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             
             Lesson *lesson = [[Lesson alloc] init];
             lesson.lessonID = [packed objectForKey:@"lessonID"];
             lesson.languageTag = [packed objectForKey:@"languageTag"];
             lesson.name = [packed objectForKey:@"name"];
             lesson.detail = [packed objectForKey:@"detail"];
             lesson.userID = [packed objectForKey:@"userID"];
             lesson.userName = [packed objectForKey:@"userName"];
             lesson.serverVersion = [packed objectForKey:@"updated"];
             if ([[packed objectForKey:@"lessonCode"] length])
                 lesson.lessonCode = [packed objectForKey:@"lessonCode"];
             else
                 lesson.lessonCode = [NSString string];

             [self.delegate introViewController:self gotStubLesson:lesson];
         }         
         
         [self.hud hide:YES];
         [self dismissViewControllerAnimated:YES completion:nil];
     } onFailure:^(NSError *error) {
         [self.hud hide:YES];
         self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
         self.hud.delegate = self;
         self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-BigX.png"]];
         UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
         view.text = error.localizedDescription;
         view.font = self.hud.labelFont;
         view.textColor = [UIColor whiteColor];
         view.backgroundColor = [UIColor clearColor];
         [view sizeToFit];
         self.hud.customView = view;
         self.hud.mode = MBProgressHUDModeCustomView;
         [self.hud hide:YES afterDelay:1.5];
     }];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.nameField.delegate = self;
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload {
    [self setNameField:nil];
    [self setLanguageButtons:nil];
    [super viewDidUnload];
}
- (IBAction)nameChanged:(UITextField *)sender {
    NSLog(@"%@", sender.text);
    for (UIButton *button in self.languageButtons)
        button.enabled = sender.text.length > 0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    LanguageSelectController *controller = segue.destinationViewController;
    controller.delegate = self;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
}

#pragma mark - LanguageSelectControllerDelegate

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    [self saveName:self.nameField.text andLanguageWithTag:tag];
}

@end
