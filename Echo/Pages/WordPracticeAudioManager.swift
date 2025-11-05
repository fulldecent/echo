//
//  WordPracticePage.swift
//  Echo
//
//  Created by William Entriken on 2025-10-21.
//

import SwiftUI
import AVFoundation
import AVFAudio
import Combine
import Foundation

/**
 * This only needs to work on iOS 26+ and macOS 26+
 */
final class WordPracticeAudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // Prompt file names (must be present in the app bundle)
    static let startPromptName = "Recording" // Recording.wav
    static let successPromptName = "Success" // Success.wav
    static let failurePromptName = "Failed"  // Failed.wav
    static let promptExtension = "wav"
    
    enum State: Equatable {
        case idle
        case promptingStart
        case recordingListening        // waiting for speech
        case recordingActive           // speech detected; writing
        case promptingStopSuccess
        case promptingStopFailure
        case playingReference
        case playingUser
        case error(String)
    }
    
    enum MicPermission {
        case undetermined, granted, denied
    }
    
    // Public observable state
    @Published private(set) var state: State = .idle
    @Published private(set) var permission: MicPermission = .undetermined
    @Published private(set) var playbackProgress: Double = 0
    @Published private(set) var userRecordingURL: URL?
    
    var isRecording: Bool {
        state == .recordingListening || state == .recordingActive
    }
    var isPlaying: Bool {
        state == .playingReference || state == .playingUser
    }
    
    // VAD parameters
    var noSpeechTimeout: TimeInterval = 2.0          // fail if no speech within this time
    var maxRecordingDuration: TimeInterval = 5.0     // cap recording duration
    var silenceDurationToEnd: TimeInterval = 0.35    // end shortly after user finishes
    var vadThresholdDBFS: Float = -35.0              // lower = more sensitive
    // Playback stereo pan: reference slightly right, user slightly left
    var referencePan: Float = 0.2
    var userPan: Float = -0.2
    var preRollDuration: TimeInterval = 0.3          // include audio just before speech detection
    
    // Internals
    private var engine: AVAudioEngine?
    private var inputFormat: AVAudioFormat?
    private var audioFile: AVAudioFile?
    private var currentFileURL: URL?
    private var isFinishing = false
    
    private var speechStarted = false
    private var lastSpeechDate: Date?
    
    private var player: AVAudioPlayer?
    private var progressTimer: Timer?
    
    private var noSpeechTimer: DispatchSourceTimer?
    private var maxDurationTimer: DispatchSourceTimer?
    private var promptCompletion: (() -> Void)?
    // Pre-roll ring buffer (audio before VAD triggers)
    private var preRollBuffer: AVAudioPCMBuffer?
    private var preRollCapacityFrames: Int = 0
    private var preRollWritePos: Int = 0
    private var preRollCount: Int = 0
    // When speech first starts, we flush pre-roll which already includes the current buffer.
    // Skip writing the first buffer after start to avoid duplication.
    private var skipFirstWriteAfterStart = false
    #if os(iOS)
    private var shouldDeactivateSessionWhenIdle = false
    #endif
    
    // MARK: - Permissions (modern API only)
    
    func requestPermission() {
        #if os(iOS)
        if #available(iOS 17, *) {
            let app = AVAudioApplication.shared
            switch app.recordPermission {
            case .granted:
                permission = .granted
            case .denied:
                permission = .denied
            case .undetermined:
                permission = .undetermined
                AVAudioApplication.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.permission = granted ? .granted : .denied
                    }
                }
            @unknown default:
                permission = .denied
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                permission = .granted
            case .denied:
                permission = .denied
            case .undetermined:
                permission = .undetermined
                session.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.permission = granted ? .granted : .denied
                    }
                }
            @unknown default:
                permission = .denied
            }
        }
        #elseif os(macOS)
        let app = AVAudioApplication.shared
        let perm = app.recordPermission
        switch perm {
        case .granted:
            permission = .granted
        case .denied:
            permission = .denied
        case .undetermined:
            permission = .undetermined
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permission = granted ? .granted : .denied
                }
            }
        @unknown default:
            permission = .denied
        }
        #endif
    }
    
    // MARK: - Public Control
    
    func beginRecordingFlow() {
        guard !isRecording, !isPlaying else { return }
        guard permission == .granted else {
            requestPermission()
            return
        }
        #if os(iOS)
        configureSessionForPlayAndRecord()
        #endif
        
        state = .promptingStart
        playPrompt(named: Self.startPromptName) { [weak self] in
            self?.startEngineAndListen()
        }
    }
    
    func playReference(url: URL) {
        guard !isRecording else { return }
        playURL(url, playingState: .playingReference)
    }
    
    func playUser() {
        guard let url = userRecordingURL, !isRecording else { return }
        playURL(url, playingState: .playingUser)
    }
    
    func resetRecording() {
        cancelAll()
        if let url = userRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        userRecordingURL = nil
        state = .idle
    }
    
    func cancelAll() {
        // Stop playback
        player?.stop()
        player = nil
        progressTimer?.invalidate()
        progressTimer = nil
        
        // Stop recording
        stopEngineIfRunning()
        audioFile = nil
        currentFileURL = nil
        
        // Cancel timers
        noSpeechTimer?.cancel()
        noSpeechTimer = nil
        maxDurationTimer?.cancel()
        maxDurationTimer = nil
        
        if case .error = state {
            // keep error visible
        } else {
            state = .idle
        }
    }
    
    // MARK: - Recording (AVAudioEngine + VAD)
    
    private func startEngineAndListen() {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".caf")
        currentFileURL = nil
        isFinishing = false
        
        let engine = AVAudioEngine()
        self.engine = engine
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        self.inputFormat = format
        // Setup pre-roll ring buffer based on desired duration
        do {
            let sampleRate = format.sampleRate
            let channels = Int(format.channelCount)
            let frames = Int(ceil(preRollDuration * sampleRate))
            preRollCapacityFrames = max(frames, 1)
            preRollWritePos = 0
            preRollCount = 0
            preRollBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(preRollCapacityFrames))
            preRollBuffer?.frameLength = AVAudioFrameCount(preRollCapacityFrames)
            // Zero-initialize buffer per channel
            if let ptr = preRollBuffer?.floatChannelData {
                for c in 0..<channels {
                    ptr[c].initialize(repeating: 0, count: preRollCapacityFrames)
                }
            }
        }
        
        speechStarted = false
        lastSpeechDate = nil
        
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            let db = self.bufferRMSdBFS(buffer)
            let now = Date()
            // Accumulate into pre-roll ring buffer until speech starts
            self.appendToPreRoll(buffer)
            
            if db > self.vadThresholdDBFS {
                if !self.speechStarted {
                    self.speechStarted = true
                    if !self.openFileForWriting(at: fileURL, format: format) {
                        DispatchQueue.main.async {
                            self.finishRecording(success: false, fileURL: nil, error: "Unable to open file for writing.")
                        }
                        return
                    }
                    // Write pre-roll content first so the very beginning is captured
                    if let file = self.audioFile {
                        self.flushPreRoll(to: file)
                    }
                    // Avoid writing this detection buffer again
                    self.skipFirstWriteAfterStart = true
                    self.scheduleMaxDurationTimer()
                    DispatchQueue.main.async { self.state = .recordingActive }
                }
                self.lastSpeechDate = now
            }
            
            // Write only after speech started
            if self.speechStarted, let file = self.audioFile {
                if self.skipFirstWriteAfterStart {
                    // Skip writing this buffer; subsequent buffers will be written normally
                    self.skipFirstWriteAfterStart = false
                } else {
                    do {
                        try file.write(from: buffer)
                    } catch {
                        DispatchQueue.main.async {
                            self.finishRecording(success: false, fileURL: nil, error: "Write error: \(error.localizedDescription)")
                        }
                        return
                    }
                }
            }
            
            // End when trailing silence observed after speech
            if self.speechStarted, let last = self.lastSpeechDate {
                if now.timeIntervalSince(last) >= self.silenceDurationToEnd {
                    DispatchQueue.main.async { self.finishRecording(success: true, fileURL: self.currentFileURL, error: nil) }
                }
            }
        }
        
        do {
            engine.prepare()
            try engine.start()
        } catch {
            state = .error("Audio engine failed to start: \(error.localizedDescription)")
            stopEngineIfRunning()
            return
        }
        
        state = .recordingListening
        scheduleNoSpeechTimer()
    }
    
    private func finishRecording(success: Bool, fileURL: URL?, error: String?) {
        if isFinishing { return }
        isFinishing = true
        stopEngineIfRunning()
        audioFile = nil
        
        noSpeechTimer?.cancel()
        noSpeechTimer = nil
        maxDurationTimer?.cancel()
        maxDurationTimer = nil
        
        if success, let url = fileURL {
            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0
            if size > 0 {
                userRecordingURL = url
                state = .promptingStopSuccess
                playPrompt(named: Self.successPromptName) { [weak self] in
                    guard let self = self else { return }
                    self.state = .idle
                    #if os(iOS)
                    if self.shouldDeactivateSessionWhenIdle {
                        self.deactivateSession()
                        self.shouldDeactivateSessionWhenIdle = false
                    }
                    #endif
                }
                return
            } else {
                try? FileManager.default.removeItem(at: url)
            }
        }
        
        // Failure
        state = .promptingStopFailure
        playPrompt(named: Self.failurePromptName) { [weak self] in
            guard let self = self else { return }
            self.state = .idle
            #if os(iOS)
            if self.shouldDeactivateSessionWhenIdle {
                self.deactivateSession()
                self.shouldDeactivateSessionWhenIdle = false
            }
            #endif
        }
        if let error { print("Recording failure:", error) }
        #if os(iOS)
        // Defer deactivation until after any prompt playback completes
        shouldDeactivateSessionWhenIdle = true
        #endif
    }
    
    private func stopEngineIfRunning() {
        guard let engine = engine else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil
    }
    
    private func scheduleNoSpeechTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + noSpeechTimeout)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            if !self.speechStarted && !self.isFinishing {
                self.finishRecording(success: false, fileURL: nil, error: "No speech detected within timeout.")
            }
        }
        timer.resume()
        noSpeechTimer = timer
    }
    
    private func scheduleMaxDurationTimer() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + maxRecordingDuration)
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            if self.speechStarted && !self.isFinishing {
                self.finishRecording(success: true, fileURL: self.currentFileURL, error: nil)
            } else {
                self.finishRecording(success: false, fileURL: nil, error: "Timed out without speech.")
            }
        }
        timer.resume()
        maxDurationTimer = timer
    }
    
    // MARK: - Playback
    
    private func playURL(_ url: URL, playingState: State) {
        // If the same URL is already playing, restart from beginning
        if let current = player, current.isPlaying, current.url == url {
            current.stop()
            current.currentTime = 0
            // Apply desired pan on restart
            switch playingState {
            case .playingReference: current.pan = referencePan
            case .playingUser: current.pan = userPan
            default: break
            }
            current.prepareToPlay()
            state = playingState
            current.play()
            startProgressTimer()
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            guard p.duration > 0 else { return }
            player?.stop()
            progressTimer?.invalidate()
            player = p
            p.delegate = self
            p.prepareToPlay()
            // Apply desired pan
            switch playingState {
            case .playingReference: p.pan = referencePan
            case .playingUser: p.pan = userPan
            default: break
            }
            state = playingState
            p.play()
            startProgressTimer()
        } catch {
            state = .error("Playback failed: \(error.localizedDescription)")
            player = nil
        }
    }
    
    private func playPrompt(named name: String, completion: (() -> Void)? = nil) {
        guard let url = Bundle.main.url(forResource: name, withExtension: Self.promptExtension) else {
            completion?() // Missing asset; continue flow
            return
        }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            player?.stop()
            progressTimer?.invalidate()
            player = p
            p.delegate = self
            p.prepareToPlay()
            promptCompletion = completion
            p.play()
        } catch {
            completion?()
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch self.state {
            case .playingReference, .playingUser:
                self.state = .idle
            case .promptingStart, .promptingStopSuccess, .promptingStopFailure:
                let completion = self.promptCompletion
                self.promptCompletion = nil
                completion?()
            default:
                break
            }
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            self.playbackProgress = 0
            #if os(iOS)
            if self.shouldDeactivateSessionWhenIdle, !self.isPlaying {
                self.deactivateSession()
                self.shouldDeactivateSessionWhenIdle = false
            }
            #endif
        }
    }
    
    private func startProgressTimer() {
        playbackProgress = 0
        progressTimer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let p = self.player, p.isPlaying else {
                self?.progressTimer?.invalidate()
                self?.progressTimer = nil
                return
            }
            self.playbackProgress = p.duration > 0 ? p.currentTime / p.duration : 0
        }
        RunLoop.main.add(t, forMode: .common)
        progressTimer = t
    }
    
    // MARK: - Utilities
    
    private func bufferRMSdBFS(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let ch = buffer.floatChannelData?.pointee else { return -120.0 }
        let n = Int(buffer.frameLength)
        if n == 0 { return -120.0 }
        var sum: Float = 0
        var i = 0
        while i < n {
            let v = ch[i]
            sum += v * v
            i += 1
        }
        let mean = sum / Float(max(n, 1))
        let rms = sqrt(mean)
        let db = 20.0 * log10f(max(rms, 1e-7))
        return db
    }
    
    // MARK: - Pre-roll handling

    private func appendToPreRoll(_ buffer: AVAudioPCMBuffer) {
        guard let pre = preRollBuffer, let inPtr = buffer.floatChannelData, let outPtr = pre.floatChannelData else { return }
        let channels = Int(buffer.format.channelCount)
        let inFrames = Int(buffer.frameLength)
        if inFrames == 0 || preRollCapacityFrames <= 0 { return }
        var remaining = inFrames
        var readPos = 0
        while remaining > 0 {
            let writable = min(remaining, preRollCapacityFrames - preRollWritePos)
            for c in 0..<channels {
                let src = inPtr[c].advanced(by: readPos)
                let dst = outPtr[c].advanced(by: preRollWritePos)
                dst.update(from: src, count: writable)
            }
            preRollWritePos = (preRollWritePos + writable) % preRollCapacityFrames
            preRollCount = min(preRollCount + writable, preRollCapacityFrames)
            remaining -= writable
            readPos += writable
        }
    }

    private func flushPreRoll(to file: AVAudioFile) {
        guard let pre = preRollBuffer else { return }
        let channels = Int(pre.format.channelCount)
        guard let srcPtr = pre.floatChannelData else { return }
        let framesToWrite = preRollCount
        if framesToWrite <= 0 { return }
        // Create a temp buffer to linearize ring buffer content in chronological order
        guard let out = AVAudioPCMBuffer(pcmFormat: pre.format, frameCapacity: AVAudioFrameCount(framesToWrite)) else { return }
        out.frameLength = AVAudioFrameCount(framesToWrite)
        let outPtr = out.floatChannelData!
        let start = (preRollWritePos - framesToWrite + preRollCapacityFrames) % preRollCapacityFrames
        let firstChunk = min(framesToWrite, preRollCapacityFrames - start)
        let secondChunk = framesToWrite - firstChunk
        for c in 0..<channels {
            // first chunk
            outPtr[c].update(from: srcPtr[c].advanced(by: start), count: firstChunk)
            // second chunk (wrap)
            if secondChunk > 0 {
                outPtr[c].advanced(by: firstChunk).update(from: srcPtr[c], count: secondChunk)
            }
        }
        do {
            try file.write(from: out)
        } catch {
            // If pre-roll write fails, continue without it
        }
        // Reset pre-roll after flush
        preRollCount = 0
        preRollWritePos = 0
    }

    private func openFileForWriting(at url: URL, format: AVAudioFormat) -> Bool {
        do {
            audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
            currentFileURL = url
            return true
        } catch {
            return false
        }
    }
    
    #if os(iOS)
    private func configureSessionForPlayAndRecord() {
        let s = AVAudioSession.sharedInstance()
        do {
            try s.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP, .duckOthers])
            try s.setActive(true)
        } catch {
            // Non-fatal; engine may still run
        }
    }
    
    private func deactivateSession() {
        let s = AVAudioSession.sharedInstance()
        do {
            try s.setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            // Ignore deactivation failure
        }
    }
    #endif
}
