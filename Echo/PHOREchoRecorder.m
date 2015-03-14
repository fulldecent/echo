//
//  PHORRecordModel.m
//  Test Record 2
//
//  Created by Will Entriken on 5/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PHOREchoRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface PHOREchoRecorder() <AVAudioPlayerDelegate, AVAudioRecorderDelegate>
@property (nonatomic) BOOL isRecordingInProgress;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) NSTimer *updateTimer;
@property (strong, nonatomic) NSMutableArray *history;
@property (nonatomic) double speakingBeginTime;
@property (strong, nonatomic) NSURL *temporaryAudioURL;
@end

@implementation PHOREchoRecorder
@synthesize microphoneLevel = _microphoneLevel;
@synthesize isRecordingInProgress = _isRecordingInProgress;
@synthesize audioPlayer = _audioPlayer;
@synthesize audioRecorder = _audioRecorder;
@synthesize updateTimer = _updateTimer;
@synthesize history = _history;
@synthesize speakingBeginTime = _speakingBeginTime;
@synthesize temporaryAudioURL = _temporaryAudioURL;
@synthesize pan = _pan;
@synthesize duration = _duration;
@synthesize delegate = _delegate;
@synthesize audioWasModified = _audioWasModified;

#define RECORDING_TIMEOUT 5.0
#define RECORDING_INTERVAL 0.1
#define RECORDING_AVERAGING_WINDOW_SIZE 10
#define RECORDING_START_TRIGGER_DB 10
#define RECORDING_STOP_TRIGGER_DB 20
#define RECORDING_MINIMUM_TIME 0.5
#define RECORDING_SAMPLES_PER_SEC 22050

#if TARGET_IPHONE_SIMULATOR // audio playback tells you it is complete even though this much is actually still buffered
#define PLAYBACK_BUFFER_SIZE 0.2
#else
#define PLAYBACK_BUFFER_SIZE 0.1
#endif

- (AVAudioRecorder *)audioRecorder
{
    if (!_audioRecorder) {
        // USE kAudioFormatLinearPCM
        // SEE IMA4 vs M4A http://stackoverflow.com/questions/3509921/recorder-works-on-iphone-3gs-but-not-on-iphone-3g
        NSDictionary *recordSettings =
        @{AVSampleRateKey: [NSNumber numberWithFloat: RECORDING_SAMPLES_PER_SEC],
         AVFormatIDKey: @(kAudioFormatLinearPCM),
         AVNumberOfChannelsKey: @1,
         AVLinearPCMIsFloatKey: @NO,
         AVEncoderAudioQualityKey: @(AVAudioQualityMax)};
        
        NSError *error = nil;
        _audioRecorder = [[ AVAudioRecorder alloc] initWithURL:self.temporaryAudioURL settings:recordSettings error:&error];
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES;
        
        if ([_audioRecorder prepareToRecord] == NO){
            NSLog(@"Error: %@ %ld" , [error localizedDescription], (long)[error code]);
        }
    }
    return _audioRecorder;
}

- (NSURL *)temporaryAudioURL
{
    if (!_temporaryAudioURL) {
        NSString *file = [NSString stringWithFormat:@"recording%x.caf", arc4random()];
        NSURL *tmpDir = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
        _temporaryAudioURL = [tmpDir URLByAppendingPathComponent:file];
        NSLog(@"Opened recording file for writing: %@", _temporaryAudioURL);
    }
    return _temporaryAudioURL;
}

// DESIGNATED INITIALIZER
- (instancetype)init
{
    self = [super init];
    self.history = [NSMutableArray arrayWithCapacity:RECORDING_AVERAGING_WINDOW_SIZE];
    return self;
}

- (instancetype)initWithAudioDataAtURL:(NSURL *)url
{
    self = [self init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    while ([fileManager fileExistsAtPath:[self.temporaryAudioURL absoluteString]]) {
        self.temporaryAudioURL = nil;
    }

    NSError *error = nil;
    if (![[NSFileManager defaultManager] copyItemAtURL:url toURL:self.temporaryAudioURL error:&error])
        NSLog(@"%@", error);
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.temporaryAudioURL error:&error];
    self.duration = @(self.audioPlayer.duration); 
    return self;
}

