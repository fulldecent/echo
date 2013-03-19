//
//  PHORAddAWordViewController.m
//  EnglishStudy
//
//  Created by Will Entriken on 6/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WordDetailController.h"
#import "Languages.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioServices.h>
#import "Word.h"
#import "Lesson.h"
#import "PHOREchoRecordButton.h"
#import "PHOREchoRecorder.h"
#import "LanguageSelectController.h"
#import "NetworkManager.h"
#import "MBProgressHUD.h"

#define NUMBER_OF_RECORDERS 3

@interface WordDetailController () <LanguageSelectControllerDelegate, WordDetailControllerDelegate, MBProgressHUDDelegate>
// Outlets for UI elements
@property (strong, nonatomic) UILabel *wordLabel;
@property (strong, nonatomic) UILabel *detailLabel;
@property (strong, nonatomic) NSMutableDictionary *echoRecordButtons;
@property (strong, nonatomic) NSMutableDictionary *resetButtons;

// Model
@property (strong, nonatomic) NSString *editingLanguageTag;
@property (strong, nonatomic) NSString *editingName;
@property (strong, nonatomic) NSMutableDictionary *editingDetail;
@property (strong, nonatomic) NSMutableDictionary *echoRecorders;

@property (strong, nonatomic) MBProgressHUD *hud;
@end


@implementation WordDetailController 
@synthesize actionButton;
@synthesize wordLabel;
@synthesize detailLabel;
@synthesize echoRecorders = _echoRecorders;
@synthesize echoRecordButtons = _echoRecordButtons;
@synthesize resetButtons = _resetButtons;
@synthesize editingLanguageTag = _editingLanguageTag;
@synthesize word = _word;
@synthesize delegate = _delegate;
@synthesize hud = _hud;

+ (NSString *)makeUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return (__bridge_transfer NSString *)string;
}

- (Word *)word
{
    if (!_word) _word = [[Word alloc] init];
    return _word;    
}

- (void)setWord:(Word *)word
{
    _word = word;
    self.editingLanguageTag = word.languageTag;
    self.editingName = word.name;
    self.editingDetail = [word.detail mutableCopy];
}

