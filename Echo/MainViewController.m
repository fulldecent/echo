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
#import "ProfileViewController.h"
#import "Languages.h"
#import "WordDetailController.h"
#import "MBProgressHUD.h"
#import "NetworkManager.h"
#import "WebViewController.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "TDBadgedCell.h"
#import <NSData+Base64.h>
#import "Event.h"
#import "UIImageView+AFNetworking.h"

typedef enum {SectionLessons, SectionPractice, SectionSocial, SectionCount} Sections;
typedef enum {CellLesson, CellLessonEditable, CellLessonDownload, CellLessonUpload, CellDownloadLesson, CellCreateLesson, CellNewPractice, CellEditProfile, CellEvent} Cells;

@interface MainViewController () <LessonViewDelegate, LessonInformationViewDelegate, DownloadLessonViewControllerDelegate, WordDetailControllerDelegate, UIActionSheetDelegate>
@property (strong, nonatomic) LessonSet *lessonSet;
@property (strong, nonatomic) LessonSet *practiceSet;
@property (strong, nonatomic) Lesson *currentLesson;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) NSArray *myEvents;
@property (strong, nonatomic) NSArray *otherEvents;
@property (strong, nonatomic) Word *currentWord;

@end

@implementation MainViewController
@synthesize lessonSet = _lessonSet;
@synthesize practiceSet = _practiceSet;
@synthesize currentLesson = _currentLesson;
@synthesize hud = _hud;

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

- (IBAction)reload
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager getUpdatesForLessons:self.lessonSet.lessons
                       newLessonsSinceID:[defaults objectForKey:@"lastUpdateLessonList"]
                         messagesSinceID:[defaults objectForKey:@"lastMessageSeen"]
                               onSuccess:^(NSDictionary *lessonsIDsWithNewServerVersions, NSNumber *numNewLessons, NSNumber *numNewMessages)
     {
         [self.lessonSet setRemoteUpdatesForLessonsWithIDs:[lessonsIDsWithNewServerVersions allKeys]];
         [defaults setObject:numNewLessons forKey:@"numNewLessons"];
         [defaults setObject:numNewMessages forKey:@"numNewMessages"];
         [defaults setObject:[NSDate date] forKey:@"lastUpdateLessonList"];
         [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
         [self.refreshControl endRefreshing];
         [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[numNewMessages intValue]];         
         [self.lessonSet syncStaleLessonsWithProgress:^(Lesson *lesson, NSNumber *progress){
             NSIndexPath *path = [self indexPathForLesson:lesson];
             [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
         }];
     }
                               onFailure:^
     (NSError *error) {
         [self.refreshControl endRefreshing];
         [NetworkManager hudFlashError:error];
     }];
    
    [networkManager getEventsIMayBeInterestedInOnSuccess:^(NSArray *events) {
        self.otherEvents = events;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionSocial] withRowAnimation:UITableViewRowAnimationAutomatic];
        ;
    } onFailure:^(NSError *error) {
        ;
    }];
    
    [networkManager getEventsTargetingMeOnSuccess:^(NSArray *events) {
        self.myEvents = events;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionPractice] withRowAnimation:UITableViewRowAnimationAutomatic];
        ;
    } onFailure:^(NSError *error) {
        ;
    }];
}

