//
//  MainViewController.m
//  Echo
//
//  Created by Will Entriken on 11/26/12.
//
//

#import "MainViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "LessonSet.h"
#import "LessonViewController.h"
#import "LessonInformationViewController.h"
#import "Profile.h"
#import "IntroViewController.h"
#import "DownloadLessonViewController.h"
#import "Languages.h"
#import "WordDetailController.h"

typedef enum {SectionLessons, SectionPractice, SectionCount} Sections;
typedef enum {CellLesson, CellLessonEditable, CellLessonTransfer, CellDownloadLesson, CellCreateLesson, CellPractice, CellPracticeTransfer, CellNewPractice, CellInbox, CellEditProfile, CellMeetPeople, CellWhatsUp} Cells;

@interface MainViewController () <LessonViewDelegate, LessonInformationViewDelegate, IntroViewControllerDelegate, DownloadLessonViewControllerDelegate, WordDetailControllerDelegate>
@property (strong, nonatomic) LessonSet *lessonSet;
@property (strong, nonatomic) LessonSet *practiceLessonSet;
@property (strong, nonatomic) LessonSet *practiceSet;
@property (strong, nonatomic) Lesson *currentLesson;
@end

@implementation MainViewController
@synthesize lessonSet = _lessonSet;
@synthesize practiceLessonSet = _practiceLessonSet;
@synthesize practiceSet = _practiceSet;
@synthesize currentLesson = _currentLesson;

- (LessonSet *)lessonSet
{
    if (!_lessonSet) _lessonSet = [LessonSet lessonSetWithName:@"downloadsAndUploads"];
    return _lessonSet;
}

- (LessonSet *)practiceSet
{
    if (!_practiceSet) _practiceSet = [LessonSet lessonSetWithName:@"practiceLessons"];
    return _practiceSet;
}

