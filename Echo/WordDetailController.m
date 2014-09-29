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
#import "LanguageSelectController.h"
#import "NetworkManager.h"
#import "MBProgressHUD.h"
#import "Audio.h"
#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"
#import "FDWaveformView.h"
#import "F3BarGauge.h"
#import "FDRightDetailWithTextFieldCell.h"

#define NUMBER_OF_RECORDERS 3

typedef enum {SectionInfo, SectionRecordings, SectionCount} Sections;
typedef enum {CellLanguage, CellTitle, CellDetail, CellRecording} Cells;

@interface WordDetailController () <LanguageSelectControllerDelegate, WordDetailControllerDelegate, MBProgressHUDDelegate>
// Outlets for UI elements
@property (strong, nonatomic) UILabel *wordLabel;
@property (strong, nonatomic) UILabel *detailLabel;
@property (strong, nonatomic) UITextField *wordField;
@property (strong, nonatomic) UITextField *detailField;
@property (strong, nonatomic) NSMutableDictionary *recordButtons;
@property (strong, nonatomic) NSMutableDictionary *recordGuages;
@property (strong, nonatomic) NSMutableDictionary *playButtons;
@property (strong, nonatomic) NSMutableDictionary *waveforms;
@property (strong, nonatomic) NSMutableDictionary *resetButtons;

// Model
@property (strong, nonatomic) NSString *editingLanguageTag;
@property (strong, nonatomic) NSString *editingName;
@property (strong, nonatomic) NSString *editingDetail;
@property (strong, nonatomic) NSMutableDictionary *echoRecorders;

@property (strong, nonatomic) MBProgressHUD *hud;
@end


@implementation WordDetailController 
@synthesize actionButton;
@synthesize wordLabel;
@synthesize detailLabel;
@synthesize echoRecorders = _echoRecorders;
@synthesize recordButtons = _recordButtons;
@synthesize playButtons = _playButtons;
@synthesize waveforms = _waveforms;
@synthesize resetButtons = _resetButtons;
@synthesize editingLanguageTag = _editingLanguageTag;
@synthesize word = _word;
@synthesize delegate = _delegate;
@synthesize hud = _hud;

- (Cells)cellTypeForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case SectionInfo:
            if (indexPath.row == 0)
                return CellLanguage;
            else if (indexPath.row == 1)
                return CellTitle;
            else // (indexPath.row == 2)
                return CellDetail;
        case SectionRecordings:
            return CellRecording;
    }
    assert (0);
    return 0;
}

- (void)makeItBounce:(UIView *)view
{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:1], [NSNumber numberWithFloat:1.2], nil];
    bounceAnimation.duration = 0.15;
    bounceAnimation.removedOnCompletion = NO;
    bounceAnimation.repeatCount = 2;
    bounceAnimation.autoreverses = YES;
    bounceAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
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

- (NSMutableDictionary *)recordButtons
{
    if (!_recordButtons) _recordButtons = [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    return _recordButtons;
}

- (NSMutableDictionary *)recordGuages
{
    if (!_recordGuages) _recordGuages = [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    return _recordGuages;
}

- (NSMutableDictionary *)waveforms
{
    if (!_waveforms) _waveforms = [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    return _waveforms;
}

- (NSMutableDictionary *)playButtons
{
    if (!_playButtons) _playButtons = [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    return _playButtons;
}

- (NSMutableDictionary *)resetButtons
{
    if (!_resetButtons) _resetButtons = [[NSMutableDictionary alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    return _resetButtons;
}

- (IBAction)playButtonPressed:(id)sender
{
    NSNumber *echoIndex =  [[self.playButtons allKeysForObject:sender] objectAtIndex:0];
    PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:echoIndex];
    [recorder playback];
    [self makeItBounce:sender];
}

- (IBAction)recordButtonPressed:(id)sender
{
    NSNumber *echoIndex = [[self.recordButtons allKeysForObject:sender] objectAtIndex:0];
    PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:echoIndex];
    [recorder record];
    [self makeItBounce:sender];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSNumber *echoIndex;
    if ([object isKindOfClass:[PHOREchoRecorder class]])
        echoIndex = [[self.echoRecorders allKeysForObject:object] objectAtIndex:0];
    
    if ([keyPath isEqualToString: @"microphoneLevel"]) {
        F3BarGauge *guage = [self.recordGuages objectForKey:echoIndex];
        guage.value = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
NSLog(@"observed microphoneLevel %@", [change objectForKey:NSKeyValueChangeNewKey]);
    }         
}

- (IBAction)save
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *files = [[NSMutableArray alloc] initWithCapacity:NUMBER_OF_RECORDERS];
    self.word.languageTag = self.editingLanguageTag;
    self.word.name = self.editingName;
    self.word.detail = self.editingDetail;
    for (int i=0; i<[self.echoRecorders count]; i++) {
        PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:[NSNumber numberWithInt:i]];
        Audio *audio;
        if (self.word.files.count > i)
            audio = [self.word.files objectAtIndex:i];
        else {
            audio = [[Audio alloc] init];
            audio.word = self.word;
        }
        if (recorder.audioWasModified) {
            [fileManager removeItemAtURL:audio.fileURL error:nil];
            [fileManager createDirectoryAtURL:self.word.fileURL withIntermediateDirectories:YES attributes:nil error:nil];
            NSError *error = nil;
            [fileManager moveItemAtURL:[recorder getAudioDataURL] toURL:audio.fileURL error:&error];
            if (error)
                NSLog(@"Word file copy error: %@", [error localizedDescription]);
            [files addObject:audio];
        } else {
            [files addObject:[self.word.files objectAtIndex:i]];
        }
    }
    self.word.files = files;
    [self.delegate wordDetailController:self didSaveWord:self.word];
}

- (IBAction)validate
{
    BOOL valid = YES;
    UIColor *goodColor = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].textLabel.textColor;
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
        UIButton *recordButton = [self.recordButtons objectForKey:[NSNumber numberWithInt:i]];
        UIButton *playButton = [self.playButtons objectForKey:[NSNumber numberWithInt:i]];
        UIButton *checkButtons = [self.resetButtons objectForKey:[NSNumber numberWithInt:i]];
        if (!recorder || !recorder.duration) {
            valid = NO;
            recordButton.hidden = NO;
            playButton.hidden = YES;
            checkButtons.hidden = NO;
        } else {
            recordButton.hidden = YES;
            playButton.hidden = NO;
            checkButtons.hidden = NO;
        }
    }
    
    self.actionButton.enabled = valid;
}