#pragma mark - UITableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pushNotificationReceived:) name:@"pushNotification" object:nil];
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)])
        self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:244.0/255 green:219.0/255 blue:0 alpha:1];

    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
        [self.tableView setContentInset:UIEdgeInsetsMake(20,
                                                         self.tableView.contentInset.left,
                                                         self.tableView.contentInset.bottom,
                                                         self.tableView.contentInset.right)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"MainView"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastUpdateLessonList = [defaults objectForKey:@"lastUpdateLessonList"];
    if (!lastUpdateLessonList || [lastUpdateLessonList timeIntervalSinceNow] < -5*60) {
        NSLog(@"Auto-update lesson list %f", [lastUpdateLessonList timeIntervalSinceNow]);
        [self reload];
    }
    [super viewWillAppear:YES];
 //   self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    Profile *me = [Profile currentUserProfile];
    if (!me.learningLanguageTag)
        [self performSegueWithIdentifier:@"intro" sender:self];
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
        {
            if (indexPath.row == 0)
                return CellDownloadLesson;
            if (indexPath.row == 1)
                return CellCreateLesson;
            Lesson *lesson = [self lessonForRowAtIndexPath:indexPath];
            if ([self.lessonSet transferProgressForLesson:lesson]) {
                // COPY PASTE THIS FROM NETWORKMANAGER.M TO MAKE SURE IT'S RIGHT
                if (lesson.localChangesSinceLastSync)
                    return CellLessonUpload;
                else
                    return CellLessonDownload;
            } else if (lesson.isByCurrentUser)
                return CellLessonEditable;
            else
                return CellLesson;
            break;
        }
        case SectionPractice:
            if (indexPath.row == 0)
                return CellEditProfile;
            else if (indexPath.row == 1)
                return CellNewPractice;
            else
                return CellEvent;
        case SectionSocial:
            return CellEvent;
    }
    assert (0);
    return 0;
}

- (Lesson *)lessonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != SectionLessons)
        return nil;
    if (indexPath.row > 1 && indexPath.row < self.lessonSet.lessons.count + 2)
        return [self.lessonSet.lessons objectAtIndex:indexPath.row - 2];
    return nil;
}

- (NSIndexPath *)indexPathForLesson:(Lesson *)lesson
{
    NSUInteger index = [self.lessonSet.lessons indexOfObject:lesson];
    return [NSIndexPath indexPathForRow:index+2 inSection:SectionLessons];
}

- (Event *)eventForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionPractice)
        return [self.myEvents objectAtIndex:indexPath.row - 2];
    else if (indexPath.section == SectionSocial)
        return [self.otherEvents objectAtIndex:indexPath.row];
    return nil;
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SectionLessons:
            return self.lessonSet.lessons.count + 2;
        case SectionPractice:
            return self.myEvents.count + 2;
        case SectionSocial:
            return self.otherEvents.count;
    }
    assert(0);
    return 0;
}

