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
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

typedef enum {SectionActions, SectionEditingInfo, SectionWords, SectionByline, SectionCount} Sections;
typedef enum {CellShared, CellNotShared, CellShuffle, CellWord, CellAddWord, CellAuthorByline, CellEditLanguage, CellEditTitle, CellEditDescription} Cells;

@interface LessonViewController () <WordDetailControllerDelegate, MBProgressHUDDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
@property (nonatomic) int currentWordIndex;
@property (nonatomic) BOOL wordListIsShuffled;
@property (nonatomic) BOOL editingFromSwipe;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) UIActionSheet *actionSheet;
@property (nonatomic) BOOL actionIsToLessonAuthor;



@end

@implementation LessonViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"LessonView"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

//TODO: should be a datasource
- (void)setLesson:(Lesson *)lesson
{
    NSMutableArray *buttons = [[NSMutableArray alloc] init];
    if (lesson.isByCurrentUser) {
        [buttons addObject:self.editButtonItem];
        if (lesson.words.count == 0)
            self.editing = YES;
    }
    [buttons addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(lessonSharePressed:)]];
    self.navigationItem.rightBarButtonItems = buttons;
    _lesson = lesson;
}

- (IBAction)lessonFlagPressed:(id)sender {
    self.actionIsToLessonAuthor = YES;
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"Flagging a lesson is public and will delete your copy of the lesson. To continue, choose a reason."
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:@"Inappropriate title", @"Inaccurate content", @"Poor quality", nil];
    self.actionSheet.tag = 0;
    [self.actionSheet showInView:self.view];
}

- (IBAction)lessonSharePressed:(id)sender {
    // Create the item to share (in this example, a url)
    NSString *urlString = [NSString stringWithFormat:@"https://learnwithecho.com/lessons/%ld", (long)[self.lesson.lessonID integerValue]];
    NSURL *url = [NSURL URLWithString:urlString];
    NSString *title = [NSString stringWithFormat:@"I am practicing a lesson in %@: %@",
                       [Languages nativeDescriptionForLanguage:self.lesson.languageTag],
                       self.lesson.name];
    NSArray *itemsToShare = @[url, title];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll]; //or whichever you don't need
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)lessonReplyAuthorPressed:(id)sender {
    self.actionIsToLessonAuthor = YES;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Send feedback"
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Send", nil];
    alertView.tag = 0;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
}

- (IBAction)sharePressed:(id)sender {
    self.lesson.localChangesSinceLastSync = YES;
    [self.delegate lessonView:self wantsToUploadLesson:self.lesson];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if (editing == self.editing)
        return;
    
    [self.tableView beginUpdates];
    NSArray *shuffleRow = @[[NSIndexPath indexPathForRow:0 inSection:SectionWords]];
    NSArray *addRow = @[[NSIndexPath indexPathForRow:[self.lesson.words count] inSection:SectionWords]];
    
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
            if ([self.lesson isShared])
                self.lesson.localChangesSinceLastSync = YES;
            [self.delegate lessonView:self didSaveLesson:self.lesson];
            self.title = self.lesson.name;
        }
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionActions] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionByline] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SectionEditingInfo] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [self.tableView endUpdates];
}

#pragma mark - WordPracticeDataSource
- (Word *)currentWordForWordPractice:(WordPracticeController *)wordPractice
{
    return (self.lesson.words)[self.currentWordIndex];
}

