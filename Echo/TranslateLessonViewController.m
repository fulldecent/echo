//
//  TranslateLessonViewController.m
//  Echo
//
//  Created by Will Entriken on 4/28/13.
//
//

#import "TranslateLessonViewController.h"
#import "LanguageSelectController.h"
#import "Profile.h"
#import "Languages.h"
#import "Word.h"
#import "NetworkManager.h"
#import "Lesson.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@interface TranslateLessonViewController () <LanguageSelectControllerDelegate, UITextFieldDelegate>
@property Lesson *originalLesson;
@property Lesson *translatedLesson;
@end

@implementation TranslateLessonViewController
@synthesize originalLesson = _originalLesson;
@synthesize translatedLesson = _translatedLesson;

- (void)viewDidLoad
{
    [super viewDidLoad];
    Profile *me = [Profile currentUserProfile];
    self.originalLesson = [self.datasource lessonToTranslateForTranslateLessonView:self];
    self.translatedLesson = [[Lesson alloc] init];
    [self.translatedLesson setToLesson:(self.originalLesson.translations)[me.nativeLanguageTag]];
    self.translatedLesson.languageTag = me.nativeLanguageTag;
    self.translatedLesson.lessonCode = self.originalLesson.lessonCode;
    self.translatedLesson.userID = me.userID;
    self.translatedLesson.userName = me.username;
    NSMutableArray *words = [[NSMutableArray alloc] init];
    for (Word *word in self.originalLesson.words) {
        Word *translatedWord = [self.originalLesson wordWithCode:word.wordCode translatedTo:self.translatedLesson.languageTag];
        if (!translatedWord) {
            translatedWord = [[Word alloc] init];
            translatedWord.wordCode = word.wordCode;
        }
        [words addObject:translatedWord];
    }
    self.translatedLesson.words = words;
    [self validate];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"TranslateLesson"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)save:(id)sender
{
    [self.datasource translateLessonView:self didTranslate:self.originalLesson into:self.translatedLesson withLanguageTag:self.translatedLesson.languageTag];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 3;
    return self.originalLesson.words.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"language"];
        cell.detailTextLabel.text = [Languages nativeDescriptionForLanguage:self.translatedLesson.languageTag];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"textField"];
        UITextField *textField = (UITextField *)[cell viewWithTag:1];
        [textField removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [textField addTarget:self action:@selector(updatedTextForTextField:) forControlEvents:UIControlEventEditingChanged];
        if (indexPath.section == 0 && indexPath.row == 1) {
            textField.placeholder = self.originalLesson.name;
            textField.text = self.translatedLesson.name;
        } else if (indexPath.section == 0 && indexPath.row == 2) {
            textField.placeholder = self.originalLesson.detail;
            textField.text = self.translatedLesson.detail;
        } else {
            textField.placeholder = [(Word *)(self.originalLesson.words)[indexPath.row] name];
            textField.text = [(Word *)(self.translatedLesson.words)[indexPath.row] name];
        }
        textField.delegate = self;
        if (textField.text.length)
            textField.backgroundColor = [UIColor whiteColor];
        else
            textField.backgroundColor = [UIColor colorWithRed:256.0/256 green:220.0/256 blue:220.0/256 alpha:1.0];
    }
    return cell;
}

- (void)updatedTextForTextField:(UITextField *)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    if (indexPath.section == 0 && indexPath.row == 1)
        self.translatedLesson.name = sender.text;
    else if (indexPath.section == 0 && indexPath.row == 2)
        self.translatedLesson.detail = sender.text;
    else
        [(Word *)(self.translatedLesson.words)[indexPath.row] setName:sender.text];
    if (sender.text.length)
        sender.backgroundColor = [UIColor whiteColor];
    else
        sender.backgroundColor = [UIColor colorWithRed:256.0/256 green:220.0/256 blue:220.0/256 alpha:1.0];
    [self validate];
}

- (IBAction)validate {
    BOOL valid = YES;
    if (!self.translatedLesson.name.length)
        valid = NO;
    if (!self.translatedLesson.detail.length)
        valid = NO;
    for (Word *word in self.translatedLesson.words)
        if (!word.name.length)
            valid = NO;
    self.navigationItem.rightBarButtonItem.enabled = valid;
}

#pragma mark - UIView

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[LanguageSelectController class]]) {
        LanguageSelectController *controller = segue.destinationViewController;
        controller.delegate = self;
    }
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0)
        return indexPath;
    return nil;
}

#pragma mark - PHORLanguagesViewControllerDelegate

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    self.translatedLesson.languageTag = tag;
    [self.tableView reloadData];
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
