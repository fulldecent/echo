//
//  PHORLanguagesViewController.h
//  EnglishStudy
//
//  Created by Will Entriken on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LanguageSelectControllerDelegate
- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name;
@end

@interface LanguageSelectController : UITableViewController
@property (weak, nonatomic) id <LanguageSelectControllerDelegate> delegate;
@end
