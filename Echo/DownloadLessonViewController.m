//
//  DownloadLessonsViewController.m
//  Echo
//
//  Created by Will Entriken on 2/11/13.
//
//

#import "DownloadLessonViewController.h"
#import "NetworkManager.h"
#import "LanguageSelectController.h"
#import "UIImageView+AFNetworking.h"
#import <MessageUI/MessageUI.h>
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "Echo-Swift.h"

@interface DownloadLessonViewController () <LanguageSelectControllerDelegate, MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) NSArray *lessons;
- (void)populateRowsWithSearch:(NSString *)searchString languageTag:(NSString *)tag;
@end

@implementation DownloadLessonViewController
@synthesize delegate = _delegate;

- (void)populateRowsWithSearch:(NSString *)searchString languageTag:(NSString *)tag
{
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
    
    Profile *me = [Profile currentUserProfile];
    self.navigationItem.rightBarButtonItem.title = me.learningLanguageTag;
    [self populateRowsWithSearch:@"" languageTag:me.learningLanguageTag];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    id tracker = [GAI sharedInstance].defaultTracker;
    [tracker set:kGAIScreenName value:@"DownloadLesson"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
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
    
    Lesson *lesson = (self.lessons)[indexPath.row];
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"lesson" forIndexPath:indexPath];
    ((UILabel *)[cell viewWithTag:1]).text = lesson.name;
    ((UILabel *)[cell viewWithTag:2]).text = lesson.detail;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:lesson.serverTimeOfLastCompletedSync];
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    ((UILabel *)[cell viewWithTag:3]).text = formattedDateString;
    if (lesson.numLikes) {
        ((UILabel *)[cell viewWithTag:4]).text = [NSString stringWithFormat:@"%ld", (long)lesson.numLikes];
        [(UIImageView *)[cell viewWithTag:7] setHidden:NO];
    } else {
        ((UILabel *)[cell viewWithTag:4]).text = @"";
        [(UIImageView *)[cell viewWithTag:7] setHidden:YES];
    }
    if (lesson.numFlags) {
        ((UILabel *)[cell viewWithTag:5]).text = [NSString stringWithFormat:@"%ld", (long)lesson.numFlags];
        [(UIImageView *)[cell viewWithTag:8] setHidden:NO];
    } else {
        ((UILabel *)[cell viewWithTag:5]).text = @"";
        [(UIImageView *)[cell viewWithTag:8] setHidden:YES];
    }
    ((UILabel *)[cell viewWithTag:6]).text = lesson.userName;
    UIImage *placeholder = [UIImage imageNamed:@"none40"];
    NSURL *userPhoto = [networkManager photoURLForUserWithID:@(lesson.userID)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:userPhoto];
    [(UIImageView *)[cell viewWithTag:9] setImageWithURLRequest:request placeholderImage:placeholder success:nil failure:nil];
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
        [self.delegate downloadLessonViewController:self gotStubLesson:(self.lessons)[indexPath.row]];
        id<GAITracker> tracker = [GAI sharedInstance].defaultTracker;
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"Usage"
                                                              action:@"Learning"
                                                               label:@"Download Lesson"
                                                               value:@(1)] build]];
        
    } else {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
            picker.mailComposeDelegate = self;
            [picker setSubject:[NSString stringWithFormat:@"Idea for Echo lesson/%@", self.navigationItem.rightBarButtonItem.title]];
            [picker setToRecipients:@[@"echo@phor.net"]];
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
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
