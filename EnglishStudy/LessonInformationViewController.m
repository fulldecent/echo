//
//  LessonInformationViewController.m
//  Echo
//
//  Created by Will Entriken on 8/18/12.
//
//

#import "LessonInformationViewController.h"
#import "LessonViewController.h"
#import "Word.h"
#import "Languages.h"

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
        [_editingDetail setObject:@"" forKey:@"en"];
    }
    
    return _editingDetail;
}

- (IBAction)updateName:(UITextField *)sender {
    self.editingName = sender.text;
    [self validate];
}

- (IBAction)updateDetail:(UITextField *)sender {
    id cellView = [sender superview];
    UITableViewCell *cell = (UITableViewCell *)[cellView superview];
    UITableView *tableView = (UITableView *)[cell superview];
    NSIndexPath *indexPath = [tableView indexPathForCell:cell];
    NSString *languageTag = [[Languages sortedListOfLanguages:self.editingDetail.allKeys] objectAtIndex:indexPath.row];
    [self.editingDetail setObject:sender.text forKey:languageTag];
    [self validate];
}

- (IBAction)save:(id)sender {
    self.lesson.languageTag = self.editingLanguageTag;
    self.lesson.name = self.editingName;
    self.lesson.detail = self.editingDetail;
    self.lesson.version = [NSNumber numberWithInt:[self.lesson.serverVersion integerValue] + 1];
    [self.delegate lessonInformationView:self didSaveLesson:self.lesson];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)validate {
    BOOL valid = YES;

    UILabel *lessonLabel = (UILabel *)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]] viewWithTag:1];
    if (self.editingName.length == 0) {
        valid = NO;
        lessonLabel.textColor = [UIColor redColor];
    } else {
        lessonLabel.textColor = [UIColor colorWithRed:81.0/255.0 green:102.0/255.0 blue:145.0/255.0 alpha:1.0];
    }

    NSUInteger enIndex = [[Languages sortedListOfLanguages:[self.editingDetail allKeys]] indexOfObject:@"en"];
    UILabel *enDetail = (UILabel *)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:enIndex inSection:1]] viewWithTag:1];
    if ([(NSString *)[self.editingDetail objectForKey:@"en"] length] == 0) {
        valid = NO;
        enDetail.textColor = [UIColor redColor];
    } else {
        enDetail.textColor = [UIColor colorWithRed:81.0/255.0 green:102.0/255.0 blue:145.0/255.0 alpha:1.0];
    }
    
    NSUInteger nativeIndex = [[Languages sortedListOfLanguages:[self.editingDetail allKeys]] indexOfObject:self.editingLanguageTag];
    UILabel *nativeDetail = (UILabel *)[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:nativeIndex inSection:1]] viewWithTag:1];
    if ([(NSString *)[self.editingDetail objectForKey:self.editingLanguageTag] length] == 0) {
        valid = NO;
        nativeDetail.textColor = [UIColor redColor];
    } else {
        nativeDetail.textColor = [UIColor colorWithRed:81.0/255.0 green:102.0/255.0 blue:145.0/255.0 alpha:1.0];
    }

    self.navigationItem.rightBarButtonItem.enabled = valid;
    self.title = self.editingName;
}

- (void)viewDidLoad
{
    self.editing = YES;
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self validate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.editingLanguageTag) {
        [self performSegueWithIdentifier:@"language" sender:self];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        if (self.editingLanguageTag.length)
            return [@"Lesson in " stringByAppendingString:[Languages nativeDescriptionForLanguage:self.editingLanguageTag]];
        else
            return @"Lesson";
    }
    else
        return @"Detail by language";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return 1;
    else
        return [self.editingDetail count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"name"];
        UITextField *field = (UITextField *)[cell viewWithTag:2];
        field.text = self.editingName;
        field.delegate = self;
    } else if (indexPath.row < self.editingDetail.count) {
        NSString *languageTag = [[Languages sortedListOfLanguages:self.editingDetail.allKeys] objectAtIndex:indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:@"detail"];
        UILabel *view1 = (UILabel *)[cell viewWithTag:1];
        view1.text = languageTag;
        UITextField *view2 = (UITextField *)[cell viewWithTag:2];
        view2.text = [self.editingDetail objectForKey:languageTag];
        view2.placeholder = [NSString stringWithFormat:@"Detail in %@", [Languages nativeDescriptionForLanguage:languageTag]];
        view2.delegate = self;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"addDetails"];
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == self.editingDetail.count)
        return indexPath;
    else
        return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == self.editingDetail.count)
        [self performSegueWithIdentifier:@"language" sender:self];
    else {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [(UITextField *)[cell viewWithTag:1] becomeFirstResponder];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleNone;
    } else if (indexPath.row == self.editingDetail.count) {
        return UITableViewCellEditingStyleInsert;
    } else {
        NSString *language = [[Languages sortedListOfLanguages:self.editingDetail.allKeys] objectAtIndex:indexPath.row];
        if ([language isEqualToString:@"en"] || [language isEqualToString:self.editingLanguageTag])
            return UITableViewCellEditingStyleNone;
        else
            return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleInsert) {
        [self performSegueWithIdentifier:@"language" sender:self];
    } else {
        NSString *languageTag = [[Languages sortedListOfLanguages:self.editingDetail.allKeys] objectAtIndex:indexPath.row];
        [self.editingDetail removeObjectForKey:languageTag];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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
    if (!self.editingLanguageTag) { // language select was to set lesson language
        self.editingLanguageTag = tag;
        [self.editingDetail setObject:@"" forKey:tag];
        [self.tableView reloadData];
    } else {
        [self.editingDetail setObject:[NSString string] forKey:tag];
        [self.tableView reloadData];
        
        //[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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