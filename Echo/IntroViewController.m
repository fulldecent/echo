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

@interface IntroViewController() <MBProgressHUDDelegate, LanguageSelectControllerDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;
@end

@implementation IntroViewController
@synthesize hud = _hud;
@synthesize delegate = _delegate;

- (IBAction)languageButtonClicked:(UIButton *)sender
{
    if (sender.tag == 1)
        [self saveLanguageWithTag:@"en"];
    if (sender.tag == 2)
        [self saveLanguageWithTag:@"es"];
    if (sender.tag == 3)
        [self saveLanguageWithTag:@"cmn"];
}

- (void)saveLanguageWithTag:(NSString *)tag
{
    Profile *me = [Profile currentUserProfile];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.screenName = @"IntroView";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    LanguageSelectController *controller = segue.destinationViewController;
    controller.delegate = self;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
}

#pragma mark - LanguageSelectControllerDelegate

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    [self saveLanguageWithTag:tag];
    [controller dismissAnimated:YES];
}

@end
