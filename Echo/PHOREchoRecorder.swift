//
//  PHOREchoRecorder.swift
//  Echo
//
//  Created by William Entriken on 1/15/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import AVFoundation


public protocol PHOREchoRecorderDelegate: class {
    func recording(recorder: PHOREchoRecorder, didFinishSuccessfully success: Bool)
}

public class PHOREchoRecorder: NSObject {
    private let RECORDING_TIMEOUT = 5.0
    private let RECORDING_INTERVAL = 0.1
    private let RECORDING_AVERAGING_WINDOW_SIZE = 10
    private let RECORDING_SAMPLES_PER_SEC: Int32 = 22050
    private let RECORDING_START_TRIGGER_DB = 10.0
    private let RECORDING_STOP_TRIGGER_DB = 20.0
    private let RECORDING_MINIMUM_TIME = 0.5
    private let PLAYBACK_BUFFER_SIZE = 0.1 // audio playback tells you it is complete even though this much is actually still buffered
    //TODO: on the simulator buffer should be 0.2
    
    public var microphoneLevel: Double = 0.0 // roughly 0.0 to 1.0
    public var duration: Double = 0.0
    public var pan: Float = 0.0 // range: -1.0 (left) to 1.0 (right)
    public var audioWasModified = false
    public weak var delegate: PHOREchoRecorderDelegate? = nil
    
    private var temporaryAudioURL: NSURL = {
        let file: String = "recording\(arc4random()).caf"
        let tmpDir: NSURL = NSURL.fileURLWithPath(NSTemporaryDirectory(), isDirectory: true)
        return tmpDir.URLByAppendingPathComponent(file)
    }()
    private var isRecordingInProgress = false
    private var audioPlayer: AVAudioPlayer? = nil
    private lazy var audioRecorder: AVAudioRecorder? = {
        // SEE IMA4 vs M4A http://stackoverflow.com/questions/3509921/recorder-works-on-iphone-3gs-but-not-on-iphone-3g
        let recordSettings = [
            AVFormatIDKey: NSNumber(unsignedInt:kAudioFormatLinearPCM),
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey : 22050,
            AVLinearPCMIsFloatKey : false
        ]
        do {
            let recorder = try AVAudioRecorder(URL: self.temporaryAudioURL, settings: recordSettings)
            recorder.delegate = self
            recorder.meteringEnabled = true
            recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
            return recorder
        } catch {
            print(error)
        }
        return nil
    }()
    private var updateTimer: NSTimer? = nil
    private var history = [Double]()
    private var speakingBeginTime: NSTimeInterval? = nil
    
    public override init() {
        super.init()
    }
    
    public convenience init(audioDataAtURL url: NSURL) {
        self.init()
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        _ = try? fileManager.removeItemAtURL(self.temporaryAudioURL)
        try! fileManager.copyItemAtURL(audioDataURL()!, toURL: self.temporaryAudioURL)
        if let audioPlayer = self.audioPlayer {
            self.duration = audioPlayer.duration
        }
    }
    
    public func record() {
        guard !(self.audioRecorder?.recording == true) else {
            return
        }
        self.isRecordingInProgress = true
        self.audioPlayer?.stop()
        self.microphoneLevel = 0.0
        self.speakingBeginTime = 0
        self.duration = 0.0
        let beepURL = NSBundle.mainBundle().URLForResource("Ready to record", withExtension: "m4a")!
        self.audioPlayer = try! AVAudioPlayer(contentsOfURL: beepURL)
        self.audioPlayer!.pan = 0
        self.audioPlayer!.delegate = self
        self.audioPlayer!.play()
    }
    
