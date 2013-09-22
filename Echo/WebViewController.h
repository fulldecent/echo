//
//  WebViewController.h
//  Echo
//
//  Created by Will Entriken on 6/8/13.
//
//

#import <UIKit/UIKit.h>
#import "DownloadLessonViewController.h"

@interface WebViewController : UIViewController
@property (weak, nonatomic) id<DownloadLessonViewControllerDelegate> delegate;
- (void)loadRequest:(NSURLRequest *)request;
    
@property (strong, nonatomic) IBOutlet UIWebView *webView; // don't access me directly
@end
