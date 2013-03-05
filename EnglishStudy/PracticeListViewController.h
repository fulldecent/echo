//
//  PracticeListViewController.h
//  Echo
//
//  Created by Will Entriken on 8/20/12.
//
//

#import <UIKit/UIKit.h>
#import "UITableWithBackgroundViewController.h"

@interface PracticeListViewController : UITableWithBackgroundViewController
- (IBAction)reload:(id)sender;
- (IBAction)sendToFriendPressed:(UIButton *)sender;
- (void)updateBadgeCount;
@end
