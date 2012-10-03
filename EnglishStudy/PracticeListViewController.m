//
//  PracticeListViewController.m
//  Echo
//
//  Created by Will Entriken on 8/20/12.
//
//

#import "PracticeListViewController.h"
#import "WordDetailController.h"
#import "WordPracticeController.h"
#import "LessonSet.h"
#import "MBProgressHUD.h"
#import "UIGlossyButton.h"
#import "SHK.h"
#import "Languages.h"

@interface PracticeListViewController () <WordDetailControllerDelegate, MBProgressHUDDelegate, WordPracticeDataSource>
- (void)wordDetailController:(WordDetailController *)controller didSaveWord:(Word *)word;
- (NSString *)wordDetailControllerSoundDirectoryFilePath:(WordDetailController *)controller;
- (BOOL)wordDetailController:(WordDetailController *)controller canEditWord:(Word *)word;

@property (strong, nonatomic) LessonSet *practiceLessonSet;
@property (strong, nonatomic) Lesson *currentLesson;
@property (strong, nonatomic) Word *wordToPlay;
@property (nonatomic) BOOL isCreatingNewWord;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (nonatomic) NSInteger currentWordIndex;
@property (strong, nonatomic) UIBarButtonItem *refreshButton;
@property (strong, nonatomic) UIBarButtonItem *loadingButton;
@end

@implementation PracticeListViewController
@synthesize practiceLessonSet = _practiceLessonSet;
@synthesize currentLesson = _currentLesson;
@synthesize wordToPlay = _wordToPlay;
@synthesize isCreatingNewWord = _isCreatingNewWord;
@synthesize hud = _hud;
@synthesize currentWordIndex = _currentWordIndex;
@synthesize refreshButton = _refreshButton;
@synthesize loadingButton = _loadingButton;

- (LessonSet *)practiceLessonSet
{
    if (!_practiceLessonSet) _practiceLessonSet = [LessonSet lessonSetWithName:@"practiceLessons"];
    return _practiceLessonSet;
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.leftBarButtonItem = self.refreshButton;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.practiceLessonSet.lessons.count)
        return self.practiceLessonSet.lessons.count + 1;
    else
        return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.practiceLessonSet.lessons.count == 0)
        return @"Creating a new practice word will share your voice online for others to give feedback.";
    else
        return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section < self.practiceLessonSet.lessons.count) {
        if ([[self.practiceLessonSet.lessons objectAtIndex:section] words].count == 1) {
            return @"No replies yet. Try the share button?";
        }
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (self.practiceLessonSet.lessons.count == 0) {
        UIImageView *view = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"introPractice"]];
        view.contentMode = UIViewContentModeCenter;
        return view;
    } else
        return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (self.practiceLessonSet.lessons.count == 0)
        return 278;
    else if (section < self.practiceLessonSet.lessons.count) {
        if ([[self.practiceLessonSet.lessons objectAtIndex:section] words].count == 1) {
            return 30;
        }
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section < self.practiceLessonSet.lessons.count)
        return [[self.practiceLessonSet.lessons objectAtIndex:section] words].count;
    else if (section == self.practiceLessonSet.lessons.count)
        return 1;
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == self.practiceLessonSet.lessons.count) {
        return [tableView dequeueReusableCellWithIdentifier:@"new"];    
    }
    
    Lesson *lesson = [self.practiceLessonSet.lessons objectAtIndex:indexPath.section];
    Word *word = [lesson.words objectAtIndex:indexPath.row];
    UITableViewCell *cell;
    
    if (indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"intro"];
        [(UILabel *)[cell viewWithTag:1] setText:word.name];
        if (lesson.isShared) {
            [(UILabel *)[cell viewWithTag:2] setText:@"Shared online"];
            [cell viewWithTag:3].hidden = NO;
        }
        else {
            [(UILabel *)[cell viewWithTag:2] setText:@"Not yet uploaded"];
            [cell viewWithTag:3].hidden = YES;
        }
        UIGlossyButton *b = (UIGlossyButton*) [cell viewWithTag: 3];
        b.tintColor = [UIColor greenColor];
        b.backgroundOpacity = 1;
        b.innerBorderWidth = 2.0f;
        b.buttonBorderWidth = 0.0f;
        b.buttonCornerRadius = 10.0f;
        [b setGradientType: kUIGlossyButtonGradientTypeSolid];
        [b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
        b.tintColor = [UIColor lightGrayColor];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"subtitle"];
        cell.textLabel.text = word.name;
        cell.detailTextLabel.text = word.userName;
    }

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section < self.practiceLessonSet.lessons.count) {
        Lesson *lesson = [self.practiceLessonSet.lessons objectAtIndex:indexPath.section];
        Word *word = [lesson.words objectAtIndex:indexPath.row];
        self.currentLesson = lesson;
        self.wordToPlay = word;
        self.currentWordIndex = indexPath.row;
        
        if (indexPath.row == 0)
            [self performSegueWithIdentifier:@"playWord" sender:self];
        else
            [self performSegueWithIdentifier:@"echoWord" sender:self];
    } else {
        // handled by storyboard
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Lesson *lesson = [self.practiceLessonSet.lessons objectAtIndex:indexPath.section];
    if (indexPath.row == 0) {
        if (lesson.isShared) {
            [self.practiceLessonSet deleteLessonAndStopSharing:lesson onSuccess:^{
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
            } onFailure:^(NSError *error) {
            }];
        } else {
            [self.practiceLessonSet.lessons removeObjectAtIndex:indexPath.section];
            [self.practiceLessonSet writeToDisk];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } else {
        NSMutableArray *words = [lesson.words mutableCopy];
        NSUInteger index = indexPath.row;
        [self.tableView beginUpdates];
        [words removeObjectAtIndex:index];
        lesson.words = [words copy];
        lesson.version = [NSNumber numberWithInt:[lesson.serverVersion integerValue] + 1];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        [lesson removeStaleFiles];
        [self reload:nil];
    }
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[WordDetailController class]]) {
        WordDetailController *controller = segue.destinationViewController;
        controller.delegate = self;
        if ([segue.identifier isEqualToString:@"playWord"]) {
            controller.word = self.wordToPlay;
            self.isCreatingNewWord = NO;
        } else {
            self.currentLesson = [[Lesson alloc] init];
            self.isCreatingNewWord = YES;
        }
    } else if ([segue.destinationViewController isKindOfClass:[WordPracticeController class]]) {
        WordPracticeController *echoViewController = segue.destinationViewController;
        echoViewController.datasource = self;
    }
}

