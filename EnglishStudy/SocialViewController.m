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
#import "NSData+Base64.h"

@interface SocialViewController () <UIWebViewDelegate, MBProgressHUDDelegate, WordDetailControllerDelegate, WordPracticeDataSource, WordPracticeDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (strong, nonatomic) Word *currentWord;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@end

@implementation SocialViewController
@synthesize webView;
@synthesize hud = _hud;
@synthesize actionSheet = _actionSheet;
@synthesize refreshControl = _refreshControl;

#define SERVER_ECHO_API_URL @"http://learnwithecho.com/api/2.0"

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor colorWithHue:0 saturation:0 brightness:0 alpha:0.5];
    [self.refreshControl addTarget:self action:@selector(loadPage) forControlEvents:UIControlEventValueChanged];
    [self.webView.scrollView addSubview:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    // http://stackoverflow.com/questions/7883344/iphone-make-a-uiwebview-subview-scrolling-to-top-when-user-touches-the-status
    [(UIScrollView *)[self.webView.subviews objectAtIndex:0] setScrollsToTop:YES];    if (![self.view.window isKeyWindow]) [self.view.window makeKeyWindow];

    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    // http://stackoverflow.com/questions/2238914/how-to-remove-grey-shadow-on-the-top-uiwebview-when-overscroll
    for (UIView *subview in [self.webView.scrollView subviews])
        if ([subview isKindOfClass:[UIImageView class]])
            subview.hidden = YES;
    
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    /*
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastUpdate = [defaults objectForKey:@"lastUpdateSocial"];
    if (!lastUpdate || [lastUpdate timeIntervalSinceNow] < -15) {
     */
        [self loadPage];
    /*
        NSLog(@"Auto-update social %f", [lastUpdate timeIntervalSinceNow]);
    }
     */
    
    /*
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = @"Loading...";

    [self generateHTMLForMainViewOnSuccess:^(NSString *HTML)
     {
         self.hud.mode = MBProgressHUDModeDeterminate;
         self.hud.progress = 1;
         [self.hud hide:YES];
         NSString *path = [[NSBundle mainBundle] bundlePath];
         NSURL *baseURL = [NSURL fileURLWithPath:path];
         [self.webView loadHTMLString:HTML baseURL:baseURL];
     }
                                 onFailure:^(NSError *error)
     {
         [self.hud hide:NO];
         [NetworkManager hudFlashError:error];
     }];
     */
}

/*
- (void)generateHTMLForMainViewOnSuccess:(void(^)(NSString *HTML))successBlock
                       onFailure:(void(^)(NSError *error))failureBlock
{
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager getEventsTargetingMeOnSuccess:^(NSArray *events)
     {
         NSMutableString *HTML = [[NSMutableString alloc] init];
         [HTML appendString:@"<link rel=\"stylesheet\" href=\"style.css\">"];
         for (NSDictionary *eventObject in events) {
             [HTML appendString:@"<div class=\"row\">"];
             NSString *photoURL = [[networkManager photoURLForUserWithID:[eventObject objectForKey:@"actingUserID"]] absoluteString];
             [HTML appendFormat:@"<img src=\"%@\" height=32 width=32 alt=\"avatar\" />", photoURL];
             [HTML appendString:[eventObject objectForKey:@"description"]];
             [HTML appendString:@"<div class=\"clear\"></div></div>\n"];
         }
         if (successBlock)
             successBlock(HTML);
     }
                                                                    onFailure:^(NSError *error)
     {
         if (failureBlock)
             failureBlock(error);
     }];
}
*/

- (void)loadPage
{
    self.webView.delegate = self;
    Profile *me = [Profile currentUserProfile];
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSMutableString *url = [[SERVER_ECHO_API_URL stringByAppendingPathComponent:@"iPhone/social"] mutableCopy];
    [url appendFormat:@"?version=%@", version];
    [url appendFormat:@"&locale=%@", [[NSLocale preferredLanguages] objectAtIndex:0]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", @"xx", me.usercode];
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedString]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];

    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
    [self.webView loadRequest:request];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:@"lastUpdateSocial"];
    [defaults synchronize];
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
        NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
        NSNumber *practiceID = [JSON objectForKey:@"id"];
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.delegate = self;
        self.hud.mode = MBProgressHUDModeIndeterminate;

        [networkManager getWordWithFiles:practiceID withProgress:^(Word *word, NSNumber *progress)
         {
             self.hud.mode = MBProgressHUDModeAnnularDeterminate;
             self.hud.progress = [progress floatValue];
             if ([progress floatValue] == 1.0) {
                 UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                 WordDetailController *wordDetail = (WordDetailController *)[storyboard instantiateViewControllerWithIdentifier:@"WordDetailController"];
                 //[vc setModalPresentationStyle:UIModalPresentationFullScreen];
                 wordDetail.word = word;
                 wordDetail.delegate = self;
                 [self.navigationController pushViewController:wordDetail animated:YES];
                 [self.hud hide:YES];
             }
         }
                               onFailure:^(NSError *error)
         {
             [self.hud hide:YES];
             [NetworkManager hudFlashError:error];
         }];
        
    } else if ([actionType isEqualToString:@"downloadPracticeReply"]) {
        NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
        NSNumber *practiceID = [JSON objectForKey:@"id"];
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.delegate = self;
        self.hud.mode = MBProgressHUDModeAnnularDeterminate;

        [networkManager getWordWithFiles:practiceID withProgress:^(Word *word, NSNumber *progress) {
            self.hud.mode = MBProgressHUDModeAnnularDeterminate;
            self.hud.progress = [progress floatValue];
            if ([progress floatValue] == 1.0) {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                WordPracticeController *controller = (WordPracticeController *)[storyboard instantiateViewControllerWithIdentifier:@"WordPractice"];
                //[vc setModalPresentationStyle:UIModalPresentationFullScreen];
                self.currentWord = word;
                controller.datasource = self;
                controller.delegate = self;
                [self.navigationController pushViewController:controller animated:YES];
                [self.hud hide:YES];
            }
         }
                               onFailure:^(NSError *error)
         {
             [self.hud hide:YES];
             [NetworkManager hudFlashError:error];
         }];
    } else if ([actionType isEqualToString:@"markEventAsRead"]) {
        NSNumber *eventID = [JSON objectForKey:@"id"];
        NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.delegate = self;
        self.hud.mode = MBProgressHUDModeAnnularDeterminate;
        [networkManager deleteEventWithID:eventID onSuccess:^
         {
             self.hud.mode = MBProgressHUDModeAnnularDeterminate;
             self.hud.progress = 1;
             [self.hud hide:YES];
             [self loadPage];
         }
                                onFailure:^(NSError *error)
         {
             [self.hud hide:YES];
             [NetworkManager hudFlashError:error];
         }];
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
    [self.refreshControl endRefreshing];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    [self.refreshControl endRefreshing];
    [NetworkManager hudFlashError:error];
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

#pragma mark - WordPracticeViewController

- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice
{
    return self.currentWord;
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
