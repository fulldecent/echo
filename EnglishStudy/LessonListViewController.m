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

@interface LessonListViewController() <LessonViewDelegate, LessonInformationViewDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) LessonSet *lessonSet;
@property (strong, nonatomic) Lesson *currentLesson;
@end

@implementation LessonListViewController
@synthesize lessonSet = _lessonSet;
@synthesize currentLesson = _lessonForSegue;

- (LessonSet *)lessonSet
{
    if (!_lessonSet)
        _lessonSet = [LessonSet lessonSetWithName:@"downloadsAndUploads"];
    return _lessonSet;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.currentLesson = nil;
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
//    return 2;
    return 1;
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"Downloaded lessons";
    if (section == 1)
        return @"Lessons I created";
    else
        return nil;
}
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return self.lessonSet.lessons.count + 2; // Lessons, "Download lessons", "Create lesson"
    else // (section == 1)
        return 1; // Favorite words
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
                    [(UILabel *)[cell viewWithTag:2] setText:@"Uploading..."];
                else if (lesson.isOlderThanServer)
                    [(UILabel *)[cell viewWithTag:2] setText:@"Downloading..."];
                else {
                    //NSAssert(NO, @"should not have progress = 1");
                    [(UILabel *)[cell viewWithTag:2] setText:@"Transfer complete"];
                }
                NSAssert(![[self.lessonSet transferProgressForLesson:lesson] isEqualToNumber:[NSNumber numberWithInt:1]], @"cant = 1");
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"lesson"];
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
                } else { // WAS CREATED BY ANOTHER USER
                    if (lesson.isUsable) {
                        if (lesson.isOlderThanServer) {
                            line2 = [NSString stringWithFormat:@"%@ – lesson by %@ – update available",
                                     [Languages nativeDescriptionForLanguage:[lesson languageTag]],
                                     lesson.userName];
                        } else {
                            line2 = [NSString stringWithFormat:@"%@ – lesson by %@",
                                     [Languages nativeDescriptionForLanguage:[lesson languageTag]],
                                     lesson.userName];
                        }
                    } else {
                        line2 = [NSString stringWithFormat:@"%@ – not downloaded",
                                 [Languages nativeDescriptionForLanguage:[lesson languageTag]]];
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    }
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
    if (indexPath.section == 0)
    {
        if (indexPath.row < self.lessonSet.lessons.count)
        {
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
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Preparing to sync...";
    //[self.hud hide:YES afterDelay:1.0];

    [self.lessonSet markStaleLessonsWithCallback:^
     {
         [self.lessonSet syncStaleLessonsWithProgress:^(Lesson *lesson, NSNumber *progress) {
             NSUInteger index = [self.lessonSet.lessons indexOfObject:lesson];
             [self reloadRowAtIndexPathWithoutAnimation:[NSIndexPath indexPathForRow:index inSection:0]];
         }];
         [hud hide:YES afterDelay:0.5];
         [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
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
