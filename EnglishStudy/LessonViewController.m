//
//  EchoWordListController.m
//  EnglishStudy
//
//  Created by Will Entriken on 6/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LessonViewController.h"
#import "WordDetailController.h"
#import "Languages.h"
#import "NetworkManager.h"
#import "MBProgressHUD.h"
#import "SHK.h"
#import "UIImageView+AFNetworking.h"

typedef enum {SectionActions, SectionWords, SectionByline, SectionCount} Sections;
typedef enum {CellActions, CellShared, CellNotShared, CellShuffle, CellWord, CellAddWord, CellAuthorByline} Cells;

@interface LessonViewController () <WordDetailControllerDelegate, MBProgressHUDDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
@property (nonatomic) int currentWordIndex;
@property (nonatomic) BOOL wordListIsShuffled;
@property (nonatomic) BOOL editingFromSwipe;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) UIActionSheet *actionSheet;
@end

@implementation LessonViewController
@synthesize lesson = _lesson;
@synthesize currentWordIndex = _currentIndex;
@synthesize wordListIsShuffled = _wordListIsShuffled;
@synthesize delegate = _delegate;
@synthesize editingFromSwipe = _editingFromSwipe;
@synthesize hud = _hud;
@synthesize actionSheet = _actionSheet;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient.png"]];
    tempImageView.frame = self.tableView.frame;
    self.tableView.backgroundView = tempImageView;
}

//TODO: should be a datasource
- (void)setLesson:(Lesson *)lesson
{
    if ([lesson.lessonCode length]) {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        if (lesson.words.count == 0) {
            self.editing = YES;
        }
    } else {
        self.navigationItem.rightBarButtonItem = nil;
    }
    _lesson = lesson;
}

- (IBAction)likePressed:(id)sender {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = @"Sending...";
    
    NSNumber *newState = [NSNumber numberWithBool:!self.lesson.submittedLikeVote || [self.lesson.submittedLikeVote boolValue] == NO];
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
        [networkManager likeLesson:self.lesson withState:newState onSuccess:^
         {
             self.lesson.submittedLikeVote = newState;
             [self.hud hide:YES];
             [self.delegate lessonView:self didSaveLesson:self.lesson];
             [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
                                   withRowAnimation:UITableViewRowAnimationNone];
         } onFailure:^(NSError *error)
         {
             [self.hud hide:YES];
             self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
             self.hud.delegate = self;
             self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-BigX.png"]];
             UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
             view.text = error.localizedDescription;
             view.font = self.hud.labelFont;
             view.textColor = [UIColor whiteColor];
             view.backgroundColor = [UIColor clearColor];
             [view sizeToFit];
             self.hud.customView = view;
             self.hud.mode = MBProgressHUDModeCustomView;
             [self.hud hide:YES afterDelay:1.5];
         }];
}

- (IBAction)flagPressed:(id)sender {
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"Flagging a lesson is public and will delete your copy of the lesson. To continue, choose a reason."
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:@"Inappropriate title", @"Inaccurate content", @"Poor quality", nil];
    self.actionSheet.tag = 0;
    [self.actionSheet showInView:self.view];
}

