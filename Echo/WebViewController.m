//
//  WebViewController.m
//  Echo
//
//  Created by Will Entriken on 6/8/13.
//
//

#import "WebViewController.h"
#import "MBProgressHUD.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "NetworkManager.h"
#import "WordDetailController.h"
#import "WordPracticeController.h"
#import "NSData+Base64.h"

@interface WebViewController ()<UIWebViewDelegate, MBProgressHUDDelegate, WordDetailControllerDelegate, WordPracticeDataSource, WordPracticeDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) Word *currentWord;
@property (strong, nonatomic) NSURLRequest *requestToLoad;
@end

@implementation WebViewController
@synthesize hud = _hud;
@synthesize refreshControl = _refreshControl;
@synthesize currentWord = _currentWord;

#define SERVER_ECHO_API_URL @"https://learnwithecho.com/api/2.0"

#warning LOOK AT USING UIWebView+AFNetworking HERE
#warning CONSOLIDATE SOCIAL INTO THIS CLASS

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor blackColor];
    [self.refreshControl addTarget:self.webView action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [self.webView.scrollView addSubview:self.refreshControl];
    self.webView.delegate = self;
    if (self.requestToLoad) {
        [self.webView loadRequest:self.requestToLoad];
        self.requestToLoad = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    // http://stackoverflow.com/questions/7883344/iphone-make-a-uiwebview-subview-scrolling-to-top-when-user-touches-the-status
    self.webView.scrollView.scrollsToTop = YES;
//    [(UIScrollView *)[self.webView.subviews objectAtIndex:0] setScrollsToTop:YES];    if (![self.view.window isKeyWindow]) [self.view.window makeKeyWindow];
    
    // http://stackoverflow.com/questions/2238914/how-to-remove-grey-shadow-on-the-top-uiwebview-when-overscroll
    for (UIView *subview in [self.webView.scrollView subviews])
        if ([subview isKindOfClass:[UIImageView class]])
            subview.hidden = YES;
    self.screenName = @"WebView";
    
    [super viewWillAppear:animated];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
#warning TODO
    if (![request.URL.scheme isEqualToString:@"echo"]) {
        return YES;
    }
    
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
             [self.webView reload];
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
    /* http://stackoverflow.com/questions/1842370/uiwebview-didfinishloading-fires-multiple-times
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.delegate = self;
    self.hud.mode = MBProgressHUDModeIndeterminate;
     */
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    [self.refreshControl endRefreshing];
    [self.hud hide:YES];
    NSString* title = [webView stringByEvaluatingJavaScriptFromString: @"document.title"];
    self.title = title;
    
    // For the Meet People page
    NSString *javaScript = @"parseInt(document.getElementById('lastMessageSeen2').innerHTML)";
    NSString *lastMessageSeenStr = [self.webView stringByEvaluatingJavaScriptFromString:javaScript];
    if (lastMessageSeenStr.length) { // Found something
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:lastMessageSeenStr.integerValue forKey:@"lastMessageSeen"];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    [self.hud hide:NO];
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
    
#pragma mark -
    
- (void)loadRequest:(NSURLRequest *)request
{
    if (self.webView)
        [self.webView loadRequest:request];
    else
        self.requestToLoad = request;
}

@end