    private func actuallyRecord() {
        self.audioRecorder?.recordForDuration(RECORDING_TIMEOUT)
        self.updateTimer = NSTimer(timeInterval: self.RECORDING_INTERVAL, target: self, selector: #selector(PHOREchoRecorder.followUpOnRecording), userInfo: nil, repeats: true)
    }
    
    public func followUpOnRecording() {
        //NSLog(@"followUp: recording: %@ isrecording: %@", self.audioRecorder, self.audioRecorder.recording?@"YES":@"NO");
        guard self.isRecordingInProgress else {
            return
        }
        guard self.audioRecorder?.recording == true else {
            // Timed out
            self.stopRecordingAndKeepResult(false)
            let url = NSBundle.mainBundle().URLForResource("Record failed", withExtension: "m4a")!
            self.audioPlayer = try! AVAudioPlayer(contentsOfURL: url)
            self.audioPlayer!.pan = 0
            self.audioPlayer!.play()
            return
        }
        self.audioRecorder!.updateMeters()
        let peak = Double(self.audioRecorder!.peakPowerForChannel(0))
        let currentLevel = Double(self.audioRecorder!.peakPowerForChannel(0))
        self.microphoneLevel = currentLevel / 80.0 + 1
        if peak - currentLevel > RECORDING_STOP_TRIGGER_DB && self.audioRecorder!.currentTime > RECORDING_MINIMUM_TIME {
            self.stopRecordingAndKeepResult(true)
        }
        self.history.append(currentLevel)
        if self.history.count > RECORDING_AVERAGING_WINDOW_SIZE {
            self.history.removeAtIndex(0)
        }
        var runningTotal: Double = 0.0 // this can be more efficient! only need to add new and subtract oldest value
        for number in self.history {
            runningTotal += number
        }
        let movingAverage = runningTotal / Double(self.history.count)
        guard self.updateTimer?.valid == true else { // NOTE: the preceding lines (get mic level) are slow and synchronous!
            return
        }
        guard self.speakingBeginTime > 0 else {
            return
        }
        if currentLevel - movingAverage > RECORDING_START_TRIGGER_DB && self.audioRecorder!.currentTime > RECORDING_INTERVAL * 2 {
            self.speakingBeginTime = self.audioRecorder!.currentTime - RECORDING_INTERVAL * 1.5
            if self.speakingBeginTime < 0 {
                self.speakingBeginTime = 0
            }
        }
    }
    
    public func stopRecordingAndKeepResult(save: Bool) {
        self.updateTimer?.invalidate()
        self.isRecordingInProgress = false
        if save {
            self.audioRecorder!.pause()
            self.duration = self.audioRecorder!.currentTime - self.speakingBeginTime!
            NSLog("Recording duration: %@", self.duration)
            self.audioWasModified = true
        }
        self.audioRecorder!.stop()
        self.microphoneLevel = 0.0
        self.delegate?.recording(self, didFinishSuccessfully: save)
    }
    
    public func playback() {
        self.audioPlayer = try! AVAudioPlayer(contentsOfURL: self.temporaryAudioURL)
        self.audioPlayer!.currentTime = self.speakingBeginTime!
        self.audioPlayer!.pan = self.pan
        self.audioPlayer!.play()
    }
    
    public func reset() {
        self.updateTimer?.invalidate()
        self.isRecordingInProgress = false
        self.audioRecorder!.stop()
        self.microphoneLevel = 0.0
//        self.duration = nil
        self.duration = 0
        self.delegate?.recording(self, didFinishSuccessfully: false)
    }
    
    //TODO: this code needs to be prettier
    public func audioDataURL() -> NSURL? {
        // Prepare output
        let trimmedAudioFileBaseName: String = "recordingConverted\(arc4random()).caf"
        let tmpDir: NSURL = NSURL.fileURLWithPath(NSTemporaryDirectory(), isDirectory: true)
        let trimmedAudioURL: NSURL = tmpDir.URLByAppendingPathComponent(trimmedAudioFileBaseName)
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        if trimmedAudioURL.checkResourceIsReachableAndReturnError(nil) {
            try! fileManager.removeItemAtURL(trimmedAudioURL)
        }
        NSLog("Converting %@", self.temporaryAudioURL)
        let avAsset: AVAsset = AVAsset(URL: self.temporaryAudioURL)
        // get the first audio track
        let tracks: [AVAssetTrack] = avAsset.tracksWithMediaType(AVMediaTypeAudio)
        //if ([tracks count] == 0) return nil;
        let track: AVAssetTrack = tracks[0]
        
        // create the export session
        // no need for a retain here, the session will be retained by the
        // completion handler since it is referenced there
        let exportSession: AVAssetExportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetAppleM4A)!
        //if (nil == exportSession) return nil;
        // create trim time range
        let startTime: CMTime = CMTimeMake(Int64(self.speakingBeginTime! * Double(RECORDING_SAMPLES_PER_SEC)), RECORDING_SAMPLES_PER_SEC)
        let stopTime: CMTime = CMTimeMake(Int64((self.speakingBeginTime! + self.duration) * Double(RECORDING_SAMPLES_PER_SEC)), RECORDING_SAMPLES_PER_SEC)
        let exportTimeRange: CMTimeRange = CMTimeRangeFromTimeToTime(startTime, stopTime)
        // create fade in time range
        let startFadeInTime: CMTime = startTime
        let endFadeInTime: CMTime = CMTimeMake(Int64((self.speakingBeginTime! + RECORDING_INTERVAL) * 1.5 * Double(RECORDING_SAMPLES_PER_SEC)), RECORDING_SAMPLES_PER_SEC)
        let fadeInTimeRange: CMTimeRange = CMTimeRangeFromTimeToTime(startFadeInTime, endFadeInTime)
        // setup audio mix
        let exportAudioMix: AVMutableAudioMix = AVMutableAudioMix()
        let exportAudioMixInputParameters: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters(track: track)
        exportAudioMixInputParameters.setVolumeRampFromStartVolume(0.0, toEndVolume: 1.0, timeRange: fadeInTimeRange)
        exportAudioMix.inputParameters = [exportAudioMixInputParameters] // configure export session  output with all our parameters
        exportSession.outputURL = trimmedAudioURL // output path
        exportSession.outputFileType = AVFileTypeAppleM4A // output file type
        exportSession.timeRange = exportTimeRange // trim time range
        exportSession.audioMix = exportAudioMix // fade in audio mix
        
        // MAKE THE EXPORT SYNCHRONOUS
        let semaphore: dispatch_semaphore_t = dispatch_semaphore_create(0)
        exportSession.exportAsynchronouslyWithCompletionHandler({() -> Void in
            dispatch_semaphore_signal(semaphore)
        })
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
        //dispatch_release(semaphore);
        
        switch exportSession.status {
        case .Completed:
            NSLog("AVAssetExportSessionStatusCompleted: %@", trimmedAudioURL)
            return trimmedAudioURL
        case .Failed:
            // a failure may happen because of an event out of your control
            // for example, an interruption like a phone call comming in
            // make sure and handle this case appropriately
            print("AVAssetExportSessionStatusFailed \(exportSession.error!.localizedDescription)")
            return nil
        default:
            print("AVAssetExportSessionStatusFailed \(exportSession.status)")
            return nil
        }
    }
}

extension PHOREchoRecorder: AVAudioRecorderDelegate {
    
}

extension PHOREchoRecorder: AVAudioPlayerDelegate {
    
}