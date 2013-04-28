//
//  LessonInformationViewController.m
//  Echo
//
//  Created by Will Entriken on 8/18/12.
//
//

#import "LessonInformationViewController.h"
#import "LessonViewController.h"
#import "Languages.h"
#import "LanguageSelectController.h"

@interface LessonInformationViewController() <LanguageSelectControllerDelegate>
@property (strong, nonatomic) NSString *editingLanguageTag;
@property (strong, nonatomic) NSString *editingName;
@property (strong, nonatomic) NSMutableDictionary *editingDetail;
@end

@implementation LessonInformationViewController
@synthesize lesson = _lesson;
@synthesize delegate = _delegate;
@synthesize editingName = _editingName;
@synthesize editingDetail = _editingDetail;

- (Lesson *)lesson
{
    if (!_lesson) _lesson = [[Lesson alloc] init];
    return _lesson;
}

- (void)setLesson:(Lesson *)lesson
{
    _lesson = lesson;
    self.editingLanguageTag = lesson.languageTag;
    self.editingName = lesson.name;
    self.editingDetail = [lesson.detail mutableCopy];
}

- (NSMutableDictionary *)editingDetail
{
    if (!_editingDetail) {
        _editingDetail = [[NSMutableDictionary alloc] init];
    }
    
    return _editingDetail;
}

- (IBAction)updateName:(UITextField *)sender {
    self.editingName = sender.text;
    [self validate];
}

- (IBAction)updateDetail:(UITextField *)sender {
    self.editingDetail = [[NSMutableDictionary alloc] init];
    [self.editingDetail setObject:sender.text forKey:self.editingLanguageTag];
    [self validate];
}

- (IBAction)save:(id)sender {
    self.lesson.languageTag = self.editingLanguageTag;
    self.lesson.name = self.editingName;
    self.lesson.detail = self.editingDetail;
    self.lesson.version = [NSNumber numberWithInt:[self.lesson.serverVersion integerValue] + 1];
    [self.delegate lessonInformationView:self didSaveLesson:self.lesson];
}

- (IBAction)validate {
    BOOL valid = YES;
    UIColor *goodColor = [UIColor colorWithRed:81.0/256 green:102.0/256 blue:145.0/256 alpha:1.0];
    UIColor *badColor = [UIColor redColor];

    if (!self.editingLanguageTag.length)
        valid = NO;
    if (self.editingName.length)
        self.lessonLabel.textColor = goodColor;
    else {
        self.lessonLabel.textColor = badColor;
        valid = NO;
    }
    if ([[self.editingDetail objectForKey:self.editingLanguageTag] length])
        self.detailLabel.textColor = goodColor;
    else {
        self.detailLabel.textColor = badColor;
        valid = NO;
    }
    self.detailLabel.text = [NSString stringWithFormat:@"Detail (%@)", self.editingLanguageTag];
//    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItem.enabled = valid;
    self.title = self.editingName;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient.png"]];
    tempImageView.frame = self.tableView.frame;
    self.tableView.backgroundView = tempImageView;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.languageName.text = [Languages nativeDescriptionForLanguage:self.editingLanguageTag];
    self.lessonName.text = self.editingName;
    self.detailText.text = [self.editingDetail objectForKey:self.editingLanguageTag];
    [super viewWillAppear:animated];
    [self validate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.editingLanguageTag) {
        [self performSegueWithIdentifier:@"language" sender:self];
    }
    [self.lessonName becomeFirstResponder];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row != 0) {
        [[[self.tableView cellForRowAtIndexPath:indexPath] viewWithTag:2] becomeFirstResponder];
    }
    [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    if (indexPath.section == 0 && indexPath.row == 0) {
        [self performSegueWithIdentifier:@"language" sender:self];
    }
}

#pragma mark - UIViewController

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[LanguageSelectController class]]) {
        LanguageSelectController *controller = segue.destinationViewController;
        controller.delegate = self;
    }
}

#pragma mark - PHORLanguagesViewControllerDelegate

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    self.editingLanguageTag = tag;
    [self updateDetail:self.detailText];
    [self.tableView reloadData];
}

#pragma mark - UI Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
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