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
    
    [me syncOnlineOnSuccess:^(NSArray *recommendedLessons)
     {
         for (Lesson *lesson in recommendedLessons)
             [self.delegate downloadLessonViewController:self gotStubLesson:lesson];
         [self.hud hide:YES];
         [me syncToDisk];
         [self.navigationController popViewControllerAnimated:YES];
     } onFailure:^(NSError *error) {
         [self.hud hide:NO];
         [NetworkManager hudFlashError:error];
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

- (IBAction)nameChanged:(UITextField *)sender {
    for (UIButton *button in self.languageButtons)
        button.enabled = sender.text.length > 0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    LanguageSelectController *controller = segue.destinationViewController;
    controller.delegate = self;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (string.length == 0)
        return YES;
    if (textField.text.length > 16)
        return NO;
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^[-a-zA-Z0-9]+$" options:0 error:nil];
    return [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)] > 0;
}

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