- (void)record
{
    [self.audioPlayer stop];
    self.isRecordingInProgress = YES;
    if (self.audioRecorder.recording) return;
    self.microphoneLevel = @0.0f;
    self.speakingBeginTime = 0;
    self.duration = @0.0f;
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource:@"Ready to record" ofType:@"m4a"]];
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.audioPlayer.pan = 0;
    self.audioPlayer.delegate = self;
    [self.audioPlayer play];
}

- (void)actuallyRecord
{
    [self.audioRecorder recordForDuration:RECORDING_TIMEOUT];
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:RECORDING_INTERVAL
                                                        target:self 
                                                      selector:@selector(followUpOnRecording) 
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)followUpOnRecording
{    
    if (!self.isRecordingInProgress) return;
//NSLog(@"followUp: recording: %@ isrecording: %@", self.audioRecorder, self.audioRecorder.recording?@"YES":@"NO");
    if (!self.audioRecorder.recording) { // Timed out
        [self stopRecordingAndKeepResult:NO];
        
        NSURL *url = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource:@"Record failed" ofType:@"m4a"]];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        self.audioPlayer.pan = 0;
        [self.audioPlayer play];
        return;
    }

    [self.audioRecorder updateMeters];
    float peak = [self.audioRecorder peakPowerForChannel:0];
    float currentLevel = [self.audioRecorder averagePowerForChannel:0];
    self.microphoneLevel = @(currentLevel/80+1);
    
    if (peak-currentLevel > RECORDING_STOP_TRIGGER_DB && self.audioRecorder.currentTime > RECORDING_MINIMUM_TIME) {
        [self stopRecordingAndKeepResult:YES];
    }
    
    [self.history addObject:@(currentLevel)];
    if (self.history.count > RECORDING_AVERAGING_WINDOW_SIZE)
        [self.history removeObjectAtIndex:0];

    double runningTotal = 0.0;
    for (NSNumber *number in self.history) {
        runningTotal += [number doubleValue]; //TODO: USE LOG MATH
    }
    double movingAverage = runningTotal / [self.history count];
    
    if (!self.updateTimer.isValid) return;
    
    if (currentLevel-movingAverage > RECORDING_START_TRIGGER_DB && 
        self.audioRecorder.currentTime > RECORDING_INTERVAL*2 && 
        !self.speakingBeginTime) {
        self.speakingBeginTime = self.audioRecorder.currentTime - RECORDING_INTERVAL * 1.5;
        if (self.speakingBeginTime < 0)
            self.speakingBeginTime = 0;
    }
    
//    NSLog(@"levels: peak %f, current %f, avg %f, begin %f", peak, currentLevel, runningTotal, self.speakingBeginTime);
}

- (void)stopRecordingAndKeepResult:(BOOL)save
{
    [self.updateTimer invalidate];
    self.isRecordingInProgress = NO;
    if (save) {
        [self.audioRecorder pause];
        self.duration = [NSNumber numberWithFloat:self.audioRecorder.currentTime - self.speakingBeginTime];
        NSLog(@"Recording duration: %@", self.duration);
        self.audioWasModified = YES;
    }
    [self.audioRecorder stop];
    self.microphoneLevel = @0.0f;
    
    [self.delegate recording:self didFinishSuccessfully:save];
}

- (void)reset
{
    [self.updateTimer invalidate];
    self.isRecordingInProgress = NO;
    [self.audioRecorder stop];
    self.microphoneLevel = @0.0f;
    self.duration = nil;
    [self.delegate recording:self didFinishSuccessfully:NO];
}

- (void)playback
{
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.temporaryAudioURL error:nil];
    self.audioPlayer.currentTime = self.speakingBeginTime;
    self.audioPlayer.pan = [self.pan floatValue];
    [self.audioPlayer play];
}

