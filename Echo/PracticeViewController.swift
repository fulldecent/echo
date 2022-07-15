//
//  PracticeViewController.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import UIKit
import AVFoundation
import FDWaveformView
import FDSoundActivatedRecorder

fileprivate func makeItBounce(view: UIView) {
    let bounceAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
    bounceAnimation.values = [1.0, 1.2]
    bounceAnimation.duration = 0.15
    bounceAnimation.isRemovedOnCompletion = false
    bounceAnimation.repeatCount = 2
    bounceAnimation.autoreverses = true
    bounceAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
    view.layer.add(bounceAnimation, forKey: "bounce")
}

protocol PracticeViewControllerDelegate: AnyObject {
    func practiceViewControllerDidSkip(controller: PracticeViewController)
}

class PracticeViewController: UIViewController {

    enum WorkflowState {
        case Ready
        case DoAnimationAndSetup
        case ListenFirstTime
        case RecordFirstTime
        case ListenSecondTime
        case EchoFirstTime
        case ListenThirdTime
        case EchoSecondTime
        case DoAnimationAndBreakdown
    }
    
    // MARK - Model
    
    var word: Word? = nil {
        didSet {
            self.navigationItem.title = "🗣 " + word!.name
            for waveform in playbackWaveforms {
                waveform.removeFromSuperview()
            }
            playbackWaveforms.removeAll(keepingCapacity: false)
            for audio in word!.audios {
                let waveform = FDWaveformView()
                waveform.isHidden = true
                waveform.layer.zPosition = -5
                waveform.isUserInteractionEnabled = false
                waveform.doesAllowScroll = false
                waveform.doesAllowStretch = false
                waveform.doesAllowScrubbing = false
                waveform.wavesColor = .lightGray
                waveform.progressColor = .darkGray
                waveform.audioURL = audio.fileURL()
                waveform.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(waveform)
                view.addConstraint(NSLayoutConstraint(item: speakerButton!, attribute: .top, relatedBy: .equal, toItem: waveform, attribute: .top, multiplier: 1, constant: 0))
                view.addConstraint(NSLayoutConstraint(item: speakerButton!, attribute: .bottom, relatedBy: .equal, toItem: waveform, attribute: .bottom, multiplier: 1, constant: 0))
                view.addConstraint(NSLayoutConstraint(item: speakerButton!, attribute: .left, relatedBy: .equal, toItem: waveform, attribute: .left, multiplier: 1, constant: 0))
                view.addConstraint(NSLayoutConstraint(item: speakerButton!, attribute: .right, relatedBy: .equal, toItem: waveform, attribute: .right, multiplier: 1, constant: 0))
                playbackWaveforms.append(waveform)
            }
        }
    }
    
    var audioPlayer: AVAudioPlayer? = nil
    
    var playbackWaveforms: [FDWaveformView] = []
    
    lazy var soundActivatedRecorder: FDSoundActivatedRecorder = {
        let retval = FDSoundActivatedRecorder()
        retval.intervalSeconds = 0.04
        retval.delegate = self
        return retval
    }()
    
    var recordedAudio: AVAudioPlayer? = nil
    
    weak var delegate: PracticeViewControllerDelegate? = nil

    // MARK - Actions

    @IBAction func playPressed(_ sender: Any) {
        guard let word = word,
            word.audios.count > 0
        else {
            navigationController!.popViewController(animated: true)
            return
        }
        if sender is UIView {
            makeItBounce(view: sender as! UIView)
        }
        
        //self.recorder!.stopRecordingAndKeepResult(false)
        let index = Int(arc4random_uniform(UInt32(word.audios.count)))
        let chosenAudio = word.audios[index]
        guard chosenAudio.fileExistsOnDisk() else {
            return
        }
        let url = chosenAudio.fileURL()
        self.audioPlayer = try? AVAudioPlayer(contentsOf: url)
        guard self.audioPlayer != nil else {
            return
        }
        self.audioPlayer?.pan = -0.5
        self.audioPlayer?.play()
        
        // Workaround because AVURLAsset needs files with file extensions
        // http://stackoverflow.com/questions/9290972/is-it-possible-to-make-avurlasset-work-without-a-file-extension
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .allDomainsMask).last!
        let tmpURL = documentsURL.appendingPathComponent("tmp.caf")
        _ = try? fileManager.removeItem(at: tmpURL)
        _ = try? fileManager.linkItem(at: url, to: tmpURL)

