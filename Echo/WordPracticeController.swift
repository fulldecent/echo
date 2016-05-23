//
//  WordPracticeController.swift
//  Echo
//
//  Created by William Entriken on 1/11/16.
//
//

import UIKit
import AVFoundation
import Firebase
import FDWaveformView

//TODO: what about checkmarks??!

protocol WordPracticeDataSource: class {
    func currentWordForWordPractice(wordPractice: WordPracticeController) -> Word
    func wordCheckedStateForWordPractice(wordPractice: WordPracticeController) -> Bool
}

protocol WordPracticeDelegate: class {
    func skipToNextWordForWordPractice(wordPractice: WordPracticeController)
    func currentWordCanBeCheckedForWordPractice(wordPractice: WordPracticeController) -> Bool
    func wordPracticeShouldShowNextButton(wordPractice: WordPracticeController) -> Bool
    func wordPractice(wordPractice: WordPracticeController, setWordCheckedState state: Bool)
}

class WordPracticeController: UIViewController {
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
    
    @IBOutlet var wordTitle: UILabel!
    @IBOutlet var wordDetail: UITextView!
    @IBOutlet var trainingSpeakerButton: UIButton!
    @IBOutlet var trainingWaveform: FDWaveformView!
    @IBOutlet var recordButton: UIButton!
    @IBOutlet var recordGuage: FDBarGauge!
    @IBOutlet var playbackButton: UIButton!
    @IBOutlet var checkbox: UIButton!
    @IBOutlet var playbackWaveform: FDWaveformView!
    weak var datasource: WordPracticeDataSource?
    weak var delegate: WordPracticeDelegate?
    var audioPlayer: AVAudioPlayer? = nil
    var recorder: PHOREchoRecorder? = nil
    var workflowState = WorkflowState.Ready
    var word: Word!
    let WORKFLOW_DELAY = 0.3
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == "microphoneLevel") {
            self.recordGuage.value = change?[NSKeyValueChangeNewKey] as! Double
        }
    }
    
    func makeItBounce(view: UIView) {
        let bounceAnimation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.values = [1.0, 1.2]
        bounceAnimation.duration = 0.15
        bounceAnimation.removedOnCompletion = false
        bounceAnimation.repeatCount = 2
        bounceAnimation.autoreverses = true
        bounceAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        view.layer.addAnimation(bounceAnimation, forKey: "bounce")
    }
    
    @IBAction func trainingButtonPressed() {
        guard self.word.audios.count > 0 else {
            self.navigationController!.popViewControllerAnimated(false)
            return
        }
        self.recorder!.stopRecordingAndKeepResult(false)
        self.makeItBounce(self.trainingSpeakerButton)
        let index = Int(arc4random_uniform(UInt32(self.word!.audios.count)))
        let chosenAudio: Audio = self.word.audios[index]
        let fileURL = chosenAudio.fileURL()!
        self.audioPlayer = try! AVAudioPlayer(contentsOfURL: fileURL)
        self.audioPlayer?.pan = -0.5
        self.audioPlayer?.play()
        // Workaround because AVURLAsset needs files with file extensions
        // http://stackoverflow.com/questions/9290972/is-it-possible-to-make-avurlasset-work-without-a-file-extension
        
        let fileManager = NSFileManager.defaultManager()
        let documentsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .AllDomainsMask).last!
        let tmpURL = documentsURL.URLByAppendingPathComponent("tmp.caf")
        _ = try? fileManager.removeItemAtURL(tmpURL)
        _ = try? fileManager.linkItemAtURL(fileURL, toURL: tmpURL)
        self.trainingWaveform.audioURL = tmpURL
        self.trainingWaveform.progressSamples = 0
        UIView.animateWithDuration((self.audioPlayer?.duration)!, delay: 0, options: .CurveLinear, animations: {() -> Void in
            self.trainingWaveform.progressSamples = self.trainingWaveform.totalSamples
            }, completion: {(done: Bool) -> Void in
                if done {
                    self.trainingWaveform.progressSamples = 0
                }
        })
        if self.workflowState != .Ready {
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(self.audioPlayer!.duration * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.continueNextWorkflowStep(NSNull)
            }
        }
    }
    
    @IBAction func recordButtonPressed() {
        self.makeItBounce(self.recordButton)
        self.recorder!.record()
        if self.workflowState != .Ready {
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(self.recorder!.duration * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.continueNextWorkflowStep(NSNull)
            }
        }
    }
    
    @IBAction func playbackButtonPressed() {
        self.makeItBounce(self.playbackButton)
        self.recorder!.playback()
        if self.workflowState != .Ready {
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(self.recorder!.duration * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.continueNextWorkflowStep(NSNull)
            }
        }
        UIView.animateWithDuration(self.audioPlayer!.duration, delay: 0, options: .CurveLinear, animations: {() -> Void in
            self.playbackWaveform.progressSamples = self.playbackWaveform.totalSamples
            }, completion: {(done: Bool) -> Void in
                if done {
                    self.playbackWaveform.progressSamples = 0
                }
        })
    }
    
    @IBAction func playbackButtonHeld() {
        self.recorder!.reset()
        self.recordButton.hidden = false
        self.playbackButton.hidden = true
        self.checkbox.hidden = true
    }
    
    @IBAction func continueNextWorkflowStep(sender: AnyObject) {
        switch workflowState {
        case .Ready:
            workflowState = .DoAnimationAndSetup
            doFirstWorkflowStep()
        case .DoAnimationAndSetup:
            workflowState = .ListenFirstTime
            self.performSelector(#selector(WordPracticeController.trainingButtonPressed), withObject: nil, afterDelay: WORKFLOW_DELAY)
        case .ListenFirstTime:
            workflowState = .RecordFirstTime
            //self.performSelector(Selector("echoButtonPressed"), withObject: nil, afterDelay: WORKFLOW_DELAY)
        case .RecordFirstTime:
            workflowState = .EchoSecondTime
            self.performSelector(#selector(WordPracticeController.trainingButtonPressed), withObject: nil, afterDelay: WORKFLOW_DELAY)
        case .ListenSecondTime:
            workflowState = .EchoFirstTime
            //self.performSelector(Selector("echoButtonPressed"), withObject: nil, afterDelay: WORKFLOW_DELAY)
        case .EchoFirstTime:
            workflowState = .ListenThirdTime
            self.performSelector(#selector(WordPracticeController.trainingButtonPressed), withObject: nil, afterDelay: WORKFLOW_DELAY)
        case .ListenThirdTime:
            workflowState = .EchoSecondTime
            //self.performSelector(Selector("echoButtonPressed"), withObject: nil, afterDelay: WORKFLOW_DELAY)
        case .EchoSecondTime:
            workflowState = .DoAnimationAndBreakdown
        case .DoAnimationAndBreakdown:
            workflowState = .Ready
        }
        /*
        UIView.animateWithDuration(WORKFLOW_DELAY * 2, animations: {() -> Void in
        for var i = 2; i <= 7; i++ {
        self.view!.viewWithTag(i)!.transform = CGAffineTransformIdentity
        }
        self.view!.viewWithTag(self.workflowState)!.transform = CGAffineTransformMakeTranslation(0, (self.workflowState % 2 == 1) ? 50 : -50)
        self.view!.viewWithTag(self.workflowState)!.alpha = 0.0
        })
        */
    }
    
    @IBAction func resetWorkflow() {
        /*
        self.workflowState = 99;
        
        [UIView animateWithDuration:WORKFLOW_DELAY animations:^{
        for (int i=2; i<=8; i++)
        [self.view viewWithTag:i].alpha=1;
        for (int i=2; i<=7; i++)
        [self.view viewWithTag:i].transform = CGAffineTransformIdentity;
        self.workflowButton.alpha=1;
        }];
        */
    }
    
    @IBAction func checkPressed(sender: AnyObject) {
        let checked: Bool = !self.datasource!.wordCheckedStateForWordPractice(self)
        self.delegate!.wordPractice(self, setWordCheckedState: checked)
        if checked {
            self.checkbox.setImage(UIImage(named: "checkon"), forState: .Normal)
        }
        else {
            self.checkbox.setImage(UIImage(named: "check"), forState: .Normal)
        }
        
        FIRAnalytics.logEventWithName("learning", parameters: ["action": "Checked word"])
    }
    
    @IBAction func fastForwardPressed() {
        // see http://stackoverflow.com/questions/8926606/performseguewithidentifier-vs-instantiateviewcontrollerwithidentifier
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let newWordPractice = storyboard.instantiateViewControllerWithIdentifier("WordPractice") as! WordPracticeController
        self.delegate!.skipToNextWordForWordPractice(self)
        newWordPractice.datasource = self.datasource
        newWordPractice.delegate = self.delegate
        // see http://stackoverflow.com/questions/410471/how-can-i-pop-a-view-from-a-uinavigationcontroller-and-replace-it-with-another-i
        let navController: UINavigationController = self.navigationController!
        navController.popViewControllerAnimated(false)
        navController.pushViewController(newWordPractice, animated: true)
    }
    
    func doFirstWorkflowStep() {
        /*
        [UIView animateWithDuration:WORKFLOW_DELAY animations:^{
        for (int i=2; i<=7; i++)
        [self.view viewWithTag:i].alpha=1;
        for (int i=2; i<=7; i++)
        [self.view viewWithTag:i].transform = CGAffineTransformIdentity;
        self.workflowButton.alpha=0;
        }];
        
        NSURL *url = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource:@"Next" ofType:@"aif"]];
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        self.audioPlayer.pan = 0;
        [self.audioPlayer play];
        
        [self performSelector:@selector(continueNextWorkflowStep:) withObject:nil afterDelay:self.audioPlayer.duration];
        */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.word = self.datasource!.currentWordForWordPractice(self)
        self.title = self.word.name
        self.wordTitle.text = self.word.name
        self.wordDetail.text = self.word.detail
        self.recorder = PHOREchoRecorder()
        self.recorder!.addObserver(self, forKeyPath: "microphoneLevel", options: .New, context: nil)
        self.recorder!.pan = 0.5
        self.recorder!.delegate = self
        self.trainingSpeakerButton.addSubview(self.trainingWaveform)
        self.view!.addConstraint(NSLayoutConstraint(item: self.trainingSpeakerButton.imageView!, attribute: .Right, relatedBy: .Equal, toItem: self.trainingWaveform, attribute: .Left, multiplier: 1, constant: 8))
        self.playbackButton.addSubview(self.playbackWaveform)
        self.view!.addConstraint(NSLayoutConstraint(item: self.playbackButton.imageView!, attribute: .Right, relatedBy: .Equal, toItem: self.playbackWaveform, attribute: .Left, multiplier: 1, constant: 8))
        self.recordButton.addSubview(self.recordGuage)
        self.view!.addConstraint(NSLayoutConstraint(item: self.recordButton.imageView!, attribute: .Right, relatedBy: .Equal, toItem: self.recordGuage, attribute: .Left, multiplier: 1, constant: 8))
        var rightBarButtonItems = [UIBarButtonItem]()
        if self.delegate!.wordPracticeShouldShowNextButton(self) {
            let fastForward: UIBarButtonItem = self.navigationItem.rightBarButtonItem!
            rightBarButtonItems.append(fastForward)
        }
        self.navigationItem.rightBarButtonItems = rightBarButtonItems
        // See http://stackoverflow.com/questions/2246374/low-recording-volume-in-combination-with-avaudiosessioncategoryplayandrecord
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.overrideOutputAudioPort(.Speaker)
            try audioSession.setActive(true)
        } catch {
            NSLog("error doing outputaudioportoverride: \(error)")
        }
        self.performSelector(#selector(WordPracticeController.trainingButtonPressed), withObject: self, afterDelay: 0.5)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        FIRAnalytics.logEventWithName("page_view", parameters: ["name": NSStringFromClass(self.dynamicType)])
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.recorder!.removeObserver(self, forKeyPath: "microphoneLevel")
        super.viewWillDisappear(animated)
    }
    
}

extension WordPracticeController: PHOREchoRecorderDelegate {
    func recording(recorder: PHOREchoRecorder, didFinishSuccessfully success: Bool) {
        if success {
            self.recordButton.hidden = true
            self.playbackButton.hidden = false
            self.playbackWaveform.audioURL = self.recorder!.audioDataURL()
            self.playbackWaveform.setNeedsLayout() // TODO: BUG UPSTREAM
            if self.delegate!.currentWordCanBeCheckedForWordPractice(self) {
                let checked: Bool = self.datasource!.wordCheckedStateForWordPractice(self)
                if checked {
                    self.checkbox.setImage(UIImage(named: "checkon"), forState: .Normal)
                }
                else {
                    self.checkbox.setImage(UIImage(named: "check"), forState: .Normal)
                }
                self.checkbox.hidden = false
            }
            if self.workflowState != .Ready {
                self.continueNextWorkflowStep(NSNull)
            }
        }
        else {
            if self.workflowState != .Ready {
                self.resetWorkflow()
            }
        }
    }
    
}