- (NSURL *)getAudioDataURL
{
    // Prepare output 
    NSString *trimmedAudioFileBaseName = [NSString stringWithFormat:@"recordingConverted%x.caf", arc4random()];
    NSURL *tmpDir = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *trimmedAudioURL = [tmpDir URLByAppendingPathComponent:trimmedAudioFileBaseName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([trimmedAudioURL checkResourceIsReachableAndReturnError:nil]) {
        NSError *error;
        if ([fileManager removeItemAtURL:trimmedAudioURL error:&error] == NO) {
            NSLog(@"removeItemAtPath %@ error:%@", trimmedAudioURL, error);
        }
    }
    NSLog(@"Converting %@", self.temporaryAudioURL);
    
    AVAsset *avAsset = [AVAsset assetWithURL:self.temporaryAudioURL];
    
    // get the first audio track
    NSArray *tracks = [avAsset tracksWithMediaType:AVMediaTypeAudio];
    //if ([tracks count] == 0) return nil;
    AVAssetTrack *track = tracks[0];
    
    // create the export session
    // no need for a retain here, the session will be retained by the
    // completion handler since it is referenced there
    AVAssetExportSession *exportSession = [AVAssetExportSession
                                           exportSessionWithAsset:avAsset
                                           presetName:AVAssetExportPresetAppleM4A];
    //if (nil == exportSession) return nil;
    
    // create trim time range
    CMTime startTime = CMTimeMake(self.speakingBeginTime*RECORDING_SAMPLES_PER_SEC, RECORDING_SAMPLES_PER_SEC);
    CMTime stopTime = CMTimeMake((self.speakingBeginTime+[self.duration doubleValue])*RECORDING_SAMPLES_PER_SEC, RECORDING_SAMPLES_PER_SEC);
    CMTimeRange exportTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime);
    
    // create fade in time range
    CMTime startFadeInTime = startTime;
    CMTime endFadeInTime = CMTimeMake((self.speakingBeginTime+RECORDING_INTERVAL)*1.5*RECORDING_SAMPLES_PER_SEC, RECORDING_SAMPLES_PER_SEC);
    CMTimeRange fadeInTimeRange = CMTimeRangeFromTimeToTime(startFadeInTime,
                                                            endFadeInTime);
    
    // setup audio mix
    AVMutableAudioMix *exportAudioMix = [AVMutableAudioMix audioMix];
    AVMutableAudioMixInputParameters *exportAudioMixInputParameters =
    [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];
    
    [exportAudioMixInputParameters setVolumeRampFromStartVolume:0.0 toEndVolume:1.0
                                                      timeRange:fadeInTimeRange]; 
    exportAudioMix.inputParameters = @[exportAudioMixInputParameters]; 
    
    // configure export session  output with all our parameters
    exportSession.outputURL = trimmedAudioURL; // output path
    exportSession.outputFileType = AVFileTypeAppleM4A; // output file type
    exportSession.timeRange = exportTimeRange; // trim time range
    exportSession.audioMix = exportAudioMix; // fade in audio mix
    
    // MAKE THE EXPORT SYNCHRONOUS
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    //dispatch_release(semaphore);
    
    if (AVAssetExportSessionStatusCompleted == exportSession.status) {
        NSLog(@"AVAssetExportSessionStatusCompleted: %@", trimmedAudioURL);
        return trimmedAudioURL;
    } else if (AVAssetExportSessionStatusFailed == exportSession.status) {
        // a failure may happen because of an event out of your control
        // for example, an interruption like a phone call comming in
        // make sure and handle this case appropriately
        NSLog(@"AVAssetExportSessionStatusFailed %@", exportSession.error.localizedDescription);
    } else {
        NSLog(@"Export Session Status: %ld", (long)exportSession.status);
    }
    
    return nil;
}

- (void)dealloc
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:[self.temporaryAudioURL absoluteString]]) {
        //NSError *error;
        if ([fileManager removeItemAtPath:[self.temporaryAudioURL absoluteString] error:nil] == NO) {
        //    NSLog(@"removeItemAtPath %@ error:%@", [self.temporaryAudioURL absoluteString], error);
        }
    }
}

#pragma mark - AV Audio Player Delegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (self.isRecordingInProgress)
        [self performSelector:@selector(actuallyRecord) withObject:self afterDelay:PLAYBACK_BUFFER_SIZE]; // wait for buffer to clear
}


#pragma mark - AV Audio Recorder Delegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog(@"audioRecorderDidFinishRecording %@", recorder);
}

@end
