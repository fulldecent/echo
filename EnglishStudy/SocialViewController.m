//
//  SocialViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 8/5/12.
//
//

#import "SocialViewController.h"
#import "MBProgressHUD.h"
#import "NetworkManager.h"
#import "WordDetailController.h"
#import "WordPracticeController.h"
#import "AFNetworking.h"

@interface SocialViewController () <UIWebViewDelegate, MBProgressHUDDelegate, WordDetailControllerDelegate, WordPracticeDataSource, WordPracticeDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) NSString *updatedUserName;
@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (strong, nonatomic) Word *currentWord;
@end

@implementation SocialViewController
@synthesize webView;
@synthesize updatedUserName = _updatedUserName;
@synthesize hud = _hud;
@synthesize actionSheet = _actionSheet;

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
    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
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
    NSDate *lastUpdate = [defaults objectForKey:@"lastUpdateSocial"];
    if (!lastUpdate || [lastUpdate timeIntervalSinceNow] < -15) {
        [self loadPage];
        NSLog(@"Auto-update social %f", [lastUpdate timeIntervalSinceNow]);
    }
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
    } else if ([actionType isEqualToString:@"downloadPracticeReply"]) {
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
                 WordPracticeController *controller = (WordPracticeController *)[storyboard instantiateViewControllerWithIdentifier:@"wordPractice"];
                 self.currentWord = PGword;
                 controller.datasource = self;
                 controller.delegate = self;
                 [self.navigationController pushViewController:controller animated:YES];
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
    } else if ([actionType isEqualToString:@"markEventAsRead"]) {
        NSNumber *eventID = [JSON objectForKey:@"id"];
        NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
        [networkManager markEventWithIDAsRead:eventID onSuccess:nil onFailure:nil];
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

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
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

#pragma mark - WordPracticeViewController

- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice
{
    return self.currentWord;
}

- (NSString *)currentSoundDirectoryFilePath
{
    return NSTemporaryDirectory();
}

- (BOOL)wordCheckedStateForWordPractice:(WordPracticeController *)wordPractice
{
    return false;
}

- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice
{
}

- (BOOL)currentWordCanBeCheckedForWordPractice:(WordPracticeController *)wordPractice
{
    return false;
}

- (void)wordPractice:(WordPracticeController *)wordPractice setWordCheckedState:(BOOL)state
{
}

- (BOOL)wordPracticeShouldShowNextButton:(WordPracticeController *)wordPractice;
{
    return false;
}

@end
