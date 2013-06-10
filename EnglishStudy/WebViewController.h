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
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) id<DownloadLessonViewControllerDelegate> delegate;
@end
