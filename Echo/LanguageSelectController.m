//
//  PHORLanguagesViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LanguageSelectController.h"
#import "Languages.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@interface LanguageSelectController ()
@property (strong, nonatomic) NSArray *languages;
@end

@implementation LanguageSelectController
@synthesize languages = _languages;
@synthesize delegate = _delegate;

- (NSArray *)languages
{
    if (!_languages) {
        _languages = [Languages languages];
    }
    return _languages;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"LanguageSelect"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];

    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
        [self.tableView setContentInset:UIEdgeInsetsMake(20,
                                                         self.tableView.contentInset.left,
                                                         self.tableView.contentInset.bottom,
                                                         self.tableView.contentInset.right)];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.languages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"leftDetail";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.textLabel.text = (self.languages)[indexPath.row][@"tag"];
    cell.detailTextLabel.text = (self.languages)[indexPath.row][@"nativeName"];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate languageSelectController:self didSelectLanguage:(self.languages)[indexPath.row][@"tag"] withNativeName:(self.languages)[indexPath.row][@"nativeName"]];
    [self dismissViewControllerAnimated:YES completion:nil];
}



@end