- (IBAction)reload {
    [self.lessonSet markStaleLessonsWithCallback:^
     {
         [self.lessonSet syncStaleLessonsWithProgress:^(Lesson *lesson, NSNumber *progress) {
             NSUInteger index = [self.lessonSet.lessons indexOfObject:lesson];
      //       [self reloadRowAtIndexPathWithoutAnimation:[NSIndexPath indexPathForRow:index inSection:0]];
         }];
         [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
         //self.navigationItem.leftBarButtonItem = self.refreshButton;
         
         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
         [defaults setObject:[NSDate date] forKey:@"lastUpdateLessonList"];
         [defaults synchronize];
         [self.refreshControl endRefreshing];
     }];
}

#pragma mark - UITableViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient.png"]];
    tempImageView.frame = self.tableView.frame;
    self.tableView.backgroundView = tempImageView;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor  blackColor];
    [refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    Profile *me = [Profile currentUserProfile];
    if (!me.username)
        [self performSegueWithIdentifier:@"intro" sender:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    self.currentLesson = nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastUpdateLessonList = [defaults objectForKey:@"lastUpdateLessonList"];
    if (!lastUpdateLessonList || [lastUpdateLessonList timeIntervalSinceNow] < -5*60) {
        NSLog(@"Auto-update lesson list %f", [lastUpdateLessonList timeIntervalSinceNow]);
        [self reload];
    }
    [super viewWillAppear:YES];
    [self.tableView reloadData];
}



- (void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (Cells)cellTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case SectionLessons:
            if (indexPath.row < self.lessonSet.lessons.count) {
                Lesson *lesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
                if ([self.lessonSet transferProgressForLesson:lesson])
                    return CellLessonTransfer;
                else if (lesson.isEditable)
                    return CellLessonEditable;
                else
                    return CellLesson;
            } else if (indexPath.row == self.lessonSet.lessons.count)
                return CellDownloadLesson;
            else
                return CellCreateLesson;
            break;
        case SectionPractice:
            if (indexPath.row < self.practiceSet.lessons.count) {
                Lesson *lesson = [self.practiceSet.lessons objectAtIndex:indexPath.row];
                if ([self.lessonSet transferProgressForLesson:lesson])
                    return CellPracticeTransfer;
                else
                    return CellPractice;
            } else if (indexPath.row == self.practiceSet.lessons.count) {
                return CellNewPractice;
            } else if (indexPath.row == self.practiceSet.lessons.count+1) {
                return CellMeetPeople;
            } else if (indexPath.row == self.practiceSet.lessons.count+2) {
                return CellEditProfile;
            }
            break;
    }
    assert (0);
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case SectionLessons:
            return @"Lessons";
        default:
        case SectionPractice:
            return @"Practice";
    }
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 33;
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellLesson:
        case CellLessonEditable:
        case CellLessonTransfer:
            return 65;
        case CellCreateLesson:
        case CellDownloadLesson:
        case CellEditProfile:
        case CellInbox:
        case CellMeetPeople:
        case CellNewPractice:
        case CellPractice:
        case CellPracticeTransfer:
        case CellWhatsUp:
            return 44;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Create label with section title
    UILabel *label = [[UILabel alloc] init] ;
    label.frame = CGRectMake(100, 5, 140, 30);
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
//    label.shadowColor = [UIColor whiteColor];
//    label.shadowOffset = CGSizeMake(0.0, 1.0);
    label.font = [UIFont boldSystemFontOfSize:20];
    label.text = [self tableView:tableView titleForHeaderInSection:section];

    UIImage *icon;
    if (section == SectionLessons)
        icon = [UIImage imageNamed:@"echo"];
    else if (section == SectionPractice)
        icon = [UIImage imageNamed:@"practiceIcon"];

    UIImageView * iconView = [[UIImageView alloc] initWithImage:icon];
    iconView.frame = CGRectMake(65, 5, 30, 30);
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 30)];
    UIView *background = [[UIView alloc] initWithFrame:CGRectMake(50, 5, 200, 30)];
  
    if (section == SectionLessons)
        background.backgroundColor = [UIColor colorWithRed:61.0/256 green:100.0/256 blue:212.0/256 alpha:1.0];
    else if (section == SectionPractice)
        background.backgroundColor = [UIColor colorWithRed:29.0/256 green:140.0/256 blue:38.0/256 alpha:1.0];

    background.layer.cornerRadius = 5;
    background.layer.masksToBounds = NO;
    [background.layer setCornerRadius:10.0f];
    [background.layer setBorderColor:[UIColor blackColor].CGColor];
    [background.layer setBorderWidth:1.5f];
    [background.layer setShadowColor:[UIColor blackColor].CGColor];
    [background.layer setShadowOpacity:0.8];
    [background.layer setShadowRadius:3.0];
    [background.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
    
    [view addSubview:background];
    [view addSubview:label];
    [view addSubview:iconView];
    
    return view;
    /*
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(50, 50, 100, 200)];
    view.backgroundColor = [UIColor redColor];
    UIImage *icon = [UIImage imageNamed:@"echo"];
    UIImageView * iconView = [[UIImageView alloc] initWithImage:icon];
    [view addSubview:iconView];
    return view;
     */
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SectionLessons:
            return self.lessonSet.lessons.count+2;
        case SectionPractice:
            return self.practiceSet.lessons.count+3;
        default:
            return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    Lesson *lesson;
    Profile *me = [Profile currentUserProfile];

    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellLesson:
            cell = [tableView dequeueReusableCellWithIdentifier:@"lesson"];
            lesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
            [(UILabel *)[cell viewWithTag:1] setText:lesson.name];
            [(UILabel *)[cell viewWithTag:2] setText:[lesson.detail objectForKey:lesson.languageTag]];
            [(UIProgressView *)[cell viewWithTag:3] setProgress:[lesson.portionComplete floatValue]];
            [(UILabel *)[cell viewWithTag:4] setText:[NSString stringWithFormat:@"%d%%", (int)([lesson.portionComplete floatValue]*100)]];
            [(UIButton *)[cell viewWithTag:6] setHidden:(lesson.portionComplete.floatValue > 0)];
            
            return cell;
        case CellLessonEditable:
            cell = [tableView dequeueReusableCellWithIdentifier:@"lessonEditable"];
            lesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
            [(UILabel *)[cell viewWithTag:1] setText:lesson.name];
            [(UILabel *)[cell viewWithTag:2] setText:[lesson.detail objectForKey:lesson.languageTag]];
            [(UILabel *)[cell viewWithTag:3] setText:@"7 people using"];
            return cell;
        case CellLessonTransfer: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"lessonTransfer"];
            lesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
            [(UILabel *)[cell viewWithTag:1] setText:lesson.name];
            [(UILabel *)[cell viewWithTag:2] setText:[lesson.detail objectForKey:lesson.languageTag]];
            NSNumber *percent = [self.lessonSet transferProgressForLesson:lesson];
            [(UIProgressView *)[cell viewWithTag:4] setProgress:[percent floatValue]];
            //[(UILabel *)[cell viewWithTag:5] setText:[NSString stringWithFormat:@"%d%%", (int)([percent floatValue]*100)]];
            return cell;
        }
        case CellDownloadLesson:
            cell = [tableView dequeueReusableCellWithIdentifier:@"downloadLesson"];
            [(UILabel *)[cell viewWithTag:2] setText:[NSString stringWithFormat:@"New %@ lessons", [Languages nativeDescriptionForLanguage:me.learningLanguageTag]]];