- (BOOL)wordCheckedStateForWordPractice:(WordPracticeController *)wordPractice
{
    Word *word = (self.lesson.words)[self.currentWordIndex];
    return word.completed;
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
    Word *word = (self.lesson.words)[self.currentWordIndex];
    word.completed = @(state);
    [self.delegate lessonView:self didSaveLesson:self.lesson];
    NSIndexPath *path = [NSIndexPath indexPathForRow:self.currentWordIndex+1 inSection:SectionWords];
    [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view data source

- (Cells)cellTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case SectionActions:
            if ([self.lesson isByCurrentUser])
                return self.lesson.isShared ? CellShared : CellNotShared;
            else
                return CellAuthorByline;
        case SectionEditingInfo:
            if (indexPath.row == 0) {
                return CellEditLanguage;
            } else if (indexPath.row == 1) {
                return CellEditTitle;
            } else
                return CellEditDescription;
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
        return self.lesson.detail;
    else
        return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SectionActions:
            if (self.editing && !self.editingFromSwipe)
                return 0;
            else
                return 1;
        case SectionEditingInfo:
            if (self.editing && !self.editingFromSwipe)
                return 3;
            else
                return 0;
        case SectionWords:
            if ([self.lesson.words count] || (self.tableView.editing && !self.editingFromSwipe))
                return [self.lesson.words count] + 1; // add or shuffle button
            else
                return [self.lesson.words count];
        case SectionByline:
            return 0;
    }
    assert(0);
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    FDRightDetailWithTextFieldCell *fdCell;
    Word *word;
    NSInteger index;
    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellNotShared:
            return [tableView dequeueReusableCellWithIdentifier:@"notShared"];
        case CellShared:
            return [tableView dequeueReusableCellWithIdentifier:@"shared"];
        case CellAddWord:
            return [tableView dequeueReusableCellWithIdentifier:@"add"];
        case CellShuffle:
            return [tableView dequeueReusableCellWithIdentifier:@"shuffle"];
        case CellWord: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"word"];
            index = (self.tableView.editing && !self.editingFromSwipe) ? indexPath.row : indexPath.row-1;
            word = (self.lesson.words)[index];
            cell.textLabel.text = word.name;
            cell.detailTextLabel.text = word.detail;

            if (self.lesson.isByCurrentUser)
                cell.accessoryType = UITableViewCellAccessoryNone;
            else if (word.completed)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
            return cell;
        }
        case CellAuthorByline: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"author"];
            cell.textLabel.text = self.lesson.userName;
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://learnwithecho.com/avatarFiles/%@.png",self.lesson.userID]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [cell.imageView setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"none40"] success:nil failure:nil];
            
            UIButton *flagButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [flagButton setImage:[UIImage imageNamed:@"flag"] forState:UIControlStateNormal];
            [flagButton setFrame:CGRectMake(0, 0, 40, 40)];
            [flagButton addTarget:self action:@selector(lessonFlagPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = flagButton;
            return cell;
        }
        case CellEditLanguage:
            cell = [tableView dequeueReusableCellWithIdentifier:@"editLanguage"];
            cell.detailTextLabel.text = [Languages nativeDescriptionForLanguage:self.lesson.languageTag];
            return cell;
        case CellEditTitle:
            cell = [tableView dequeueReusableCellWithIdentifier:@"editTitle"];
            fdCell = (FDRightDetailWithTextFieldCell *)cell;
            fdCell.textField.text = self.lesson.name;
            [fdCell.textField addTarget:self action:@selector(nameTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            return cell;
        case CellEditDescription:
            cell = [tableView dequeueReusableCellWithIdentifier:@"editDetail"];
            fdCell = (FDRightDetailWithTextFieldCell *)cell;
            fdCell.textField.text = self.lesson.detail;
            [fdCell.textField addTarget:self action:@selector(detailTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            return cell;
    }
    assert(0); return 0;
}

- (void)nameTextFieldDidChange:(UITextField *)textField
{
    self.lesson.name = textField.text;
}

- (void)detailTextFieldDidChange:(UITextField *)textField
{
    self.lesson.detail = textField.text;
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
    return self.lesson.isByCurrentUser && [self cellTypeForRowAtIndexPath:indexPath] == CellWord;
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
    Word *word = words[sourceIndexPath.row];
    [words removeObjectAtIndex:sourceIndexPath.row];
    [words insertObject:word atIndex:destinationIndexPath.row];
    self.lesson.words = [words copy];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SectionWords) {
        if (editingStyle == UITableViewCellEditingStyleInsert) {
            self.currentWordIndex = (int) self.lesson.words.count;
            [self performSegueWithIdentifier:@"editWord" sender:self];
        } else if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSMutableArray *words = [self.lesson.words mutableCopy];
            NSUInteger index = self.editingFromSwipe ? indexPath.row - 1 : indexPath.row;
            [self.tableView beginUpdates];
            [words removeObjectAtIndex:index];
            self.lesson.words = [words copy];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (![words count])
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SectionWords]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    if (self.editing) {
        switch ([self cellTypeForRowAtIndexPath:indexPath]) {
            case CellAddWord:
                return indexPath;
            default:
                return nil;
        }
    } else {
        switch ([self cellTypeForRowAtIndexPath:indexPath]) {
            case CellWord:
            case CellShuffle:
            case CellAddWord:
                return indexPath;
            default:
                return nil;
        }
    }
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
            self.currentWordIndex = (int) indexPath.row - 1;
            self.wordListIsShuffled = NO;
            [self performSegueWithIdentifier:@"echoWord" sender:self];
        case CellAuthorByline:
            break;//TODO LOAD AUTHOR PAGE FROM WEBVIEW HERE
        default:
            break;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.lesson.isByCurrentUser)
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
    self.currentWordIndex = (int) indexPath.row-1;
    self.wordListIsShuffled = NO; 
    [self performSegueWithIdentifier:@"editWord" sender:self];
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[WordPracticeController class]]) {
        WordPracticeController *controller = segue.destinationViewController;
        controller.datasource = self;
        controller.delegate = self;
    } else if ([segue.destinationViewController isKindOfClass:[WordDetailController class]]) {
        WordDetailController *controller = segue.destinationViewController;
        controller.delegate = self;
        if (self.currentWordIndex < [self.lesson.words count]) {
            controller.word = (self.lesson.words)[self.currentWordIndex];
        } else {
            Word *word = [[Word alloc] init];
            word.languageTag = self.lesson.languageTag;
            word.lesson = self.lesson;
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
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        NSMutableArray *words = [self.lesson.words mutableCopy];
        words[self.currentWordIndex] = word;
        self.lesson.words = [words copy];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    if ([self.lesson isShared])
        self.lesson.localChangesSinceLastSync = YES;
    [self.delegate lessonView:self didSaveLesson:self.lesson];
    [controller.navigationController popViewControllerAnimated:YES];
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
    Lesson *target;
    if (self.actionIsToLessonAuthor)
        target = self.lesson;
    
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager doFlagLesson:target withReason:(enum NetworkManagerFlagReason) buttonIndex onSuccess:^
     {
         self.hud.mode = MBProgressHUDModeDeterminate;
         self.hud.progress = 1;
         [self.hud hide:YES];
         [self.delegate lessonView:self wantsToDeleteLesson:self.lesson];
         [self.navigationController popViewControllerAnimated:YES];
     } onFailure:^(NSError *error)
     {
         [self.hud hide:NO];
         [NetworkManager hudFlashError:error];
     }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.mode = MBProgressHUDModeIndeterminate;
        self.hud.labelText = @"Sending...";
        Lesson *target;
        if (self.actionIsToLessonAuthor)
            target = self.lesson;

        NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
        NSString *message = [alertView textFieldAtIndex:0].text;
        [networkManager postFeedback:message toAuthorOfLessonWithID:target.lessonID
                           onSuccess:^
         {
             self.hud.mode = MBProgressHUDModeDeterminate;
             self.hud.progress = 1;
             [self.hud hide:YES];
         } onFailure:^(NSError *error) {
             [self.hud hide:YES];
             [NetworkManager hudFlashError:error];
         }];
    };
}

@end