#pragma mark - WorkEditControllerDelegate
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
    
    /*
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.delegate = self;
	self.hud.mode = MBProgressHUDModeDeterminate;
    self.hud.labelText = @"Sharing practice word";
    
    [self.practiceLessonSet syncLesson:self.currentLesson withProgress:^(Lesson *lesson, NSNumber *progress)
     {
         self.hud.progress = [progress floatValue];
         if ([progress isEqualToNumber:[NSNumber numberWithInt:1]]) {
             [self.hud hide:YES afterDelay:0.5];
             [self.tableView reloadData];
         }
     }];
    */
    
    [self.practiceLessonSet syncLesson:self.currentLesson withProgress:^(Lesson *lesson, NSNumber *progress)
     {
        NSUInteger index = [self.practiceLessonSet.lessons indexOfObject:lesson];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (progress.integerValue == 1.0)
            self.navigationItem.leftBarButtonItem = self.refreshButton;
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
    return self.isCreatingNewWord;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
}

#pragma mark - Word Practice Data Source

- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice
{
    return [self.currentLesson.words objectAtIndex:self.currentWordIndex];
}

- (NSString *)currentSoundDirectoryFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *lessonPath;
    NSString *wordPath;
    if (self.currentLesson.lessonCode.length) {
        lessonPath = [documentsPath stringByAppendingPathComponent:self.currentLesson.lessonCode];
        wordPath = [lessonPath stringByAppendingPathComponent:[[self.currentLesson.words objectAtIndex:self.currentWordIndex] wordCode]];
    }
    else {
        NSString *lessonIDString = [NSString stringWithFormat:@"%d", [self.currentLesson.lessonID integerValue]];
        lessonPath = [documentsPath stringByAppendingPathComponent:lessonIDString];
        NSNumber *wordID = [[self.currentLesson.words objectAtIndex:self.currentWordIndex] wordID];
        wordPath = [lessonPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [wordID integerValue]]];
    }
    return wordPath;
}

- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice
{
    self.currentWordIndex++;
    if (self.currentWordIndex == self.currentLesson.words.count)
        self.currentWordIndex = 1; // skip request word
}

- (IBAction)sendToFriendPressed:(UIButton *)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender.superview.superview];
    Lesson *lesson = [self.practiceLessonSet.lessons objectAtIndex:indexPath.section];
    
    // Create the item to share (in this example, a url)
    NSString *urlString = [NSString stringWithFormat:@"http://learnwithecho.com/lessons/%d", [lesson.lessonID integerValue]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *title = [NSString stringWithFormat:@"I am practicing a word in %@: %@",
                       [Languages nativeDescriptionForLanguage:lesson.languageTag],
                       [(Word *)[lesson.words objectAtIndex:0] name]];
    SHKItem *item = [SHKItem URL:url title:title contentType:SHKURLContentTypeWebpage];
    
    // Get the ShareKit action sheet
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    
    // ShareKit detects top view controller (the one intended to present ShareKit UI) automatically,
    // but sometimes it may not find one. To be safe, set it explicitly
    [SHK setRootViewController:self];
    
    // Display the action sheet
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (IBAction)reload:(id)sender {
    self.navigationItem.leftBarButtonItem = self.loadingButton;
    [self.practiceLessonSet markStaleLessonsWithCallback:^
     {
         [self.practiceLessonSet syncStaleLessonsWithProgress:^(Lesson *lesson, NSNumber *progress) {
             NSUInteger index = [self.practiceLessonSet.lessons indexOfObject:lesson];
             [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationAutomatic];
         }];
         self.navigationItem.leftBarButtonItem = self.refreshButton;
         [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
     }];
}

- (void)updateBadgeCount
{
    [self.practiceLessonSet markStaleLessonsWithCallback:^
     {
         NSString *badge = self.practiceLessonSet.countOfLessonsNeedingSync ? [NSString stringWithFormat:@"%d", self.practiceLessonSet.countOfLessonsNeedingSync] : nil;
         self.navigationController.tabBarItem.badgeValue = badge;
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