- (NSMutableDictionary *)echoRecorders
{
    if (!_echoRecorders) _echoRecorders = [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    return _echoRecorders;
}

- (NSMutableDictionary *)editingDetail
{
    if (!_editingDetail) _editingDetail = [[NSMutableDictionary alloc] init];
    return _editingDetail;
}

- (NSMutableDictionary *)echoRecordButtons
{
    if (!_echoRecordButtons) _echoRecordButtons = [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    return _echoRecordButtons;
}

- (NSMutableDictionary *)resetButtons
{
    if (!_resetButtons) _resetButtons = [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    return _resetButtons;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSNumber *echoIndex;
    if ([object isKindOfClass:[PHOREchoRecordButton class]])
        echoIndex = [[self.echoRecordButtons allKeysForObject:object] objectAtIndex:0];
    else if ([object isKindOfClass:[PHOREchoRecorder class]]) 
        echoIndex = [[self.echoRecorders allKeysForObject:object] objectAtIndex:0];
    
    if ([keyPath isEqualToString: @"microphoneLevel"]) {
        PHOREchoRecordButton *button = [self.echoRecordButtons objectForKey:echoIndex];
        button.value = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
NSLog(@"observed microphoneLevel %@", [change objectForKey:NSKeyValueChangeNewKey]);
    }         
}

- (IBAction)echoButtonPressed:(PHOREchoRecordButton *)sender {
    NSNumber *echoIndex;
    echoIndex = [[self.echoRecordButtons allKeysForObject:sender] objectAtIndex:0];
    PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:echoIndex];
    
    if (sender.state == PHORRecordButtonStateRecord) {
        [recorder record];
    } else if (sender.state == PHORRecordButtonStatePlayback || sender.state == PHORRecordButtonStatePlaybackOnly) {
        [recorder playback];
    }
    
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1], [NSNumber numberWithFloat:1.2], nil];
    bounceAnimation.duration = 0.15;
    bounceAnimation.removedOnCompletion = NO;
    bounceAnimation.repeatCount = 2;
    bounceAnimation.autoreverses = YES;
    bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [sender.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

- (IBAction)echoButtonReset:(id)sender
{
    NSNumber *echoIndex;
    echoIndex = [[self.echoRecordButtons allKeysForObject:sender] objectAtIndex:0];
    PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:echoIndex];
    [recorder reset];
    [self validate];
}

- (IBAction)save
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *files = [[NSMutableArray alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    for (int i=0; i<[self.echoRecorders count]; i++) {
        PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:[NSNumber numberWithInt:i]];
        if (recorder.audioWasModified) {
            if ([self.word.files count]) {
                NSString *oldFileBaseName = [self.word.files objectAtIndex:i];
                NSString *oldFilePath = [[self.delegate wordDetailControllerSoundDirectoryFilePath:self] stringByAppendingPathComponent:oldFileBaseName];
                [fileManager removeItemAtPath:oldFilePath error:nil];
            }
            
            NSString *temporaryFilePath = [recorder getAudioDataFilePath];
            NSString *permanentFileName = [[WordDetailController makeUUID] stringByAppendingPathExtension:[temporaryFilePath pathExtension]];
            NSString *soundDirectoryFilePath = [self.delegate wordDetailControllerSoundDirectoryFilePath:self];
            NSString *permanentFilePath = [soundDirectoryFilePath stringByAppendingPathComponent:permanentFileName];
            [fileManager createDirectoryAtPath:soundDirectoryFilePath withIntermediateDirectories:YES attributes:nil error:nil];
            NSError *error = nil;
            [fileManager copyItemAtURL:[NSURL fileURLWithPath:temporaryFilePath]
                                 toURL:[NSURL fileURLWithPath:permanentFilePath]
                                 error:&error];
            if (error)
                NSLog(@"Word file copy error: %@", [error localizedDescription]);
            [files addObject:permanentFileName];
        } else {
            [files addObject:[self.word.files objectAtIndex:i]];
        }
    }
    self.word.files = [files copy];
    self.word.languageTag = self.editingLanguageTag;
    self.word.name = self.editingName;
    self.word.detail = self.editingDetail;
    [self.delegate wordDetailController:self didSaveWord:self.word];
}
                                                  
- (IBAction)validate
{
    BOOL valid = YES;
    UIColor *goodColor = [UIColor colorWithRed:81.0/256 green:102.0/256 blue:145.0/256 alpha:1.0];
    UIColor *badColor = [UIColor redColor];
    

    if (!self.editingLanguageTag.length)
        valid = NO;
    
    if (self.editingName.length)
        self.wordLabel.textColor = goodColor;
    else {
        self.wordLabel.textColor = badColor;
        valid = NO;
    }
    
    for (int i=0; i<NUMBER_OF_RECORDERS; i++) {
        PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:[NSNumber numberWithInt:i]];
        PHOREchoRecordButton *button = [self.echoRecordButtons objectForKey:[NSNumber numberWithInt:i]];
        
        if (recorder.duration) {
            button.state = PHORRecordButtonStatePlayback;
        } else {
            if (button.state != PHORRecordButtonStateRecord) // if statement prevents deadlock with observeValue:
                button.state = PHORRecordButtonStateRecord;
            valid = NO;
        }
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationNone];
    
    self.actionButton.enabled = valid;
}

- (IBAction)updateName:(UITextField *)sender
{
    self.editingName = sender.text;
    self.title = sender.text;
//    for (PHOREchoRecordButton *button in [self.echoRecordButtons allValues])
//        [button setTitle:sender.text forState:UIControlStateNormal];
    [self validate];
}

- (IBAction)updateDetail:(UITextField *)sender
{
    [self.editingDetail setObject:sender.text forKey:self.editingLanguageTag];
    [self validate];
}

- (IBAction)resetButtonPressed:(UIButton *)sender
{
    NSNumber *echoIndex;
    echoIndex = [[self.resetButtons allKeysForObject:sender] objectAtIndex:0];
    PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:echoIndex];
    PHOREchoRecordButton *button = [self.echoRecordButtons objectForKey:echoIndex];
    [recorder reset];
    [button setValue:PHORRecordButtonStateRecord];
    [self validate];
}

- (IBAction)reply:(UIBarButtonItem *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    WordDetailController *wordDetail = (WordDetailController *)[storyboard instantiateViewControllerWithIdentifier:@"WordDetailController"];
    wordDetail.delegate = self;
    Word *replyWord = [[Word alloc] init];
    replyWord.languageTag = self.word.languageTag;
    replyWord.name = self.word.name;
    replyWord.detail = [self.word.detail copy];
    wordDetail.word = replyWord;
    [self.navigationController pushViewController:wordDetail animated:YES];
}

