//
//  GetLessonsViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 7/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GetLessonsViewController.h"
#import "MBProgressHUD.h"
#import "NetworkManager.h"
#import "LanguageSelectController.h"
#import "Languages.h"
#import "AFNetworking.h"

@interface GetLessonsViewController () <UIWebViewDelegate, MBProgressHUDDelegate, LanguageSelectControllerDelegate>
@property (strong, nonatomic) MBProgressHUD *hud;
@end

@implementation GetLessonsViewController
@synthesize webView;
@synthesize hud = _hud;
@synthesize delegate = _delegate;

#define SERVER_IPHONELESSON_BASE_URL @"http://learnwithecho.com/api/1.0/iPhone/lessons"
    
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = @"English";
    self.webView.delegate = self;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableString *url = [[SERVER_IPHONELESSON_BASE_URL stringByAppendingPathComponent:[defaults objectForKey:@"learningLanguageTag"]] mutableCopy];
    [url appendFormat:@"?nativeLanguageTag=%@", [defaults objectForKey:@"nativeLanguageTag"]];
    [url appendFormat:@"&userCode=%@", [defaults objectForKey:@"userGUID"]];
    [url appendFormat:@"&locale=%@", [[NSLocale preferredLanguages] objectAtIndex:0]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self.webView loadRequest:request];
}

- (void)viewDidUnload
{
    [self setWebView:nil];
    [super viewDidUnload];
    self.hud = nil;
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[[request URL] scheme] isEqualToString:@"lesson"]) {
        NSData *data = [[[[request URL] query] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
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
        
        [self.delegate getLessonsController:self gotStubLesson:lesson];
        [self.navigationController popViewControllerAnimated:YES];
        return NO;
    }
    return YES;
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[LanguageSelectController class]]) {
        LanguageSelectController *controller = segue.destinationViewController;
        controller.delegate = self;
    }
}

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    self.title = name;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *urlBase = [SERVER_IPHONELESSON_BASE_URL stringByAppendingPathComponent:tag];
    NSString *fullURL = [urlBase stringByAppendingFormat:@"?nativeLanguageTag=%@", [defaults objectForKey:@"nativeLanguageTag"]];
    fullURL = [fullURL stringByAppendingFormat:@"&userCode=%@", [defaults objectForKey:@"userGUID"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:fullURL]];
    [self.webView loadRequest:request];
}



@end
