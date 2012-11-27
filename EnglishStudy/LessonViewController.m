//
//  EchoWordListController.m
//  EnglishStudy
//
//  Created by Will Entriken on 6/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LessonViewController.h"
#import "Word.h"
#import "WordDetailController.h"
#import "Languages.h"
#import "NetworkManager.h"
#import "MBProgressHUD.h"
#import "SHK.h"
#import "UIImageView+AFNetworking.h"

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
    [self.actionSheet showFromTabBar:self.tabBarController.tabBar];
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
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
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
    NSArray *shuffleRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]];
    NSArray *addRow = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self.lesson.words count] inSection:1]];
    
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
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]  withRowAnimation:YES];
    }
    [self.tableView endUpdates];
}

#pragma mark - Word Practice Data Source

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

- (void)skipToNextWordForWordPractice:(WordPracticeController *)wordPractice
{
    if (self.wordListIsShuffled)
        self.currentWordIndex = arc4random() % [self.lesson.words count];
    else
        self.currentWordIndex = (self.currentWordIndex + 1) % [self.lesson.words count];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return [self.lesson.detail objectForKey:self.lesson.languageTag];
    else
        return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == 0 && self.lesson.userName) {
        CGRect footerFrame = [tableView rectForFooterInSection:section];
        UIView *footer = [[UIView alloc] initWithFrame:footerFrame];

        CGRect labelFrame = CGRectMake(40, 10, footerFrame.size.width - 60, footerFrame.size.height - 30);
        UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
        label.text = self.lesson.userName;
        // Colors and font
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:13];
        label.shadowColor = [UIColor colorWithWhite:0.8 alpha:0.8];
        label.textColor = [UIColor blackColor];
        // Automatic word wrap
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.textAlignment = UITextAlignmentCenter;
        label.numberOfLines = 0;
        // Autosize
        [label sizeToFit];
        // Add the UILabel to the tableview
        
        UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(20, 10, 16, 16)];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://learnwithecho.com/avatarFiles/%@.png",self.lesson.userID]];
        [image setImageWithURL:url placeholderImage:[UIImage imageNamed:@"none40"]];

        
        [footer addSubview:label];
        [footer addSubview:image];

        return footer;
    } else
        return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0 && self.lesson.userName)
        return 40;
    else
        return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    int retval;
    if (section == 0) {
        if (self.editing && !self.editingFromSwipe)
            return 0;
        else
            return 1;
    } else {    
        retval = [self.lesson.words count];
        if (retval || (self.tableView.editing && !self.editingFromSwipe))
            retval++;
        return retval;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == 0 && !(self.editing && !self.editingFromSwipe)) {
        if (indexPath.row == 0) {
            if (self.lesson.isEditable && !self.lesson.isShared) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"notShared"];
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:@"header2online"];

                for(int i=1; i<=4; i++) {
                    UIGlossyButton *b = (UIGlossyButton*) [cell viewWithTag: i];
                    b.tintColor = [UIColor greenColor];
                    b.backgroundOpacity = 1;
                    b.innerBorderWidth = 2.0f;
                    b.buttonBorderWidth = 0.0f;
                    b.buttonCornerRadius = 10.0f;
                    [b setGradientType: kUIGlossyButtonGradientTypeSolid];
                    [b setExtraShadingType:kUIGlossyButtonExtraShadingTypeRounded];
                    b.tintColor = [UIColor lightGrayColor];
                }
                
                if (self.lesson.submittedLikeVote && [self.lesson.submittedLikeVote boolValue])
                    [(UIGlossyButton *)[cell viewWithTag:3] setTintColor:[UIColor greenColor]];
            }
        }
    } else {
        if (indexPath.row == 0 && !(self.tableView.editing && !self.editingFromSwipe))
            cell = [tableView dequeueReusableCellWithIdentifier:@"shuffle"];
        else if (indexPath.row == [self.lesson.words count] && (self.tableView.editing && !self.editingFromSwipe))
            cell = [tableView dequeueReusableCellWithIdentifier:@"add"];
        else { // A normal word in the lesson
            cell = [tableView dequeueReusableCellWithIdentifier:@"word"];
            int index = (self.tableView.editing && !self.editingFromSwipe) ? indexPath.row : indexPath.row-1;
            Word *word = [self.lesson.words objectAtIndex:index];
            cell.textLabel.text = word.name;
            cell.detailTextLabel.text = word.nativeDetail;
            if ([self.lesson.lessonCode length] == 0)
                cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        cell.backgroundColor = [UIColor colorWithHue:0.63 saturation:0.1 brightness:0.97 alpha:1];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        return NO;
    else {
        if (indexPath.row == 0 && !(self.tableView.editing && !self.editingFromSwipe)) {
            return NO;
        } else if (indexPath.row == [self.lesson.words count] && (self.tableView.editing && !self.editingFromSwipe)) {
            return NO;
        } else { // A normal word in the lesson
            return YES;
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section == 1 && proposedDestinationIndexPath.row < [self.lesson.words count])
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
    if (indexPath.section == 1) {
        if (editingStyle == UITableViewCellEditingStyleInsert) {
            self.currentWordIndex = indexPath.row;
            [self performSegueWithIdentifier:@"editWord" sender:self];
        } else if (editingStyle == UITableViewCellEditingStyleDelete) {
            NSMutableArray *words = [self.lesson.words mutableCopy];
            NSUInteger index = self.editingFromSwipe ? indexPath.row - 1 : indexPath.row;
            [self.tableView beginUpdates];
            [words removeObjectAtIndex:index];
            self.lesson.words = [words copy];
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            if (![words count])
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    if (indexPath.section == 0) {
        return nil;
    } else {
        if (indexPath.row == 0 && !(self.tableView.editing && !self.editingFromSwipe)) {
            return indexPath;
        } else if (indexPath.row == [self.lesson.words count] && (self.tableView.editing && !self.editingFromSwipe)) {
            return indexPath;
        } else if (self.tableView.editing && !self.editingFromSwipe) { // A normal word in the lesson
            return nil;
        } else {
            return indexPath;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        if (indexPath.row == 0 && !(self.tableView.editing && !self.editingFromSwipe)) {
            self.wordListIsShuffled = YES;
            [self skipToNextWordForWordPractice:nil];
            [self performSegueWithIdentifier:@"echoWord" sender:self];
        } else if (indexPath.row == [self.lesson.words count] && (self.tableView.editing && !self.editingFromSwipe)) {
            [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
        } else { // A normal word in the lesson
            self.currentWordIndex = indexPath.row - 1;
            self.wordListIsShuffled = NO; 
            [self performSegueWithIdentifier:@"echoWord" sender:self];
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleNone;
    } else if (indexPath.section == 1 && (self.editing && !self.editingFromSwipe)) {
        if (indexPath.row == [self.lesson.words count])
            return UITableViewCellEditingStyleInsert;
        else
            return UITableViewCellEditingStyleDelete;
    } else /* if (indexPath.section == 1 && !self.editing) */ {
        if (indexPath.row == 0) 
            return UITableViewCellEditingStyleNone;
        else 
            return UITableViewCellEditingStyleDelete;
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
        WordPracticeController *echoViewController = segue.destinationViewController;
        echoViewController.datasource = self;
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

#pragma mark - Translate View Controller Delegate

- (void)wordDetailController:(WordDetailController *)controller didSaveWord:(Word *)word 
{
    if (self.editing && self.currentWordIndex == [self.lesson.words count]) { // new word
        self.lesson.words = [self.lesson.words arrayByAddingObject:word];
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.currentWordIndex inSection:1]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if ((self.editing && !self.editingFromSwipe)) { // existing row
        NSMutableArray *words = [self.lesson.words mutableCopy];
        [words replaceObjectAtIndex:self.currentWordIndex withObject:word];
        self.lesson.words = [words copy];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.currentWordIndex inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else /* !self.editing */ {
        NSMutableArray *words = [self.lesson.words mutableCopy];
        [words replaceObjectAtIndex:self.currentWordIndex withObject:word];
        self.lesson.words = [words copy];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.currentWordIndex+1 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
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

#pragma mark - PHORLanguagesViewControllerDelegate

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    NSMutableDictionary *dict = [self.lesson.detail mutableCopy];
    [dict setObject:[NSString string] forKey:tag];
    self.lesson.detail = [dict copy];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
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