- (void)setup
{
    for (int i=0; i<NUMBER_OF_RECORDERS; i++) {
        PHOREchoRecorder *recorder;
        if (i < [self.word.files count]) {
            NSString *soundDirectoryFilePath = [self.delegate wordDetailControllerSoundDirectoryFilePath:self];
            NSString *filePath = [soundDirectoryFilePath stringByAppendingPathComponent:[self.word.files objectAtIndex:i]];
            recorder = [[PHOREchoRecorder alloc] initWithAudioDataAtFilePath:filePath];
        }
        else
            recorder = [[PHOREchoRecorder alloc] init];
        recorder.delegate = self;
        [self.echoRecorders setObject:recorder forKey:[NSNumber numberWithInt:i]];
    }
    
    /*
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute,
                            sizeof(audioRouteOverride), &audioRouteOverride);
     */
    
    // see http://stackoverflow.com/questions/2246374/low-recording-volume-in-combination-with-avaudiosessioncategoryplayandrecord
    NSError *setCategoryErr = nil;
    NSError *activationErr  = nil;
    //Set the general audio session category
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error: &setCategoryErr];
    
    //Make the default sound route for the session be to use the speaker
    UInt32 doChangeDefaultRoute = 1;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof (doChangeDefaultRoute), &doChangeDefaultRoute);
    
    //Activate the customized audio session
    [[AVAudioSession sharedInstance] setActive: YES error: &activationErr];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradient.png"]];
    tempImageView.frame = self.tableView.frame;
    self.tableView.backgroundView = tempImageView;
    [self setup];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    for (PHOREchoRecorder *recorder in [self.echoRecorders allValues])
        [recorder addObserver:self forKeyPath:@"microphoneLevel" options:NSKeyValueObservingOptionNew context:nil];
    self.title = self.word.name;
    if (![self.delegate wordDetailController:self canEditWord:self.word]) {
        if ([self.delegate respondsToSelector:@selector(wordDetailController:canReplyWord:)] &&
            [self.delegate wordDetailController:self canReplyWord:self.word]) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemReply target:self action:@selector(reply:)];
        } else
            self.navigationItem.rightBarButtonItem = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.delegate wordDetailController:self canEditWord:self.word])
        [self validate];
    if (!self.editingLanguageTag)
        [self performSegueWithIdentifier:@"language" sender:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"child viewWillDisappear start");
    for (PHOREchoRecorder *recorder in [self.echoRecorders allValues])
        [recorder removeObserver:self forKeyPath:@"microphoneLevel"];
    [super viewWillDisappear:animated];
    NSLog(@"child viewWillDisappear returning");
}

- (void)viewDidDisappear:(BOOL)animated
{
    NSLog(@"child viewDidDisappear start");
    [super viewDidDisappear:animated];
    NSLog(@"child viewDidDisappear returning");    
}

- (void)viewDidUnload
{
    self.actionButton = nil;
    self.echoRecorders = nil;
    [super viewDidUnload];
}

