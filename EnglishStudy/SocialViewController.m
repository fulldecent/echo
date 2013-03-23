//
//  SocialViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 8/5/12.
//
//

#import "SocialViewController.h"
#import "MBProgressHUD.h"
#import "FDTakeController.h"
#import "NetworkManager.h"
#import "WordDetailController.h"
#import "AFNetworking.h"

@interface SocialViewController () <UIWebViewDelegate, MBProgressHUDDelegate, UIAlertViewDelegate, UIActionSheetDelegate, FDTakeDelegate, UITextFieldDelegate, WordDetailControllerDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) NSString *updatedUserName;
@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (strong, nonatomic) FDTakeController *takeController;
@end

@implementation SocialViewController
@synthesize webView;
@synthesize updatedUserName = _updatedUserName;
@synthesize hud = _hud;
@synthesize actionSheet = _actionSheet;
@synthesize takeController = _takeController;

#define SERVER_ECHO_API_URL @"http://learnwithecho.com/api/1.0"

- (void)loadPage
{
    self.webView.delegate = self;
    Profile *me = [Profile currentUserProfile];
    NSMutableString *url = [[SERVER_ECHO_API_URL stringByAppendingPathComponent:@"iPhone/social"] mutableCopy];
    [url appendFormat:@"?native=%@", me.nativeLanguageTag];
    [url appendFormat:@"&userCode=%@", me.usercode];
    [url appendFormat:@"&learning=%@", me.learningLanguageTag];
    [url appendFormat:@"&locale=%@", [[NSLocale preferredLanguages] objectAtIndex:0]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self.webView loadRequest:request];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:@"lastUpdateSocial"];
    [defaults synchronize];
}

- (void)viewWillAppear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastUpdateLessonList = [defaults objectForKey:@"lastUpdateSocial"];
    if (!lastUpdateLessonList || [lastUpdateLessonList timeIntervalSinceNow] < -15) {
        [self loadPage];
        NSLog(@"Auto-update social %f", [lastUpdateLessonList timeIntervalSinceNow]);
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (![request.URL.scheme isEqualToString:@"echo"])
        return YES;

    // echo://action#json_parameters
    NSString *actionType = request.URL.host;
    NSDictionary *JSON = [NSDictionary dictionary];
    if (request.URL.fragment) {
        NSString *JSONString = [request.URL.fragment stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSError *error = nil;
        JSON = [NSJSONSerialization JSONObjectWithData:[JSONString dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:kNilOptions error:&error];
    }
    
    if ([actionType isEqualToString:@"downloadPractice"]) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.delegate = self;
        self.hud.mode = MBProgressHUDModeAnnularDeterminate;

        NSNumber *practiceID = [JSON objectForKey:@"id"];
        NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
        [networkManager downloadWordWithID:[practiceID integerValue] withProgress:^(Word *PGword, NSNumber *PGprogress)
         {
             self.hud.progress = [PGprogress floatValue];
             if ([PGprogress floatValue] == 1.0) {
                 UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                 WordDetailController *wordDetail = (WordDetailController *)[storyboard instantiateViewControllerWithIdentifier:@"WordDetailController"];
                 //[vc setModalPresentationStyle:UIModalPresentationFullScreen];
                 wordDetail.word = PGword;
                 wordDetail.delegate = self;
                 [self.navigationController pushViewController:wordDetail animated:YES];
                 [self.hud hide:YES];
             }
         } onFailure:^{
             [self.hud hide:YES];
             self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
             self.hud.delegate = self;
             UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
             view.text = @"Error downloading";
             view.font = self.hud.labelFont;
             view.textColor = [UIColor whiteColor];
             view.backgroundColor = [UIColor clearColor];
             [view sizeToFit];
             self.hud.customView = view;
             self.hud.mode = MBProgressHUDModeCustomView;
             [self.hud hide:YES afterDelay:3];
         }];
    } else if ([actionType isEqualToString:@"updateProfile"]) {
        self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Edit username", @"Change photo", nil];
        [self.actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    [self.hud hide:YES];
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.delegate = self;
    //    self.hud.labelText = error.localizedDescription;
    //    self.hud.labelText = @"Network connection failed";
    //	self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-BigX.png"]];
    UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    view.text = error.localizedDescription;
    view.font = self.hud.labelFont;
    view.textColor = [UIColor whiteColor];
    view.backgroundColor = [UIColor clearColor];
    [view sizeToFit];
    self.hud.customView = view;
    
	self.hud.mode = MBProgressHUDModeCustomView;
	[self.hud hide:YES afterDelay:3];
    //    NSLog(@"webView didFailLoadWithError %@", error);
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // Change username
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Enter your new username"
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Update", nil];
        alertView.tag = 0;
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        alertView.delegate = self;
        [alertView textFieldAtIndex:0].delegate = self;
        [alertView show];
    } else if (buttonIndex == 1) {
        self.takeController = [[FDTakeController alloc] init];
        self.takeController.imagePicker.allowsEditing = YES;
        self.takeController.delegate = self;
        [self.takeController takePhotoOrChooseFromLibrary];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (string.length == 0)
        return YES;
    if (textField.text.length > 20)
        return NO;
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^[-a-zA-Z0-9]+$" options:0 error:nil];
    return [regex numberOfMatchesInString:string options:0 range:NSMakeRange(0, string.length)] > 0;
}

#pragma mark - FDTakeDelegate

- (void)takeController:(FDTakeController *)controller gotPhoto:(UIImage *)photo withInfo:(NSDictionary *)info
{
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager setMyPhoto:photo
                     onSuccess:^
     {
         [self loadPage];
     }
                     onFailure:^(NSError *error) {}];
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
        [networkManager setMyUsername:[[alertView textFieldAtIndex:0] text]
                            onSuccess:^
         {
             [self loadPage];
         }
                            onFailure:^(NSError *error) {}];
    }
}

#pragma mark - WordDetailViewControllerDelegate

- (BOOL)wordDetailController:(WordDetailController *)controller canEditWord:(Word *)word
{
    return NO;
}

- (BOOL)wordDetailController:(WordDetailController *)controller canReplyWord:(Word *)word
{
    return YES;
}

- (NSString *)wordDetailControllerSoundDirectoryFilePath:(WordDetailController *)controller
{
    return NSTemporaryDirectory();
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
