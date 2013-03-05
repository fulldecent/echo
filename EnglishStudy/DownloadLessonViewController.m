//
//  DownloadLessonsViewController.m
//  Echo
//
//  Created by Will Entriken on 2/11/13.
//
//

#import "DownloadLessonViewController.h"
#import "Profile.h"
#import "Lesson.h"
#import "NetworkManager.h"
#import "LanguageSelectController.h"

@interface DownloadLessonViewController () <LanguageSelectControllerDelegate>
@property (strong, nonatomic) NSArray *lessons;
- (void)populateRowsWithSearch:(NSString *)searchString languageTag:(NSString *)tag;
@end

@implementation DownloadLessonViewController

- (void)populateRowsWithSearch:(NSString *)searchString languageTag:(NSString *)tag
{
    NSLog(@"search String is %@ and lang is %@",searchString, tag);
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager lessonsWithSearch:searchString languageTag:tag return:^(NSArray *retLessons) {
        self.lessons = retLessons;
        [self.tableView reloadData];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient.png"]];
    tempImageView.frame = self.tableView.frame;
    self.tableView.backgroundView = tempImageView;
    
    Profile *me = [Profile currentUserProfile];
    self.navigationItem.rightBarButtonItem.title = me.learningLanguageTag;
    [self populateRowsWithSearch:@"" languageTag:me.learningLanguageTag];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.lessons.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Lesson *lesson = [self.lessons objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"lesson" forIndexPath:indexPath];
    cell.textLabel.text = lesson.name;
    cell.detailTextLabel.text = lesson.userName;
    
    // Configure the cell...
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    LanguageSelectController *controller = segue.destinationViewController;
    controller.delegate = self;
}

#pragma mark - LanguageSelectControllerDelegate

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    [self populateRowsWithSearch:@"" languageTag:tag];
    self.navigationItem.rightBarButtonItem.title = tag;
}

@end