        for waveform in playbackWaveforms {
            waveform.isHidden = true
        }
        let chosenWaveform = playbackWaveforms[index]
        chosenWaveform.highlightedSamples = nil
        chosenWaveform.isHidden = false
        UIView.animate(withDuration: (audioPlayer?.duration)!, delay: 0, options: .curveLinear, animations: {() -> Void in
            chosenWaveform.highlightedSamples = 0 ..< chosenWaveform.totalSamples
        }, completion: {(done: Bool) -> Void in
            chosenWaveform.isHidden = true
        })
    }
    
    @IBAction func microphonePressed(_ sender: Any) {
        guard AVAudioSession.sharedInstance().recordPermission == AVAudioSession.RecordPermission.granted else {
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                Achievement.enableMicrophone.setAccomplished()
            }
            return
        }
        
        if let player = recordedAudio {
            player.pan = 0.5
            player.play()
            return
        }
        
        let beepURL = Bundle.main.url(forResource: "Ready to record", withExtension: "m4a")!
        self.audioPlayer = try! AVAudioPlayer(contentsOf: beepURL)
        self.audioPlayer!.pan = 0
        self.audioPlayer!.delegate = self
        self.audioPlayer!.play()
        self.microphoneButton.layer.shadowOpacity = 1.0
        self.microphoneButton.layer.shadowRadius = 5
        self.microphoneButton.layer.shadowColor = UIColor.red.cgColor
        self.microphoneButton.layer.shadowOffset = CGSize.zero
        soundActivatedRecorder.startListening()
    }
    @IBAction func checkPressed(_ sender: Any) {
    }
    @IBAction func autoPressed(_ sender: Any) {
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        delegate?.practiceViewControllerDidSkip(controller: self)
    }
    
    @IBAction func longPressed(_ sender: Any) {
        soundActivatedRecorder.abort()
        recordedAudio = nil
        microphoneButton.setTitle("🎤", for: .normal)
        self.microphoneButton.layer.shadowOpacity = 0
    }
    
    // MARK - Outlets
    @IBOutlet weak var speakerButton: UIButton!
    @IBOutlet weak var microphoneButton: UIButton!
    
    
    // MARK - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord)
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
        } catch {
            NSLog("error doing outputaudioportoverride: \(error)")
        }
        
        self.view.subviews.filter { $0.isKind(of: UIToolbar.self) }.forEach {$0.isHidden=true}
        //TEMP: HIDE THESE
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        soundActivatedRecorder.abort()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


extension PracticeViewController: FDSoundActivatedRecorderDelegate {
    /// A recording was successfully captured
    func soundActivatedRecorderDidStartRecording(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async(execute: {
            NSLog("STARTED RECORDING")
            self.microphoneButton.layer.shadowOpacity = 1.0
            self.microphoneButton.layer.shadowRadius = 30
            self.microphoneButton.layer.shadowColor = UIColor.red.cgColor
            self.microphoneButton.layer.shadowOffset = CGSize.zero
        })
    }
    
    func soundActivatedRecorderDidFinishRecording(_ recorder: FDSoundActivatedRecorder, andSaved file: URL) {
        DispatchQueue.main.async(execute: {
            NSLog("DONE RECORDING")
            self.microphoneButton.layer.shadowRadius = 10
            self.microphoneButton.layer.shadowColor = UIColor.blue.cgColor
            self.microphoneButton.setTitle("🔈", for: .normal)
            self.recordedAudio = try! AVAudioPlayer(contentsOf: file)
            self.recordedAudio?.delegate = self
        })
    }
    
    func soundActivatedRecorderDidAbort(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async(execute: {
            NSLog("STOPPED RECORDING")
            self.microphoneButton.layer.shadowOpacity = 0
            let beepURL = Bundle.main.url(forResource: "Record failed", withExtension: "m4a")!
            self.audioPlayer = try! AVAudioPlayer(contentsOf: beepURL)
            self.audioPlayer!.pan = 0
            self.audioPlayer!.delegate = self
            self.audioPlayer!.play()
        })
    }
    
    func soundActivatedRecorderDidTimeOut(_ recorder: FDSoundActivatedRecorder) {
        DispatchQueue.main.async(execute: {
            NSLog("STOPPED RECORDING")
            self.microphoneButton.layer.shadowOpacity = 0
            let beepURL = Bundle.main.url(forResource: "Record failed", withExtension: "m4a")!
            self.audioPlayer = try! AVAudioPlayer(contentsOf: beepURL)
            self.audioPlayer!.pan = 0
            self.audioPlayer!.delegate = self
            self.audioPlayer!.play()
        })
    }
}

extension PracticeViewController: AVAudioPlayerDelegate {
    
}
