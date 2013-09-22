//
//  SocialViewController.h
//  EnglishStudy
//
//  Created by Will Entriken on 8/5/12.
//
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"

@interface SocialViewController : GAITrackedViewController
@property (strong, nonatomic) IBOutlet UIWebView *webView;
-(IBAction)loadPage;
@end