- (IBAction)updateName:(UITextField *)sender
{
    self.editingName = sender.text;
    self.title = sender.text;
    [self validate];
}

- (IBAction)updateDetail:(UITextField *)sender
{
    self.editingDetail = sender.text;
    [self validate];
}

- (IBAction)resetButtonPressed:(UIButton *)sender
{
    NSNumber *echoIndex = [[self.resetButtons allKeysForObject:sender] objectAtIndex:0];
    PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:echoIndex];
    [recorder reset];
    [self validate];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:echoIndex inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
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
            Audio *file = [self.word.files objectAtIndex:i];
            recorder = [[PHOREchoRecorder alloc] initWithAudioDataAtURL:file.fileURL];
        }
        else
            recorder = [[PHOREchoRecorder alloc] init];
        recorder.delegate = self;
        [self.echoRecorders setObject:recorder forKey:[NSNumber numberWithInt:i]];
    }
    
    // see http://stackoverflow.com/questions/2246374/low-recording-volume-in-combination-with-avaudiosessioncategoryplayandrecord
    NSError *setCategoryErr = nil;
    NSError *activationErr  = nil;
    //Set the general audio session category
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:&setCategoryErr];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    BOOL success = [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    if (!success) {
        NSLog(@"error doing outputaudioportoverride - %@", [error localizedDescription]);
    }
    
    //Activate the customized audio session
    [[AVAudioSession sharedInstance] setActive: YES error: &activationErr];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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

    id tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"WordDetail"];
    [tracker send:[[GAIDictionaryBuilder createAppView] build]];
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
    for (PHOREchoRecorder *recorder in [self.echoRecorders allValues])
        [recorder removeObserver:self forKeyPath:@"microphoneLevel"];
    [super viewWillDisappear:animated];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SectionInfo)
        return 3;
    else
        return NUMBER_OF_RECORDERS;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    FDRightDetailWithTextFieldCell *FDCell;
    
    switch ([self cellTypeForRowAtIndexPath:indexPath]) {
        case CellLanguage:
            cell = [tableView dequeueReusableCellWithIdentifier:@"language"];
            cell.detailTextLabel.text = [Languages nativeDescriptionForLanguage:self.editingLanguageTag];
            return cell;
        case CellTitle:
            cell = [tableView dequeueReusableCellWithIdentifier:@"word"];
            FDCell = (FDRightDetailWithTextFieldCell *)cell;
            self.wordLabel = cell.textLabel;
            self.wordField = FDCell.textField;
            self.wordField.text = self.editingName;
            self.wordField.enabled = [self.delegate wordDetailController:self canEditWord:self.word];
            self.wordField.delegate = self;
            [self.wordField addTarget:self
                               action:@selector(textFieldDidChange:)
                     forControlEvents:UIControlEventEditingChanged];
            return cell;
        case CellDetail:
            cell = [tableView dequeueReusableCellWithIdentifier:@"detail"];
            FDCell = (FDRightDetailWithTextFieldCell *)cell;
            self.detailLabel = cell.textLabel;
            self.detailField = FDCell.textField;
            self.detailLabel.text = [NSString stringWithFormat:@"Detail (%@)", self.editingLanguageTag];
            self.detailField.text = self.editingDetail;
            self.detailField.enabled = [self.delegate wordDetailController:self canEditWord:self.word];
            self.detailField.delegate = self;
            [self.detailField addTarget:self
                                 action:@selector(textFieldDidChange:)
                       forControlEvents:UIControlEventEditingChanged];
            return cell;
        case CellRecording:
            cell = [tableView dequeueReusableCellWithIdentifier:@"record"];
            
            UIButton *playButton = (UIButton *)[cell viewWithTag:1];
            FDWaveformView *waveform = (FDWaveformView *)[cell viewWithTag:2];
            UIButton *recordButton = (UIButton *)[cell viewWithTag:3];
            F3BarGauge *recordGuage = (F3BarGauge *)[cell viewWithTag:10];
            UIButton *checkbox = (UIButton *)[cell viewWithTag:4];
            PHOREchoRecorder *recorder = [self.echoRecorders objectForKey:@(indexPath.row)];
            
            if (indexPath.row < [self.word.files count]) {
                Audio *file = [self.word.files objectAtIndex:indexPath.row];

                // Workaround because AVURLAsset needs files with file extensions
                // http://stackoverflow.com/questions/9290972/is-it-possible-to-make-avurlasset-work-without-a-file-extension
                NSURL *documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                              inDomains:NSUserDomainMask] lastObject];
                NSURL *tmpURL = [documentsURL URLByAppendingPathComponent:@"tmp.caf"];
                NSFileManager *dfm = [NSFileManager defaultManager];
                [dfm removeItemAtURL:tmpURL error:nil];
                [dfm linkItemAtURL:file.fileURL toURL:tmpURL error:nil];
                waveform.audioURL = tmpURL;
            }
            
            [playButton addSubview:waveform];
            [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:playButton.imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:waveform attribute:NSLayoutAttributeLeft multiplier:1 constant:8]];
            [recordButton addSubview:recordGuage];
            [cell.contentView addConstraint:[NSLayoutConstraint constraintWithItem:recordButton.imageView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:recordGuage attribute:NSLayoutAttributeLeft multiplier:1 constant:8]];
            
            [self.playButtons setObject:playButton forKey:@(indexPath.row)];
            [self.waveforms setObject:waveform forKey:@(indexPath.row)];
            [self.recordButtons setObject:recordButton forKey:@(indexPath.row)];
            [self.recordGuages setObject:recordGuage forKey:@(indexPath.row)];
            [self.resetButtons setObject:checkbox forKey:@(indexPath.row)];
            
            if (![self.delegate wordDetailController:self canEditWord:self.word]) {
                playButton.hidden = NO;
                recordButton.hidden = YES;
                checkbox.hidden = YES;
            } else if (recorder.duration) {
                playButton.hidden = NO;
                recordButton.hidden = YES;
                checkbox.hidden = NO;
                [checkbox setImage:[UIImage imageNamed:@"Checkbox checked"] forState:UIControlStateNormal];
            } else {
                playButton.hidden = YES;
                recordButton.hidden = NO;
                checkbox.hidden = NO;

                [checkbox setImage:[UIImage imageNamed:@"Checkbox empty"] forState:UIControlStateNormal];
            }
            return cell;
    }
    assert (0);
    return 0;
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES]; // fucking nice
}

