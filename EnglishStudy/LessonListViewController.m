//
//  EchoWordListViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <MessageUI/MessageUI.h>
#import "LessonListViewController.h"
#import "LessonInformationViewController.h"
#import "LessonViewController.h"
#import "Lesson.h"
#import "Languages.h"
#import "NetworkManager.h"
#import "LessonSet.h"
#import "MBProgressHUD.h"
#import "UIImageView+AFNetworking.h"
#import <QuartzCore/QuartzCore.h>

@interface LessonListViewController() <LessonViewDelegate, LessonInformationViewDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) LessonSet *lessonSet;
@property (strong, nonatomic) Lesson *currentLesson;
@property (strong, nonatomic) UIBarButtonItem *refreshButton;
@property (strong, nonatomic) UIBarButtonItem *loadingButton;
@end

@implementation LessonListViewController
@synthesize lessonSet = _lessonSet;
@synthesize currentLesson = _lessonForSegue;
@synthesize refreshButton = _refreshButton;
@synthesize loadingButton = _loadingButton;

- (LessonSet *)lessonSet
{
    if (!_lessonSet)
        _lessonSet = [LessonSet lessonSetWithName:@"downloadsAndUploads"];
    return _lessonSet;
}

- (UIBarButtonItem *)refreshButton
{
    if (!_refreshButton)
        _refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reload:)];
    return _refreshButton;
}

- (UIBarButtonItem *)loadingButton
{
    if (!_loadingButton) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        activityView.hidesWhenStopped = YES;
        [activityView startAnimating];
        _loadingButton = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    }
    return _loadingButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    /*
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor redColor] CGColor] ,(id)[[UIColor greenColor] CGColor], nil];
    gradient.aut
   // gradient.frame = self.backgroundView.bounds;
   // UIView *view = [[UIView alloc] initWithFrame:self.bounds];
   // [view.layer insertSublayer:gradient atIndex:0];
   // self.backgroundView = view;

    self.tableView.backgroundView.layer.sublayers = nil;
    [self.tableView.backgroundView.layer insertSublayer:gradient atIndex:0];
  
  //  [self.tableView.backgroundView.layer insertSublayer:gradient atIndex:0];
    
    self.tableView.backgroundColor = [UIColor clearColor];
     */
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationItem.leftBarButtonItem = self.refreshButton;
    self.currentLesson = nil;
        
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastUpdateLessonList = [defaults objectForKey:@"lastUpdateLessonList"];
    if (!lastUpdateLessonList || [lastUpdateLessonList timeIntervalSinceNow] < -5*60) {
        NSLog(@"Auto-update lesson list %f", [lastUpdateLessonList timeIntervalSinceNow]);
        [self reload:nil];
    }
    
    [super viewWillAppear:YES];
}

