//
//  SocialViewController.h
//  EnglishStudy
//
//  Created by Will Entriken on 8/5/12.
//
//

#import <UIKit/UIKit.h>

@interface SocialViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIWebView *webView;
-(IBAction)loadPage;
@end