- (void)loadHelpScreen
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    WebViewController *controller = (WebViewController *)[storyboard instantiateViewControllerWithIdentifier:@"WebViewController"];
    controller.delegate = self;
    NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"resources" ofType:@"html"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.navigationController pushViewController:controller animated:YES];
    [controller loadRequest:request];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TDBadgedCell *cell; /* Sometimes Interface Builder has a UITableViewCell, you keep track of that */
    Lesson *lesson;
    Event *event;
    Profile *me = [Profile currentUserProfile];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellLesson:
            cell = [tableView dequeueReusableCellWithIdentifier:@"lesson"];
            lesson = [self lessonForRowAtIndexPath:indexPath];
            cell.textLabel.text = lesson.name;
            cell.detailTextLabel.text = lesson.detail;
            if (me.nativeLanguageTag) {
                Lesson *translatedLesson = [lesson.translations objectForKey:me.nativeLanguageTag];
                if (translatedLesson.name)
                    cell.detailTextLabel.text = translatedLesson.detail;
            }
            
            if (lesson.portionComplete.floatValue == 0)
                cell.badgeString = @"New";
            else if (lesson.portionComplete.floatValue < 1.0)
                cell.badgeString = [NSString stringWithFormat:@"%d%% done", (int)([lesson.portionComplete floatValue]*100)];
            else
                cell.badgeString = nil;
            return cell;
        case CellLessonEditable:
            cell = [tableView dequeueReusableCellWithIdentifier:@"lessonEditable"];
            lesson = [self lessonForRowAtIndexPath:indexPath];
            cell.textLabel.text = lesson.name;
            if (lesson.isShared)
                cell.detailTextLabel.text = @"Shared online";
            else
                cell.detailTextLabel.text = @"Not yet shared online";
            return cell;
        case CellLessonDownload: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"lessonDownload"];
            lesson = [self lessonForRowAtIndexPath:indexPath];
            cell.textLabel.text = lesson.name;
            NSNumber *percent = [self.lessonSet transferProgressForLesson:lesson];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Downloading – %d%%", (int)([percent floatValue]*100)];
            return cell;
        }
        case CellLessonUpload: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"lessonUpload"];
            lesson = [self lessonForRowAtIndexPath:indexPath];
            cell.textLabel.text = lesson.name;
            NSNumber *percent = [self.lessonSet transferProgressForLesson:lesson];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"Uploading – %d%%", (int)([percent floatValue]*100)];
            return cell;
        }
        case CellDownloadLesson:
            cell = [tableView dequeueReusableCellWithIdentifier:@"downloadLesson"];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"New %@ lesson", [Languages nativeDescriptionForLanguage:me.learningLanguageTag]];
            if ([(NSNumber *)[defaults objectForKey:@"newLessonCount"] integerValue]) {
                cell.badgeString = [(NSNumber *)[defaults objectForKey:@"newLessonCount"] stringValue];
                cell.badgeRightOffset = 8;
            } else {
                cell.badgeString = nil;
            }
            return cell;
        case CellCreateLesson:
            cell = [tableView dequeueReusableCellWithIdentifier:@"createLesson"];
            return cell;
        case CellNewPractice:
            cell = [tableView dequeueReusableCellWithIdentifier:@"newPractice"];
            return cell;
        case CellEditProfile:
            cell = [tableView dequeueReusableCellWithIdentifier:@"editProfile"];
            cell.textLabel.text = me.username;
            if (me.profileCompleteness.floatValue < 1) {
                cell.badgeString = [NSString stringWithFormat:@"%d%% done", (int)(me.profileCompleteness.floatValue*100)];
            } else
                cell.badgeString = nil;
            return cell;
        case CellEvent:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"social"];
            event = [self eventForRowAtIndexPath:indexPath];
            
            cell.selectionStyle = event.eventType == EventTypePostPractice ?
            UITableViewCellSelectionStyleDefault :
            UITableViewCellSelectionStyleNone;
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[event.timestamp doubleValue]];
            NSString *formattedDateString = [dateFormatter stringFromDate:date];
            cell.detailTextLabel.text = formattedDateString;
            
            NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
            UIImage *placeholder = [UIImage imageNamed:@"none40"];
            NSURL *userPhoto = [networkManager photoURLForUserWithID:event.actingUserID];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:userPhoto];
            [cell.imageView setImageWithURLRequest:request placeholderImage:placeholder success:nil failure:nil];

            cell.textLabel.text = event.htmlDescription;