- (void)reloadRowAtIndexPathWithoutAnimation:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.lessonSet.lessons.count + 2; // Lessons, "Download lessons", "Create lesson"
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.lessonSet.lessons.count == 0)
        return @"Download lessons and compare the teacher's voice with your own. Using headphones will help you hear more clearly.";
    else
        return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.lessonSet.lessons.count == 0) {
        UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"introLessons"]];
        view.contentMode = UIViewContentModeCenter;
        return view;
    } else
        return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.lessonSet.lessons.count == 0)
        return 278;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        if (indexPath.row == [self.lessonSet.lessons count]) { // DOWNLOAD LESSONS
            cell = [tableView dequeueReusableCellWithIdentifier:@"downloadLessons"];
        } else if (indexPath.row == [self.lessonSet.lessons count] + 1) { // CREATE LESSON
            cell = [tableView dequeueReusableCellWithIdentifier:@"createLesson"];
        } else { // A LESSON
            Lesson *lesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
            
            if ([self.lessonSet transferProgressForLesson:lesson]) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"lessonTransferring"];
                if (lesson.name)
                    [(UILabel *)[cell viewWithTag:1] setText:lesson.name];
                else
                    [(UILabel *)[cell viewWithTag:1] setText:[NSString string]];

                NSLog(@"LOADING CELL WITH PROGRESS %@", [self.lessonSet transferProgressForLesson:lesson]);
                [(UIProgressView *)[cell viewWithTag:3] setProgress:
                 [(NSNumber *)[self.lessonSet transferProgressForLesson:lesson] floatValue]];
                if (lesson.isNewerThanServer)
                    [(UILabel *)[cell viewWithTag:2] setText:NSLocalizedString(@"uploading", @"Status message, lesson is uploading to server")];
                else if (lesson.isOlderThanServer)
                    [(UILabel *)[cell viewWithTag:2] setText:NSLocalizedString(@"downloading", @"Status message, lesson is downloading from server")];
                else {
                    //NSAssert(NO, @"should not have progress = 1");
                    [(UILabel *)[cell viewWithTag:2] setText:@"Transfer complete"];
                }
                NSAssert(![[self.lessonSet transferProgressForLesson:lesson] isEqualToNumber:[NSNumber numberWithInt:1]], @"cant = 1");
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"lessonWithIcon"];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                if (lesson.name)
                    [(UILabel *)[cell viewWithTag:1] setText:lesson.name];
                else
                    [(UILabel *)[cell viewWithTag:1] setText:[NSString string]];
                
                NSString *line2;
                if (lesson.isEditable) {
                    if (lesson.isShared) {
                        if (lesson.isNewerThanServer) {
                            line2 = [NSString stringWithFormat:@"%@ – shared, need to resend", [Languages nativeDescriptionForLanguage:[lesson languageTag]]];
                        } else if (lesson.isOlderThanServer) {
                            line2 = [NSString stringWithFormat:@"%@ – shared, update available", [Languages nativeDescriptionForLanguage:[lesson languageTag]]];
                        } else {
                            line2 = [NSString stringWithFormat:@"%@ – shared", [Languages nativeDescriptionForLanguage:[lesson languageTag]]];
                        }
                    } else {
                        line2 = [NSString stringWithFormat:@"%@ – not shared", [Languages nativeDescriptionForLanguage:[lesson languageTag]]];
                    }
                    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                    
                    UIImageView *image = (UIImageView *)[cell viewWithTag:3];
                    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                    NSString *deviceUUID = [defaults objectForKey:@"userGUID"];
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://learnwithecho.com/api/1.0/users/%@/photo",deviceUUID]];
                    [image setImageWithURL:url placeholderImage:[UIImage imageNamed:@"none40"]];
                } else { // WAS CREATED BY ANOTHER USER
                    if (lesson.isUsable) {
                        if (lesson.isOlderThanServer) {
                            line2 = [NSString stringWithFormat:@"%@ [update available]",
                                     lesson.userName];
                        } else {
                            line2 = [NSString stringWithFormat:@"%@",
                                     lesson.userName];
                        }
                    } else {
                        line2 = [NSString stringWithFormat:@"%@ – not downloaded",
                                 [Languages nativeDescriptionForLanguage:[lesson languageTag]]];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
                    
                    UIImageView *image = (UIImageView *)[cell viewWithTag:3];
                    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://learnwithecho.com/avatarFiles/%@.png",lesson.userID]];
                    [image setImageWithURL:url placeholderImage:[UIImage imageNamed:@"none40"]];
                }
                [(UILabel *)[cell viewWithTag:2] setText:line2];
            }
        }
    } else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"favoriteWords"];
    }
    return cell;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row < [self.lessonSet.lessons count]) {
        Lesson *lesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
        if (!lesson.isUsable)
            return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == [self.lessonSet.lessons count]) { // GET NEW WORDS
            // the storyboard handles this transition
        } else if (indexPath.row == [self.lessonSet.lessons count] + 1) { // CREATE A LESSON
            // the storyboard handles this transition
        } else {
            Lesson *lesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
            self.currentLesson = lesson;
            [self performSegueWithIdentifier:@"lesson" sender:self];
        }
    } 
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    self.currentLesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"lessonInformation" sender:self];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row < self.lessonSet.lessons.count) {
            Lesson *lesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
            if ([self.lessonSet transferProgressForLesson:lesson])
                return 63;
        }
    }
    return self.tableView.rowHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row < self.lessonSet.lessons.count)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentLesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
    if (self.currentLesson.isEditable && self.currentLesson.isShared) {
        NSString *title = @"You are deleting this lesson from your device. Would you like to continue sharing online?";
        UIActionSheet *confirmDeleteLesson = [[UIActionSheet alloc] initWithTitle:title
delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Stop sharing online", @"Keep sharing online", nil];
        [confirmDeleteLesson showFromTabBar:self.tabBarController.tabBar];
    } else {
        [self.lessonSet deleteLesson:[self.lessonSet.lessons objectAtIndex:indexPath.row]];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        self.currentLesson = nil;
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 0 && indexPath.row < self.lessonSet.lessons.count;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section == 0 && proposedDestinationIndexPath.row < self.lessonSet.lessons.count)
        return proposedDestinationIndexPath;
    else
        return sourceIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    Lesson *lesson = [self.lessonSet.lessons objectAtIndex:sourceIndexPath.row];
    [self.lessonSet.lessons removeObjectAtIndex:sourceIndexPath.row];
    [self.lessonSet.lessons insertObject:lesson atIndex:destinationIndexPath.row];
    [self.lessonSet writeToDisk];
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[LessonViewController class]]) {
        LessonViewController *wordListController = segue.destinationViewController;
        wordListController.lesson = self.currentLesson;
        wordListController.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[LessonInformationViewController class]]) {
        LessonInformationViewController *controller = segue.destinationViewController;
        controller.delegate = self;
        if (![segue.description isEqualToString:@"createLesson"])
            controller.lesson = self.currentLesson;
    } else if ([segue.destinationViewController isKindOfClass:[GetLessonsViewController class]]) {
        GetLessonsViewController *controller = segue.destinationViewController;
        controller.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[LanguageSelectController class]]) {
        LanguageSelectController *controller = segue.destinationViewController;
        controller.delegate = self;
    }
}