- (void)uploadWordAsNewPracticeLesson
{
    Lesson *lesson = [[Lesson alloc] init];
    lesson.name = @"PRACTICE";
    lesson.detail = [NSDictionary dictionaryWithObject:self.word.name forKey:self.word.languageTag];
    lesson.languageTag = self.word.languageTag;
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.delegate = self;
    hud.labelText = @"Sharing practice word";
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) { // Language, Word, Detail
        return 3;
    } else {
        return NUMBER_OF_RECORDERS;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
/*
    if (section == 0) {
        if (self.editingLanguageTag.length)
            return [@"Word in " stringByAppendingString:[Languages nativeDescriptionForLanguage:self.editingLanguageTag]];
        else
            return @"Word";
    }
    else
*/
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"language"];
            cell.detailTextLabel.text = [Languages nativeDescriptionForLanguage:self.editingLanguageTag];
        } else if (indexPath.row == 1) { // Word
            cell = [tableView dequeueReusableCellWithIdentifier:@"word"];
            self.wordLabel = (UILabel *)[cell viewWithTag:1];
            // self.wordLabel.text; // Automatically set
            UITextField *textField = (UITextField *)[cell viewWithTag:2];
            textField.text = self.editingName;
            textField.enabled = [self.delegate wordDetailController:self canEditWord:self.word];
            textField.delegate = self;
        } else /*if (indexPath.row == 2)*/ { // Detail
            cell = [tableView dequeueReusableCellWithIdentifier:@"detail"];
            self.detailLabel = (UILabel *)[cell viewWithTag:1];
            self.detailLabel.text = [NSString stringWithFormat:@"Detail (%@)", self.editingLanguageTag];
            UITextField *textField = (UITextField *)[cell viewWithTag:2];
            textField.text = [self.editingDetail objectForKey:self.editingLanguageTag];
            textField.enabled = [self.delegate wordDetailController:self canEditWord:self.word];
            textField.delegate = self;
        }
        
    } else /*if (indexPath.section == 1)*/ {
        cell = [tableView dequeueReusableCellWithIdentifier:@"record"];
        UIImageView *checkbox = (UIImageView *)[cell viewWithTag:1];
        PHOREchoRecordButton *button = (PHOREchoRecordButton *)[cell viewWithTag:2];
        UIButton *resetButton = (UIButton *)[cell viewWithTag:3];
        PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:[NSNumber numberWithInt:indexPath.row]];
        [self.echoRecordButtons setObject:button forKey:[NSNumber numberWithInt:indexPath.row]];
        [self.resetButtons setObject:resetButton forKey:[NSNumber numberWithInt:indexPath.row]];
        
        if (![self.delegate wordDetailController:self canEditWord:self.word]) {
            button.state = PHORRecordButtonStatePlaybackOnly;
            checkbox.hidden = YES;
            
            [(UIButton *)[cell viewWithTag:3] setHidden:YES];
        } else if (recorder.duration) {
            button.state = PHORRecordButtonStatePlayback;
            [checkbox setImage:[UIImage imageNamed:@"Checkbox checked"]];
            
            [(UIButton *)[cell viewWithTag:3] setEnabled:YES];
            [(UIButton *)[cell viewWithTag:3] setImage:[UIImage imageNamed:@"Checkbox checked"] forState:UIControlStateNormal];
        } else {
            if (button.state != PHORRecordButtonStateRecord) // if statement prevents deadlock with observeValue:
                button.state = PHORRecordButtonStateRecord;
            [checkbox setImage:[UIImage imageNamed:@"Checkbox empty"]];
            
            [(UIButton *)[cell viewWithTag:3] setImage:[UIImage imageNamed:@"Checkbox empty"] forState:UIControlStateNormal];
            [(UIButton *)[cell viewWithTag:3] setEnabled:NO];
        }
        
        [button setTitle:self.editingName forState:UIControlStateNormal];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        cell.backgroundColor = [UIColor clearColor];
        cell.backgroundView = nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return 80;
    } else {
        return self.tableView.rowHeight;
    }
}

#pragma mark - UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[LanguageSelectController class]]) {
        LanguageSelectController *controller = segue.destinationViewController;
        controller.delegate = self;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row != 0) {
        [[[self.tableView cellForRowAtIndexPath:indexPath] viewWithTag:2] becomeFirstResponder];
    } 
    [self.tableView selectRowAtIndexPath:nil animated:YES scrollPosition:UITableViewScrollPositionNone];
    if (indexPath.section == 0 && indexPath.row == 0 && [self.delegate wordDetailController:self canEditWord:self.word]) {
        [self performSegueWithIdentifier:@"language" sender:self];        
    }
}

#pragma mark - ScrollView

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES]; // fucking nice
}

#pragma mark - UI Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [textField resignFirstResponder];
}

#pragma mark - PHOR Echo Recorder Delegate

- (void)recording:(id)recorder didFinishSuccessfully:(BOOL)success
{
    if (!success) return;
    [self validate];
}

#pragma mark - LanguageSelectControllerDelegate

- (void)languageSelectController:(id)controller didSelectLanguage:(NSString *)tag withNativeName:(NSString *)name
{
    self.editingLanguageTag = tag;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self validate];
}

#pragma mark - WordDetailControllerDelegate

- (BOOL)wordDetailController:(WordDetailController *)controller canEditWord:(Word *)word
{
    return YES;
}

- (void)wordDetailController:(WordDetailController *)controller didSaveWord:(Word *)word
{
    self.hud = [MBProgressHUD HUDForView:self.view];
    self.hud.labelText = @"Uploading reply";
    self.hud.delegate = self;
                
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager uploadWord:word withFilesAtPath:NSTemporaryDirectory() inReplyToWord:self.word withProgress:^(NSNumber *PGprogress) {
        self.hud.progress = PGprogress.floatValue;
        if (PGprogress.floatValue == 1) {
            [self.hud hide:YES afterDelay:0.5];
            // http://stackoverflow.com/questions/9411271/how-to-perform-uikit-call-on-mainthread-from-inside-a-block
            dispatch_async(dispatch_get_main_queue(), ^{
                [controller.navigationController popToRootViewControllerAnimated:YES];
            });
        }
    } onFailure:^{
        self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.hud.delegate = self;
        self.hud.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"37x-BigX.png"]];
        [self.hud hide:YES];
    }];
}

- (NSString *)wordDetailControllerSoundDirectoryFilePath:(WordDetailController *)controller
{
    return NSTemporaryDirectory();
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
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