#pragma mark - UI Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
}

- (void)textFieldDidChange:(UITextField *)textField
{
    if (textField == self.wordField)
        self.editingName = textField.text;
    else
        self.editingDetail = textField.text;
    [self validate];
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
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - WordDetailControllerDelegate

- (BOOL)wordDetailController:(WordDetailController *)controller canEditWord:(Word *)word
{
    return YES;
}

- (void)wordDetailController:(WordDetailController *)controller didSaveWord:(Word *)word
{
    self.hud = [MBProgressHUD showHUDAddedTo:controller.view animated:YES];
    self.hud.labelText = @"Uploading reply";
    self.hud.delegate = self;
    
    NetworkManager *networkManager = [NetworkManager sharedNetworkManager];
    [networkManager postWord:word withFilesInPath:NSTemporaryDirectory() asReplyToWordWithID:self.word.wordID withProgress:^(NSNumber *PGprogress)
     {
        self.hud.mode = MBProgressHUDModeAnnularDeterminate;
        self.hud.progress = PGprogress.floatValue;
        if (PGprogress.floatValue == 1) {
            [self.hud hide:YES];
            // http://stackoverflow.com/questions/9411271/how-to-perform-uikit-call-on-mainthread-from-inside-a-block
            dispatch_async(dispatch_get_main_queue(), ^{
                [controller.navigationController popToRootViewControllerAnimated:YES];
            });
        }
    } onFailure:^(NSError *error){
        [self.hud hide:NO];
        [NetworkManager hudFlashError:error];
    }];
}

#pragma mark - MBProgressHUDDelegate

- (void)hudWasHidden:(MBProgressHUD *)hud
{
    self.hud = nil;
}

@end