- (IBAction)sendToFriendPressed:(id)sender {
        
    // Create the item to share (in this example, a url)
    NSString *urlString = [NSString stringWithFormat:@"http://learnwithecho.com/lessons/%d", [self.lesson.lessonID integerValue]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *title = [NSString stringWithFormat:@"I am practicing a lesson in %@: %@",
                       [Languages nativeDescriptionForLanguage:self.lesson.languageTag],
                       self.lesson.name];
    SHKItem *item = [SHKItem URL:url title:title contentType:SHKURLContentTypeWebpage];
    
    // Get the ShareKit action sheet
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    
    // ShareKit detects top view controller (the one intended to present ShareKit UI) automatically,
    // but sometimes it may not find one. To be safe, set it explicitly
    [SHK setRootViewController:self];
    
    // Display the action sheet
//    [actionSheet showFromTabBar:self.tabBarController.tabBar];
    [actionSheet showInView:self.view];
}

- (IBAction)messagePressed:(id)sender {    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Send a message to the lesson author"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Send", nil];
    alertView.tag = 0;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (IBAction)share:(id)sender {
    [self.delegate lessonView:self wantsToUploadLesson:self.lesson];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = self.lesson.name;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (editing == self.editing)
        return;
    
    [self.tableView beginUpdates];
    NSArray *shuffleRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:SectionWords]];
    NSArray *addRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.lesson.words count] inSection:SectionWords]];
    
    if (!self.editingFromSwipe) {
        if (editing) {
            if ([self.lesson.words count])
                [self.tableView deleteRowsAtIndexPaths:shuffleRow withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:addRow withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.navigationItem setHidesBackButton:YES animated:YES];
        } else {
            [self.tableView deleteRowsAtIndexPaths:addRow withRowAnimation:UITableViewRowAnimationAutomatic];
            if ([self.lesson.words count])
                [self.tableView insertRowsAtIndexPaths:shuffleRow withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.navigationItem setHidesBackButton:NO animated:YES];
        }
    }

    [super setEditing:editing animated:animated];
    [self.tableView setEditing:editing animated:animated];

    if (!self.editingFromSwipe) {
        if (!editing) {
            self.lesson.version = [NSNumber numberWithInt:[self.lesson.serverVersion integerValue] + 1];
            [self.delegate lessonView:self didSaveLesson:self.lesson];
            self.title = self.lesson.name;
        }
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionActions] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionByline] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self.tableView endUpdates];
}

#pragma mark - WordPracticeDataSource
- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice
{
    return [self.lesson.words objectAtIndex:self.currentWordIndex];
}

- (NSString *)currentSoundDirectoryFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *lessonPath;
    NSString *wordPath;
    if (self.lesson.lessonCode.length) {
        lessonPath = [documentsPath stringByAppendingPathComponent:self.lesson.lessonCode];
        wordPath = [lessonPath stringByAppendingPathComponent:[[self.lesson.words objectAtIndex:self.currentWordIndex] wordCode]];
    }
    else {
        NSString *lessonIDString = [NSString stringWithFormat:@"%d", [self.lesson.lessonID integerValue]];
        lessonPath = [documentsPath stringByAppendingPathComponent:lessonIDString];
        NSNumber *wordID = [[self.lesson.words objectAtIndex:self.currentWordIndex] wordID];
        wordPath = [lessonPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d", [wordID integerValue]]];
    }
    return wordPath;
}

- (BOOL)wordCheckedStateForWordPractice:(WordPracticeController *)wordPractice
{
    Word *word = [self.lesson.words objectAtIndex:self.currentWordIndex];
    return [word.completed boolValue];
}

#pragma mark - WordPracticeDelegate
- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice
{
    if (self.wordListIsShuffled)
        self.currentWordIndex = arc4random() % [self.lesson.words count];
    else
        self.currentWordIndex = (self.currentWordIndex + 1) % [self.lesson.words count];
}

- (BOOL)currentWordCanBeCheckedForWordPractice:(WordPracticeController *)wordPractice
{
    return YES;
}

- (BOOL)wordPracticeShouldShowNextButton:(WordPracticeController *)wordPractice;
{
    return YES;
}

