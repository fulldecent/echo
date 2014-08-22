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

@interface IntroViewController() <MBProgressHUDDelegate, LanguageSelectControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) UIAlertView *alertView;
- (void)saveName:(NSString *)name andLanguageWithTag:(NSString *)tag;
@end

@implementation IntroViewController
@synthesize hud = _hud;
@synthesize delegate = _delegate;

- (IBAction)languageButtonClicked:(UIButton *)sender
{
    if (sender.tag == 1)
        [self saveName:self.name andLanguageWithTag:@"en"];
    if (sender.tag == 2)
        [self saveName:self.name andLanguageWithTag:@"es"];
    if (sender.tag == 3)
        [self saveName:self.name andLanguageWithTag:@"cmn"];
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
         [self dismissViewControllerAnimated:YES completion:nil];
     } onFailure:^(NSError *error) {
         [self.hud hide:NO];
         [NetworkManager hudFlashError:error];
     }];
}

- (void)askUserForName
{
    self.alertView = [[UIAlertView alloc] initWithTitle:@"Hello" message:@"My name is:" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
    self.alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[self.alertView textFieldAtIndex:0] setText:self.name];
    [[self.alertView textFieldAtIndex:0] setDelegate:self];
    [self.alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.name = [(UITextField *)[alertView textFieldAtIndex:0] text];
    [self.nameField setTitle:self.name forState:UIControlStateNormal];
    if (!self.name.length)
        [self askUserForName];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.screenName = @"IntroView";
    [self.nameField setTitle:@"" forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self askUserForName];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    LanguageSelectController *controller = segue.destinationViewController;
    controller.delegate = self;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([textField.text length] + [string length] - range.length > 16)
        return NO;
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^[-a-zA-Z0-9]?$" options:0 error:nil];
    return [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)] > 0;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.name = textField.text;
    [self.nameField setTitle:self.name forState:UIControlStateNormal];
    [self.alertView dismissWithClickedButtonIndex:self.alertView.firstOtherButtonIndex animated:YES];
    if (!self.name.length)
        [self askUserForName];
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
    [self saveName:self.name andLanguageWithTag:tag];
    [controller dismissAnimated:YES];
}

@end
