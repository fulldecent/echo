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
    [networkManager searchLessonsWithLangTag:tag andSearhText:searchString onSuccess:^(NSArray *lessonPreviews)
     {
         self.lessons = lessonPreviews;
         [self.tableView reloadData];
     } onFailure:^(NSError *error) {
         [NetworkManager hudFlashError:error];
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
    if (indexPath.row == self.lessons.count)
        return [tableView dequeueReusableCellWithIdentifier:@"request" forIndexPath:indexPath];
    
    Profile *me = [Profile currentUserProfile];
    Lesson *lesson = [self.lessons objectAtIndex:indexPath.row];
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"lesson" forIndexPath:indexPath];
    [(UILabel *)[cell viewWithTag:1] setText:lesson.name];
    [(UILabel *)[cell viewWithTag:2] setText:lesson.detail];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[lesson.serverVersion doubleValue]];
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    [(UILabel *)[cell viewWithTag:3] setText:formattedDateString];
    if ([lesson.numLikes integerValue]) {
        [(UILabel *)[cell viewWithTag:4] setText:[NSString stringWithFormat:@"%@", lesson.numLikes]];
        [(UIImageView *)[cell viewWithTag:7] setHidden:NO];
    } else {
        [(UILabel *)[cell viewWithTag:4] setText:@""];
        [(UIImageView *)[cell viewWithTag:7] setHidden:YES];
    }
    if ([lesson.numFlags integerValue]) {
        [(UILabel *)[cell viewWithTag:5] setText:[NSString stringWithFormat:@"%@", lesson.numFlags]];
        [(UIImageView *)[cell viewWithTag:8] setHidden:NO];
    } else {
        [(UILabel *)[cell viewWithTag:5] setText:@""];
        [(UIImageView *)[cell viewWithTag:8] setHidden:YES];
    }
    [(UILabel *)[cell viewWithTag:6] setText:lesson.userName];
    UIImage *placeholder = [UIImage imageNamed:@"none40"];
    NSURL *userPhoto = [networkManager photoURLForUserWithID:lesson.userID];
    [(UIImageView *)[cell viewWithTag:9] setImageWithURL:userPhoto placeholderImage:placeholder];
    
    if (me.nativeLanguageTag) {
        Lesson *translatedLesson = [lesson.translations objectForKey:me.nativeLanguageTag];
        if (translatedLesson.name)
            [(UILabel *)[cell viewWithTag:2] setText:translatedLesson.name];
    }
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