/*
            cell.textLabel.attributedText = [[NSAttributedString alloc] initWithData:[event.htmlDescription dataUsingEncoding:NSUTF8StringEncoding]
                                                                             options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                       NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                  documentAttributes:nil error:nil];
 */

            cell.accessoryType = event.eventType == EventTypePostPractice ? UITableViewCellAccessoryDisclosureIndicator: UITableViewCellAccessoryNone;
            return cell;
        }
    }
    assert (0);
    return 0;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Lesson *lesson;
    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellLesson:
        case CellLessonEditable:
            lesson = [self lessonForRowAtIndexPath:indexPath];
            self.currentLesson = lesson;
            [self performSegueWithIdentifier:@"lesson" sender:self];
            break;
        case CellLessonDownload:
        case CellLessonUpload:
        case CellDownloadLesson:
        case CellCreateLesson:
        case CellNewPractice:
        case CellEditProfile:
            break;
        case CellEvent:
        {
            NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
            Event *event = [self eventForRowAtIndexPath:indexPath];
            NSNumber *practiceID = event.targetWordID;

            if (event.eventType != EventTypePostPractice)
                return;
            
            self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            self.hud.delegate = self;
            self.hud.mode = MBProgressHUDModeAnnularDeterminate;
            
            [networkManager getWordWithFiles:practiceID withProgress:^(Word *word, NSNumber *progress) {
                self.hud.mode = MBProgressHUDModeAnnularDeterminate;
                self.hud.progress = [progress floatValue];
                if ([progress floatValue] == 1.0) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                    WordDetailController *controller = (WordDetailController *)[storyboard instantiateViewControllerWithIdentifier:@"WordDetailController"];
                    self.currentWord = word;
                    controller.word = word;
                    controller.delegate = self;
                    [self.navigationController pushViewController:controller animated:YES];
                    [self.hud hide:YES];
                }
            }
                                   onFailure:^(NSError *error)
             {
                 [self.hud hide:YES];
                 [NetworkManager hudFlashError:error];
             }];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    self.currentLesson = [self lessonForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"lessonInformation" sender:self];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self lessonForRowAtIndexPath:indexPath])
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.currentLesson = [self lessonForRowAtIndexPath:indexPath];

    if (self.currentLesson.isByCurrentUser && self.currentLesson.isShared) {
        NSString *title = @"You are deleting this lesson from your device. Would you like to continue sharing online?";
        UIActionSheet *confirmDeleteLesson = [[UIActionSheet alloc] initWithTitle:title
                                                                         delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Stop sharing online", @"Keep sharing online", nil];
        [confirmDeleteLesson showInView:self.view];
    } else {
        [self.lessonSet deleteLesson:[self lessonForRowAtIndexPath:indexPath]];
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
        if ([segue.identifier isEqualToString:@"createLesson"]) {
            Profile *me = [Profile currentUserProfile];
            Lesson *lesson = [[Lesson alloc] init];
            lesson.languageTag = me.nativeLanguageTag;
            lesson.userID = me.userID;
            lesson.userName = me.username;
            controller.lesson = lesson;
        } else
            controller.lesson = self.currentLesson;
    } else if ([segue.destinationViewController isKindOfClass:[IntroViewController class]]) {
        IntroViewController *controller = segue.destinationViewController;
        controller.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[DownloadLessonViewController class]]) {
        DownloadLessonViewController *controller = segue.destinationViewController;
        controller.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[ProfileViewController class]]) {
        ProfileViewController *controller = segue.destinationViewController;
        controller.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[WordDetailController class]]) {
        Profile *me = [Profile currentUserProfile];
        WordDetailController *controller = segue.destinationViewController;
        controller.delegate = self;
        self.currentLesson = [[Lesson alloc] init];
        Word *word = [[Word alloc] init];
        word.languageTag = me.learningLanguageTag;
        controller.word = word;
        
        UIBarButtonItem *newButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
    target:controller.navigationItem.rightBarButtonItem.target
                                                                                   action:controller.navigationItem.rightBarButtonItem.action];
        controller.navigationItem.rightBarButtonItem = newButton;
        controller.actionButton = newButton;
        [controller validate];
    } else if ([segue.destinationViewController isKindOfClass:[WebViewController class]]) {
        WebViewController *controller = segue.destinationViewController;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        Profile *me = [Profile currentUserProfile];

        NSMutableString *url = [[SERVER_ECHO_API_URL stringByAppendingPathComponent:@"iPhone/social"] mutableCopy];
        [url appendFormat:@"?lastMessageSeen=%@", [defaults objectForKey:@"lastMessageSeen"]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", @"xx", me.usercode];
        NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedString]];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];

        [controller loadRequest:request];
        [defaults setObject:[NSDate date] forKey:@"lastUpdateSocial"];
        [defaults synchronize];
    }
}

#pragma mark - LessonViewDelegate

- (void)lessonView:(LessonViewController *)controller didSaveLesson:(Lesson *)lesson
{
    [self.lessonSet addOrUpdateLesson:lesson];
    [self.tableView reloadData];
}