- (void)wordPractice:(WordPracticeController *)wordPractice setWordCheckedState:(BOOL)state
{
    Word *word = [self.lesson.words objectAtIndex:self.currentWordIndex];
    word.completed = [NSNumber numberWithBool:state];
    [self.delegate lessonView:self didSaveLesson:self.lesson];
    NSIndexPath *path = [NSIndexPath indexPathForRow:self.currentWordIndex+1 inSection:SectionWords];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view data source

- (Cells)cellTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case SectionActions:
            if (self.lesson.isEditable)
                return self.lesson.isShared ? CellShared : CellNotShared;
            else
                return CellActions;
        case SectionWords:
            if (indexPath.row == 0 && !(self.tableView.editing && !self.editingFromSwipe))
                return CellShuffle;
            else if (indexPath.row == [self.lesson.words count] && (self.tableView.editing && !self.editingFromSwipe))
                return CellAddWord;
            else
                return CellWord;
        case SectionByline:
            return CellAuthorByline;
    }
    assert (0);
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SectionCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return [self.lesson.detail objectForKey:self.lesson.languageTag];
    else
        return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SectionActions:
            return (self.editing && !self.editingFromSwipe) ? 0 : 1;
        case SectionWords:
            if ([self.lesson.words count] || (self.tableView.editing && !self.editingFromSwipe))
                return [self.lesson.words count] + 1; // add or shuffle button
            else
                return [self.lesson.words count];
        case SectionByline:
            return self.lesson.isEditable ? 0 : 1;
    }
    assert(0);
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    Word *word;
    int index;
    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellNotShared:
            return [tableView dequeueReusableCellWithIdentifier:@"notShared"];
        case CellShared:
            return [tableView dequeueReusableCellWithIdentifier:@"shared"];
        case CellActions:
            cell = [tableView dequeueReusableCellWithIdentifier:@"header2online"];
            if (self.lesson.submittedLikeVote && [self.lesson.submittedLikeVote boolValue])
                [(UIGlossyButton *)[cell viewWithTag:3] setTintColor:[UIColor greenColor]];
            return cell;
        case CellAddWord:
            return [tableView dequeueReusableCellWithIdentifier:@"add"];
        case CellShuffle:
            return [tableView dequeueReusableCellWithIdentifier:@"shuffle"];
        case CellWord:
            cell = [tableView dequeueReusableCellWithIdentifier:@"word"];
            index = (self.tableView.editing && !self.editingFromSwipe) ? indexPath.row : indexPath.row-1;
            word = [self.lesson.words objectAtIndex:index];
            cell.textLabel.text = word.name;
            cell.detailTextLabel.text = word.nativeDetail;
            if (self.lesson.isEditable)
                cell.accessoryType = UITableViewCellAccessoryNone;
            else if ([word.completed boolValue])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
            return cell;
        case CellAuthorByline:
            cell = [tableView dequeueReusableCellWithIdentifier:@"author"];
            cell.textLabel.text = self.lesson.userName;
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://learnwithecho.com/avatarFiles/%@.png",self.lesson.userID]];
            [cell.imageView setImageWithURL:url placeholderImage:[UIImage imageNamed:@"none40"]];
            UIGlossyButton *button = [[UIGlossyButton alloc] initWithFrame:CGRectMake(0, 0, 42, 38)];
            [button setImage:[UIImage imageNamed:@"message"] forState:UIControlStateNormal];
            button.tintColor = [UIColor greenColor];
            button.backgroundOpacity = 1;
            button.innerBorderWidth = 2.0f;
            button.buttonBorderWidth = 0.0f;
            button.buttonCornerRadius = 10.0f;
            [button setGradientType: kUIGlossyButtonGradientTypeSolid];
            [button setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
            button.tintColor = [UIColor lightGrayColor];
            [button addTarget:self action:@selector(messagePressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = button;
            return cell;
    }
    assert(0); return 0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionActions)
        cell.backgroundColor = [UIColor colorWithHue:0.63 saturation:0.1 brightness:0.97 alpha:1];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != SectionWords)
        return NO;
    return self.lesson.isEditable && [self cellTypeForRowAtIndexPath:indexPath] == CellWord;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section != sourceIndexPath.section)
        return sourceIndexPath;
    if (proposedDestinationIndexPath.row < self.lesson.words.count)
        return proposedDestinationIndexPath;
    else
        return sourceIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSMutableArray *words = [self.lesson.words mutableCopy];
    Word *word = [words objectAtIndex:sourceIndexPath.row];
    [words removeObjectAtIndex:sourceIndexPath.row];
    [words insertObject:word atIndex:destinationIndexPath.row];
    self.lesson.words = [words copy];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionWords) {
        if (editingStyle == UITableViewCellEditingStyleInsert) {
            self.currentWordIndex = self.lesson.words.count;
            [self performSegueWithIdentifier:@"editWord" sender:self];
        } else if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSMutableArray *words = [self.lesson.words mutableCopy];
            NSUInteger index = self.editingFromSwipe ? indexPath.row - 1 : indexPath.row;
            [self.tableView beginUpdates];
            [words removeObjectAtIndex:index];
            self.lesson.words = [words copy];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (![words count])
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:SectionWords]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            [self.lesson removeStaleFiles];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.editingFromSwipe = YES;
    [super tableView:tableView willBeginEditingRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didEndEditingRowAtIndexPath:indexPath];
    self.editingFromSwipe = NO;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != SectionWords)
        return nil;
    return (self.tableView.editing && !self.editingFromSwipe) ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellShuffle:
            self.wordListIsShuffled = YES;
            [self skipToNextWordForWordPractice:nil];
            [self performSegueWithIdentifier:@"echoWord" sender:self];
            break;
        case CellAddWord:
            [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
            break;
        case CellWord:
            self.currentWordIndex = indexPath.row - 1;
            self.wordListIsShuffled = NO;
            [self performSegueWithIdentifier:@"echoWord" sender:self];
        default:
            break;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.lesson.isEditable)
        return UITableViewCellEditingStyleNone;
    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellAddWord:
            return UITableViewCellEditingStyleInsert;
        case CellWord:
            return UITableViewCellEditingStyleDelete;
        default:
            return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    self.currentWordIndex = indexPath.row-1;
    self.wordListIsShuffled = NO; 
    [self performSegueWithIdentifier:@"editWord" sender:self];
}