#warning TODO: Set visible only if new downloads available
            [(UIButton *)[cell viewWithTag:3] setTitle:@"5" forState:UIControlStateNormal];
            [(UIButton *)[cell viewWithTag:3] setHidden:YES];
            return cell;
        case CellCreateLesson:
            cell = [tableView dequeueReusableCellWithIdentifier:@"createLesson"];
            return cell;
        case CellPractice:
            cell = [tableView dequeueReusableCellWithIdentifier:@"practice"];
            lesson = [self.practiceSet.lessons objectAtIndex:indexPath.row];
            [(UILabel *)[cell viewWithTag:1] setText:[lesson.detail objectForKey:lesson.languageTag]];
            [(UILabel *)[cell viewWithTag:2] setText:@"New replies"];
#warning Set visible only if just downloaded or just updated
            [(UIButton *)[cell viewWithTag:3] setTitle:@"5" forState:UIControlStateNormal];
            return cell;
            return cell;
        case CellPracticeTransfer:
            cell = [tableView dequeueReusableCellWithIdentifier:@"practiceTransfer"];
            return cell;
        case CellNewPractice:
            cell = [tableView dequeueReusableCellWithIdentifier:@"newPractice"];
            return cell;
        case CellEditProfile: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"editProfile"];
            Profile *me = [Profile currentUserProfile];
            [(UILabel *)[cell viewWithTag:1] setText:me.username];
            return cell;
        }
        case CellInbox:
            cell = [tableView dequeueReusableCellWithIdentifier:@"inbox"];
            return cell;
        case CellMeetPeople:
            cell = [tableView dequeueReusableCellWithIdentifier:@"meetPeople"];
            [(UILabel *)[cell viewWithTag:2] setText:@"New messages"];
#warning Set visible only if just downloaded or just updated
            [(UIButton *)[cell viewWithTag:3] setTitle:@"1" forState:UIControlStateNormal];
            return cell;
        case CellWhatsUp:
            cell = [tableView dequeueReusableCellWithIdentifier:@"whatsUp"];
            return cell;
    }
}


/*
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
*/


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Lesson *lesson;
    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellLesson:
        case CellLessonEditable:
            lesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
            self.currentLesson = lesson;
            [self performSegueWithIdentifier:@"lesson" sender:self];
            break;
        case CellLessonTransfer:
        case CellDownloadLesson:
        case CellCreateLesson:
        case CellPractice:
        case CellPracticeTransfer:
        case CellNewPractice:
        case CellEditProfile:
        case CellInbox:
        case CellMeetPeople:
        case CellWhatsUp:
            break;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    self.currentLesson = [self.lessonSet.lessons objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"lessonInformation" sender:self];
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