- (void)lessonView:(LessonViewController *)controller wantsToUploadLesson:(Lesson *)lesson
{
    [self.lessonSet syncStaleLessonsWithProgress:^(Lesson *lesson, NSNumber *progress){
        NSIndexPath *path = [self indexPathForLesson:lesson];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
    }];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)lessonView:(LessonViewController *)controller wantsToDeleteLesson:(Lesson *)lesson
{
    [self.lessonSet deleteLesson:lesson];
    [self.tableView reloadData];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    Lesson *lesson = self.currentLesson;
    NSIndexPath *indexPath = [self indexPathForLesson:lesson];
    if (buttonIndex == 0) { // Stop sharing
        [self.lessonSet deleteLessonAndStopSharing:lesson
                                         onSuccess:^
         {
             [self.lessonSet deleteLesson:lesson];
             [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
         }
                                         onFailure:^(NSError *error)
         {
             [NetworkManager hudFlashError:error];
         }];
    } else if (buttonIndex == 1) { // Keep sharing
        [self.lessonSet deleteLesson:lesson];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    self.currentLesson = nil;
}

#pragma mark - LessonInformationViewDelegate
    
- (void)lessonInformationView:(LessonInformationViewController *)controller didSaveLesson:(Lesson *)lesson
{
    [self.lessonSet addOrUpdateLesson:lesson];
    [self.tableView reloadData];
    self.currentLesson = lesson;
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self performSegueWithIdentifier:@"lesson" sender:self];
}

#pragma mark - DownloadLessonViewControllerDelegate

- (void)downloadLessonViewController:(DownloadLessonViewController *)controller gotStubLesson:(Lesson *)lesson
{
    NSLog(@"GOT STUB LESSON: %@", [lesson lessonID]);
    NSLog(@"%@",[NSThread callStackSymbols]);

    lesson.remoteChangesSinceLastSync = YES;
    [self.lessonSet addOrUpdateLesson:lesson]; // may or may not add a row
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.lessonSet syncStaleLessonsWithProgress:^(Lesson *lesson, NSNumber *progress){
        NSIndexPath *path = [self indexPathForLesson:lesson];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
    }];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - WordDetailControllerDelegate
- (void)wordDetailController:(WordDetailController *)controller didSaveWord:(Word *)word
{
    self.hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = @"Sending...";

    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager postWord:word AsPracticeWithFilesInPath:NSTemporaryDirectory() withProgress:^(NSNumber *progress)
     {
         self.hud.mode = MBProgressHUDModeAnnularDeterminate;
         self.hud.progress = progress.floatValue;
         NSLog(@"How do I say: upload progress %@", progress);
         if (progress.floatValue == 1.0) {
             UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
             WordDetailController *newController = (WordDetailController *)[storyboard instantiateViewControllerWithIdentifier:@"WordDetailController"];
             newController.delegate = self;
             newController.word = [[(Lesson *)[self.practiceSet.lessons objectAtIndex:0] words] objectAtIndex:0];
             
             // http://stackoverflow.com/questions/9411271/how-to-perform-uikit-call-on-mainthread-from-inside-a-block
             dispatch_async(dispatch_get_main_queue(), ^{
                 [controller.navigationController popViewControllerAnimated:NO];
                 [self.navigationController pushViewController:newController animated:YES];
             });             
             NSLog(@"saved practice word");
         }
     } onFailure:^(NSError *error)
     {
         [self.hud hide:NO];
         [NetworkManager hudFlashError:error];
     }];
}

- (BOOL)wordDetailController:(WordDetailController *)controller canEditWord:(Word *)word
{
    return !word.name; // edit new, virgin word
}

- (void)pushNotificationReceived:(NSNotification*)aNotification
{
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self performSegueWithIdentifier:@"meetPeople" sender:self];
}

// FROM WEB VIEW CONTROLLER..................

#pragma mark - WordDetailViewControllerDelegate

/*
- (BOOL)wordDetailController:(WordDetailController *)controller canEditWord:(Word *)word
{
    return NO;
}
 */

- (BOOL)wordDetailController:(WordDetailController *)controller canReplyWord:(Word *)word
{
    return YES;
}

#pragma mark - WordPracticeViewController

- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice
{
    return self.currentWord;
}

- (BOOL)wordCheckedStateForWordPractice:(WordPracticeController *)wordPractice
{
    return false;
}

- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice
{
}

- (BOOL)currentWordCanBeCheckedForWordPractice:(WordPracticeController *)wordPractice
{
    return false;
}

- (void)wordPractice:(WordPracticeController *)wordPractice setWordCheckedState:(BOOL)state
{
}

- (BOOL)wordPracticeShouldShowNextButton:(WordPracticeController *)wordPractice;
{
    return false;
}


@end