#pragma mark - Networking and internet

- (IBAction)reload:(UIBarButtonItem *)sender {
    self.navigationItem.leftBarButtonItem = self.loadingButton;
    [self.lessonSet markStaleLessonsWithCallback:^
     {
         NSString *badge = self.lessonSet.countOfLessonsNeedingSync ? [NSString stringWithFormat:@"%d", self.lessonSet.countOfLessonsNeedingSync] : nil;
         self.navigationController.tabBarItem.badgeValue = badge;
         [self.lessonSet syncStaleLessonsWithProgress:^(Lesson *lesson, NSNumber *progress) {
             NSUInteger index = [self.lessonSet.lessons indexOfObject:lesson];
             [self reloadRowAtIndexPathWithoutAnimation:[NSIndexPath indexPathForRow:index inSection:0]];
             if (progress.integerValue == 1.0) {
                 NSString *badge = self.lessonSet.countOfLessonsNeedingSync ? [NSString stringWithFormat:@"%d", self.lessonSet.countOfLessonsNeedingSync] : nil;
                 self.navigationController.tabBarItem.badgeValue = badge;
             }
         }];
         [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
         self.navigationItem.leftBarButtonItem = self.refreshButton;
         
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         [defaults setObject:[NSDate date] forKey:@"lastUpdateLessonList"];
         [defaults synchronize];
     }];
}

- (void)updateBadgeCount
{
    [self.lessonSet markStaleLessonsWithCallback:^
     {
         NSString *badge = self.lessonSet.countOfLessonsNeedingSync ? [NSString stringWithFormat:@"%d", self.lessonSet.countOfLessonsNeedingSync] : nil;
         self.navigationController.tabBarItem.badgeValue = badge;
     }];
}

#pragma mark - LessonViewDelegate

- (void)lessonView:(LessonViewController *)controller didSaveLesson:(Lesson *)lesson
{
    [self.lessonSet addOrUpdateLesson:lesson];
    [self.tableView reloadData];
}

- (void)lessonView:(LessonViewController *)controller wantsToUploadLesson:(Lesson *)lesson
{
    [self.lessonSet syncLesson:lesson withProgress:^(Lesson *lesson, NSNumber *progress) {
        NSUInteger index = [self.lessonSet.lessons indexOfObject:lesson];
        [self reloadRowAtIndexPathWithoutAnimation:[NSIndexPath indexPathForRow:index inSection:0]];
    }];
}

- (void)lessonView:(LessonViewController *)controller wantsToDeleteLesson:(Lesson *)lesson
{
    [self.lessonSet deleteLesson:lesson];
    [self.tableView reloadData];
}

#pragma mark - LessonInformationViewDelegate

- (void)lessonInformationView:(LessonInformationViewController *)controller didSaveLesson:(Lesson *)lesson
{
    [self.lessonSet addOrUpdateLesson:lesson];
    [self.tableView reloadData];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    Lesson *lesson = self.currentLesson;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.lessonSet.lessons indexOfObject:lesson] inSection:0];
    if (buttonIndex == 0) { // Stop sharing
        [self.lessonSet deleteLessonAndStopSharing:lesson
                                         onSuccess:^
         {
             [self.lessonSet deleteLesson:lesson];
             [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
         }
                                         onFailure:^(NSError *error)
         {
        
         }];
    } else if (buttonIndex == 1) { // Keep sharing
        [self.lessonSet deleteLesson:lesson];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    self.currentLesson = nil;
}

#pragma mark - PHORLanguagesViewControllerDelegate

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    self.currentLesson = [[Lesson alloc] init];
    self.currentLesson.languageTag = tag;
    [self performSegueWithIdentifier:@"lesson" sender:self];
}

#pragma mark - GetLessonDelegate

- (void)getLessonsController:(GetLessonsViewController *)controller gotStubLesson:(Lesson *)lesson
{
    [self.lessonSet addOrUpdateLesson:lesson]; // may or may not add a row
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.lessonSet syncLesson:lesson withProgress:^(Lesson *lesson, NSNumber *progress) {
        NSUInteger index = [self.lessonSet.lessons indexOfObject:lesson];
        [self reloadRowAtIndexPathWithoutAnimation:[NSIndexPath indexPathForRow:index inSection:0]];
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


@end