#pragma mark -

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[WordPracticeController class]]) {
        WordPracticeController *controller = segue.destinationViewController;
        controller.datasource = self;
        controller.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[WordDetailController class]]) {
        WordDetailController *controller = segue.destinationViewController;
        controller.delegate = self;
        if (self.currentWordIndex < [self.lesson.words count]) {
            controller.word = [self.lesson.words objectAtIndex:self.currentWordIndex];
        } else {
            Word *word = [[Word alloc] init];
            word.languageTag = self.lesson.languageTag;
            controller.word = word;
        }
    }
}

#pragma mark - wordDetailController Delegate

- (void)wordDetailController:(WordDetailController *)controller didSaveWord:(Word *)word 
{
    // PRECONDITION: self.tableView.editing && !self.editingFromSwipe
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentWordIndex inSection:SectionWords];
    if (self.currentWordIndex == self.lesson.words.count) {
        self.lesson.words = [self.lesson.words arrayByAddingObject:word];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        NSMutableArray *words = [self.lesson.words mutableCopy];
        [words replaceObjectAtIndex:self.currentWordIndex withObject:word];
        self.lesson.words = [words copy];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    self.lesson.version = [NSNumber numberWithInt:[self.lesson.serverVersion integerValue] + 1];
    [self.delegate lessonView:self didSaveLesson:self.lesson];
    [controller.navigationController popViewControllerAnimated:YES];
}

- (NSString *)wordDetailControllerSoundDirectoryFilePath:(WordDetailController *)controller
{
    NSString *lessonPath = self.lesson.filePath;
    NSString *wordPath = [lessonPath stringByAppendingPathComponent:controller.word.wordCode];
    return wordPath;
}

- (BOOL)wordDetailController:(WordDetailController *)controller canEditWord:(Word *)word
{
    return YES;
}

#pragma mark - UI Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == self.actionSheet.cancelButtonIndex)
        return;
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = @"Sending...";
    
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager flagLesson:self.lesson withReason:buttonIndex onSuccess:^
     {
         [self.hud hide:YES];
         [self.delegate lessonView:self wantsToDeleteLesson:self.lesson];
         [self.navigationController popViewControllerAnimated:YES];
     } onFailure:^(NSError *error)
     {
         [self.hud hide:YES];
         self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
         self.hud.delegate = self;
         self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-BigX.png"]];
         UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
         view.text = error.localizedDescription;
         view.font = self.hud.labelFont;
         view.textColor = [UIColor whiteColor];
         view.backgroundColor = [UIColor clearColor];
         [view sizeToFit];
         self.hud.customView = view;
         self.hud.mode = MBProgressHUDModeCustomView;
         [self.hud hide:YES afterDelay:1.5];
     }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode = MBProgressHUDModeIndeterminate;
        self.hud.labelText = @"Sending...";

        NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
        NSString *message = [alertView textFieldAtIndex:0].text;
        [networkManager sendLesson:self.lesson authorAMessage:message
                         onSuccess:^
         {
             [self.hud hide:YES];
         } onFailure:^(NSError *error) {
             NSLog(@"Send message failure");
             [self.hud hide:YES];
             self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
             self.hud.delegate = self;
             self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-BigX.png"]];
             UITextView *view = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
             view.text = error.localizedDescription;
             view.font = self.hud.labelFont;
             view.textColor = [UIColor whiteColor];
             view.backgroundColor = [UIColor clearColor];
             [view sizeToFit];
             self.hud.customView = view;
             self.hud.mode = MBProgressHUDModeCustomView;
             [self.hud hide:YES afterDelay:1.5];
         }];
    };
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
