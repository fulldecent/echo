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
#import "UIImageView+AFNetworking.h"
#import <MessageUI/MessageUI.h>

@interface DownloadLessonViewController () <LanguageSelectControllerDelegate, MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) NSArray *lessons;
- (void)populateRowsWithSearch:(NSString *)searchString languageTag:(NSString *)tag;
@end

@implementation DownloadLessonViewController
@synthesize delegate = _delegate;

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
    return self.lessons.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.lessons.count) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"request" forIndexPath:indexPath];
        return cell;
    }
    
    Lesson *lesson = [self.lessons objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"lesson" forIndexPath:indexPath];
    [(UILabel *)[cell viewWithTag:1] setText:lesson.name];
    [(UILabel *)[cell viewWithTag:2] setText:[lesson.detail objectForKey:@"en"]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[lesson.serverVersion doubleValue]];
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    [(UILabel *)[cell viewWithTag:3] setText:formattedDateString];
    if ([lesson.likes integerValue]) {
        [(UILabel *)[cell viewWithTag:4] setText:[NSString stringWithFormat:@"%@", lesson.likes]];
        [(UIImageView *)[cell viewWithTag:7] setHidden:NO];
    } else {
        [(UILabel *)[cell viewWithTag:4] setText:@""];
        [(UIImageView *)[cell viewWithTag:7] setHidden:YES];
    }
    if ([lesson.flags integerValue]) {
        [(UILabel *)[cell viewWithTag:5] setText:[NSString stringWithFormat:@"%@", lesson.flags]];
        [(UIImageView *)[cell viewWithTag:8] setHidden:NO];
    } else {
        [(UILabel *)[cell viewWithTag:5] setText:@""];
        [(UIImageView *)[cell viewWithTag:8] setHidden:YES];
    }
//    [(UILabel *)[cell viewWithTag:5] setText:[NSString stringWithFormat:@"%@", lesson.flags]];
    [(UILabel *)[cell viewWithTag:6] setText:lesson.userName];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://learnwithecho.com/avatarFiles/%@.png", lesson.userID]];
    UIImage *placeholder = [UIImage imageNamed:@"none40"];
    [(UIImageView *)[cell viewWithTag:9] setImageWithURL:url placeholderImage:placeholder];
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.lessons.count)
        return 69;
    else
        return tableView.rowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.lessons.count) {
        [self.delegate downloadLessonViewController:self gotStubLesson:[self.lessons objectAtIndex:indexPath.row]];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
            picker.mailComposeDelegate = self;
            [picker setSubject:[NSString stringWithFormat:@"Idea for Echo lesson/%@", self.navigationItem.rightBarButtonItem.title]];
            [picker setToRecipients:[NSArray arrayWithObject:@"echo@phor.net"]];
            [picker setMessageBody:@"(TYPE YOUR IDEA IN HERE)" isHTML:NO];
            [self presentViewController:picker animated:YES completion:nil];
        }
    }
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

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
