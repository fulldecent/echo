//
//  PHORLanguagesViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LanguageSelectController.h"
#import "Languages.h"

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Choose a language";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.languages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"leftDetail";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.textLabel.text = [[self.languages objectAtIndex:indexPath.row] objectForKey:@"tag"];
    cell.detailTextLabel.text = [[self.languages objectAtIndex:indexPath.row] objectForKey:@"nativeName"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate languageSelectController:self didSelectLanguage:[[self.languages objectAtIndex:indexPath.row] objectForKey:@"tag"] withNativeName:[[self.languages objectAtIndex:indexPath.row] objectForKey:@"nativeName"]];
    [self dismissModalViewControllerAnimated:YES];
}



@end