#pragma mark - UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[LessonViewController class]]) {
        LessonViewController *controller = segue.destinationViewController;
        controller.lesson = self.currentLesson;
        controller.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[LessonInformationViewController class]]) {
        LessonInformationViewController *controller = segue.destinationViewController;
        controller.delegate = self;
        if (![segue.description isEqualToString:@"createLesson"])
            controller.lesson = self.currentLesson;
    } else if ([segue.destinationViewController isKindOfClass:[IntroViewController class]]) {
        IntroViewController *controller = segue.destinationViewController;
        controller.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[DownloadLessonViewController class]]) {
        DownloadLessonViewController *controller = segue.destinationViewController;
        controller.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[WordDetailController class]]) {
        Profile *me = [Profile currentUserProfile];
        WordDetailController *controller = segue.destinationViewController;
        controller.delegate = self;
        self.currentLesson = [[Lesson alloc] init];
        Word *word = [[Word alloc] init];
        word.languageTag = me.learningLanguageTag;
        controller.word = word;
    }
}

#pragma mark - LessonViewDelegate

- (void)lessonView:(LessonViewController *)controller didSaveLesson:(Lesson *)lesson
{
    [self.lessonSet addOrUpdateLesson:lesson];
    [self.tableView reloadData];
}

/*
- (void)lessonView:(LessonViewController *)controller wantsToUploadLesson:(Lesson *)lesson
{
    [self.lessonSet syncLesson:lesson withProgress:^(Lesson *lesson, NSNumber *progress) {
        NSUInteger index = [self.lessonSet.lessons indexOfObject:lesson];
        [self reloadRowAtIndexPathWithoutAnimation:[NSIndexPath indexPathForRow:index inSection:0]];
    }];
}
 */

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

#pragma mark - IntroViewControllerDelegate

- (void)introViewController:(IntroViewController *)controller gotStubLesson:(Lesson *)lesson
{
    [self.lessonSet addOrUpdateLesson:lesson]; // may or may not add a row
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.lessonSet syncLesson:lesson withProgress:^(Lesson *lesson, NSNumber *progress) {
        NSUInteger index = [self.lessonSet.lessons indexOfObject:lesson];
        NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:0];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - DownloadLessonViewControllerDelegate

- (void)downloadLessonViewController:(DownloadLessonViewController *)controller gotStubLesson:(Lesson *)lesson
{
    [self.lessonSet addOrUpdateLesson:lesson]; // may or may not add a row
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.lessonSet syncLesson:lesson withProgress:^(Lesson *lesson, NSNumber *progress) {
        NSUInteger index = [self.lessonSet.lessons indexOfObject:lesson];
        NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:0];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
        [controller.navigationController popViewControllerAnimated:YES];
    }];
}

#pragma mark - WordDetailControllerDelegate
- (void)wordDetailController:(WordDetailController *)controller didSaveWord:(Word *)word
{
    self.currentLesson.words = [NSArray arrayWithObject:word];
    self.currentLesson.name = @"PRACTICE";
    self.currentLesson.detail = [NSDictionary dictionaryWithObject:word.name forKey:word.languageTag];
    self.currentLesson.languageTag = word.languageTag;
    [self.practiceLessonSet.lessons addObject:self.currentLesson];
    [self.practiceLessonSet writeToDisk];
    [self.tableView reloadData];
    [controller.navigationController popViewControllerAnimated:YES];
    
    [self.practiceLessonSet syncLesson:self.currentLesson withProgress:^(Lesson *lesson, NSNumber *progress)
     {
         NSUInteger index = [self.practiceLessonSet.lessons indexOfObject:lesson];
         [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationAutomatic];
         //if (progress.integerValue == 1.0)
         //self.navigationItem.leftBarButtonItem = self.refreshButton;
     }];
    //NSUInteger index = [self.practiceLessonSet.lessons indexOfObject:self.currentLesson];
    //[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView reloadData];
    
    self.currentLesson = nil;
}

- (NSString *)wordDetailControllerSoundDirectoryFilePath:(WordDetailController *)controller
{
    NSString *lessonPath = self.currentLesson.filePath;
    NSString *wordPath = [lessonPath stringByAppendingPathComponent:controller.word.wordCode];
    return wordPath;
}

- (BOOL)wordDetailController:(WordDetailController *)controller canEditWord:(Word *)word
{
    return YES;
}


@end
