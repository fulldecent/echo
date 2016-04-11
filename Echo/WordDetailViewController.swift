//
//  WordDetailViewController.swift
//  Echo
//
//  Created by William Entriken on 1/13/16.
//
//

import Foundation
import UIKit
import MBProgressHUD
import Google
import AVFoundation
import FDWaveformView

protocol WordDetailDelegate: class {
    func wordDetailController(controller: WordDetailController, canEditWord word: Word) -> Bool
    func wordDetailController(controller: WordDetailController, didSaveWord word: Word)
    func wordDetailController(controller: WordDetailController, canReplyWord word: Word) -> Bool
}

class WordDetailController: UITableViewController {
    enum Section: Int {
        case Info
        case Recordings
    }
    
    enum Cell {
        case Language
        case Title
        case Detail
        case Recording
    }
    
    var word = Word()
    @IBOutlet var actionButton: UIBarButtonItem!
    weak var delegate: WordDetailDelegate?
    private let NUMBER_OF_RECORDERS = 3

    // Outlets for UI elements
    @IBOutlet var wordLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    @IBOutlet var wordField: UITextField!
    @IBOutlet var detailField: UITextField!
    
    lazy var recordButtons: [UIButton] = {
        var retval = [UIButton]()
        for i in 0...self.NUMBER_OF_RECORDERS-1 {
            let indexPath = NSIndexPath(forRow: i, inSection: Section.Recordings.rawValue)
            let cell = self.tableView(self.tableView, cellForRowAtIndexPath: indexPath)
            retval.append(cell.viewWithTag(3) as! UIButton)
        }
        return retval
    }()
    lazy var recordGuages: [FDBarGauge] = {
        var retval = [FDBarGauge]()
        for i in 0...self.NUMBER_OF_RECORDERS-1 {
            let indexPath = NSIndexPath(forRow: i, inSection: Section.Recordings.rawValue)
            let cell = self.tableView(self.tableView, cellForRowAtIndexPath: indexPath)
            retval.append(cell.viewWithTag(10) as! FDBarGauge)
        }
        return retval
    }()
    lazy var playButtons: [UIButton] = {
        var retval = [UIButton]()
        for i in 0...self.NUMBER_OF_RECORDERS-1 {
            let indexPath = NSIndexPath(forRow: i, inSection: Section.Recordings.rawValue)
            let cell = self.tableView(self.tableView, cellForRowAtIndexPath: indexPath)
            retval.append(cell.viewWithTag(1) as! UIButton)
        }
        return retval
    }()
    lazy var waveforms: [FDWaveformView] = {
        var retval = [FDWaveformView]()
        for i in 0...self.NUMBER_OF_RECORDERS-1 {
            let indexPath = NSIndexPath(forRow: i, inSection: Section.Recordings.rawValue)
            let cell = self.tableView(self.tableView, cellForRowAtIndexPath: indexPath)
            retval.append(cell.viewWithTag(2) as! FDWaveformView)
        }
        return retval
    }()
    lazy var resetButtons: [UIButton] = {
        var retval = [UIButton]()
        for i in 0...self.NUMBER_OF_RECORDERS-1 {
            let indexPath = NSIndexPath(forRow: i, inSection: Section.Recordings.rawValue)
            let cell = self.tableView(self.tableView, cellForRowAtIndexPath: indexPath)
            retval.append(cell.viewWithTag(4) as! UIButton)
        }
        return retval
    }()
    lazy var echoRecorders: [PHOREchoRecorder] = {
        var retval = [PHOREchoRecorder]()
        for i in 0...self.NUMBER_OF_RECORDERS-1 {
            let recorder: PHOREchoRecorder
            if i < self.word.audios.count {
                let audio = self.word.audios[i]
                recorder = PHOREchoRecorder(audioDataAtURL: audio.fileURL()!)
            } else {
                recorder = PHOREchoRecorder()
            }
            recorder.delegate = self
            retval.append(recorder)
        }
        return retval
    }()

    // Model
    var editingLanguageTag: String = ""
    var editingName: String = ""
    var editingDetail: String = ""
    
    var hud: MBProgressHUD?
    
    func cellTypeForRowAtIndexPath(indexPath: NSIndexPath) -> Cell {
        switch Section(rawValue: indexPath.section)! {
        case .Info:
            switch indexPath.row {
            case 0:
                return .Language
            case 1:
                return .Title
            default:
                return .Detail
            }
        case .Recordings:
            return .Recording
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
    
    func setWord(word: Word) {
        self.word = word
        self.editingLanguageTag = word.languageTag
        self.editingName = word.name
        self.editingDetail = word.detail.mutableCopy() as! String
    }

    @IBAction func playButtonPressed(sender: UIButton) {
        let echoIndex = self.playButtons.indexOf(sender)!
        let recorder = self.echoRecorders[echoIndex]
        recorder.playback()
        self.makeItBounce(sender)
    }
    
    @IBAction func recordButtonPressed(sender: UIButton) {
        let echoIndex = self.recordButtons.indexOf(sender)!
        let recorder = self.echoRecorders[echoIndex]
        recorder.record()
        self.makeItBounce(sender)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let recorder = object as? PHOREchoRecorder else {
            return
        }
        guard let echoIndex = self.echoRecorders.indexOf(recorder) else {
            return
        }
        guard keyPath == "microphoneLevel" else {
            return
        }
        let guage = self.recordGuages[echoIndex]
        guage.value = recorder.microphoneLevel
        NSLog("observed microphoneLevel %@", guage.value)
    }
    
    @IBAction func save() {
        var files = [Audio]()
        self.word.languageTag = self.editingLanguageTag
        self.word.name = self.editingName
        self.word.detail = self.editingDetail
        for i in 1...self.NUMBER_OF_RECORDERS {
            let recorder = self.echoRecorders[i]
            let audio: Audio
            if self.word.audios.count > i {
                audio = self.word.audios[i]
            } else {
                audio = Audio(word: self.word)
            }
            if recorder.audioWasModified {
                let fileManager = NSFileManager.defaultManager()
                let documentsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .AllDomainsMask).last!
                _ = documentsURL.URLByAppendingPathComponent("tmp.caf")
                do {
                    try fileManager.removeItemAtURL(audio.fileURL()!)
                    try fileManager.createDirectoryAtURL(self.word.fileURL()!, withIntermediateDirectories: true, attributes: nil)
                    try fileManager.moveItemAtURL(recorder.audioDataURL()!, toURL: audio.fileURL()!)
                } catch {
                    print("could not save audio: \(error)")
                }
                files.append(audio)
            }
            else {
                files.append((self.word.audios)[i])
            }
        }
        self.word.audios = files
        self.delegate!.wordDetailController(self, didSaveWord: self.word)
    }
    
    @IBAction func validate() {
        var valid: Bool = true
        let firstCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))!
        let goodColor = firstCell.textLabel!.textColor
        let badColor: UIColor = UIColor.redColor()
        if self.editingLanguageTag.isEmpty {
            valid = false
        }
        if self.editingName.isEmpty {
            self.wordLabel.textColor = badColor
            valid = false
        } else {
            self.wordLabel.textColor = goodColor
        }
        for i in 0 ..< NUMBER_OF_RECORDERS {
            let recorder: PHOREchoRecorder = (self.echoRecorders)[i]
            let recordButton: UIButton = (self.recordButtons)[i]
            let playButton: UIButton = (self.playButtons)[i]
            let checkButtons: UIButton = (self.resetButtons)[i]
            if recorder.duration == 0 {
                valid = false
                recordButton.hidden = false
                playButton.hidden = true
                checkButtons.hidden = false
            } else {
                recordButton.hidden = true
                playButton.hidden = false
                checkButtons.hidden = false
            }
        }
        self.actionButton.enabled = valid
    }
    
    @IBAction func updateName(sender: UITextField) {
        self.editingName = sender.text!
        self.title = sender.text!
        self.validate()
    }
    
    @IBAction func updateDetail(sender: UITextField) {
        self.editingDetail = sender.text!
        self.validate()
    }
    
    @IBAction func resetButtonPressed(sender: UIButton) {
        let echoIndex = self.resetButtons.indexOf(sender)!
        let recorder: PHOREchoRecorder = self.echoRecorders[echoIndex]
        recorder.reset()
        self.validate()
        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forItem: echoIndex, inSection: 1)], withRowAnimation: .Fade)
    }
    
    @IBAction func reply(sender: UIBarButtonItem) {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let wordDetail: WordDetailController = storyboard.instantiateViewControllerWithIdentifier("WordDetailController") as! WordDetailController
        wordDetail.delegate = self
        let replyWord: Word = Word()
        replyWord.languageTag = self.word.languageTag
        replyWord.name = self.word.name
        replyWord.detail = self.word.detail
        wordDetail.word = replyWord
        self.navigationController!.pushViewController(wordDetail, animated: true)
    }
    
    func setup() {
        //TODO: do this bullshit in the recorder class
        // See http://stackoverflow.com/questions/2246374/low-recording-volume-in-combination-with-avaudiosessioncategoryplayandrecord
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try audioSession.overrideOutputAudioPort(.Speaker)
            try audioSession.setActive(true)
        } catch {
            NSLog("error doing outputaudioportoverride: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        for recorder in self.echoRecorders {
            recorder.addObserver(self, forKeyPath: "microphoneLevel", options: .New, context: nil)
        }
        self.title = self.word.name
        if self.delegate?.wordDetailController(self, canEditWord: self.word) == true {
            if self.delegate!.wordDetailController(self, canReplyWord: self.word) {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: #selector(WordDetailController.reply(_:)))
            }
            else {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "WordDetail")
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject: AnyObject])
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if self.delegate?.wordDetailController(self, canEditWord: self.word) == true {
            self.validate()
        }
        if self.editingLanguageTag.isEmpty {
            self.performSegueWithIdentifier("language", sender: self)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        for recorder in self.echoRecorders {
            recorder.removeObserver(self, forKeyPath: "microphoneLevel")
        }
        super.viewWillDisappear(animated)
    }
}

extension WordDetailController /*: UITableViewDataSource */ {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .Info:
            return 3
        case .Recordings:
            return self.NUMBER_OF_RECORDERS
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch self.cellTypeForRowAtIndexPath(indexPath) {
        case .Language:
            let cell = tableView.dequeueReusableCellWithIdentifier("language")!
            cell.detailTextLabel!.text = Languages.nativeDescriptionForLanguage(self.editingLanguageTag)
            return cell
        case .Title:
            let cell = tableView.dequeueReusableCellWithIdentifier("word") as! FDRightDetailWithTextFieldCell
            self.wordLabel = cell.textLabel
            self.wordField = cell.textField
            self.wordField.text = self.editingName
            self.wordField.enabled = self.delegate?.wordDetailController(self, canEditWord: self.word) ?? false
            self.wordField.delegate = self
            self.wordField.addTarget(self, action: #selector(WordDetailController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
            return cell
        case .Detail:
            let cell = tableView.dequeueReusableCellWithIdentifier("detail") as! FDRightDetailWithTextFieldCell
            self.detailLabel = cell.textLabel
            self.detailField = cell.textField
            self.detailLabel.text = "Detail (\(self.editingLanguageTag))"
            self.detailField.text = self.editingDetail
            self.detailField.enabled = self.delegate?.wordDetailController(self, canEditWord: self.word) ?? false
            self.detailField.delegate = self
            self.detailField.addTarget(self, action: #selector(WordDetailController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)
            return cell
        case .Recording:
            let cell = tableView.dequeueReusableCellWithIdentifier("record")!
            let playButton: UIButton = cell.viewWithTag(1) as! UIButton
            let waveform: FDWaveformView = cell.viewWithTag(2) as! FDWaveformView
            let recordButton: UIButton = cell.viewWithTag(3) as! UIButton
            let recordGuage: FDBarGauge = cell.viewWithTag(10) as! FDBarGauge
            let checkbox: UIButton = cell.viewWithTag(4) as! UIButton
            let recorder: PHOREchoRecorder = self.echoRecorders[indexPath.row]
            if indexPath.row < self.word.audios.count {
                let file = self.word.audios[indexPath.row]
                // Workaround because AVURLAsset needs files with file extensions
                // http://stackoverflow.com/questions/9290972/is-it-possible-to-make-avurlasset-work-without-a-file-extension
                let fileManager = NSFileManager.defaultManager()
                let documentsURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .AllDomainsMask).last!
                let tmpURL = documentsURL.URLByAppendingPathComponent("tmp.caf")
                do {
                    try fileManager.removeItemAtURL(tmpURL)
                    try fileManager.linkItemAtURL(file.fileURL()!, toURL: tmpURL)
                } catch {
                    print("could not save audio: \(error)")
                }
                waveform.audioURL = tmpURL
            }
            playButton.addSubview(waveform)
            cell.contentView.addConstraint(NSLayoutConstraint(item: playButton.imageView!, attribute: .Right, relatedBy: .Equal, toItem: waveform, attribute: .Left, multiplier: 1, constant: 8))
            recordButton.addSubview(recordGuage)
            cell.contentView.addConstraint(NSLayoutConstraint(item: recordButton.imageView!, attribute: .Right, relatedBy: .Equal, toItem: recordGuage, attribute: .Left, multiplier: 1, constant: 8))
            self.playButtons[indexPath.row] = playButton
            self.waveforms[indexPath.row] = waveform
            self.recordButtons[indexPath.row] = recordButton
            self.recordGuages[indexPath.row] = recordGuage
            self.resetButtons[indexPath.row] = checkbox
            if !(self.delegate?.wordDetailController(self, canEditWord: self.word) == true) {
                playButton.hidden = false
                recordButton.hidden = true
                checkbox.hidden = true
            }
            else if recorder.duration > 0 {
                playButton.hidden = false
                recordButton.hidden = true
                checkbox.hidden = false
                checkbox.setImage(UIImage(named: "Checkbox checked"), forState: .Normal)
            }
            else {
                playButton.hidden = true
                recordButton.hidden = false
                checkbox.hidden = false
                checkbox.setImage(UIImage(named: "Checkbox empty"), forState: .Normal)
            }
            
            return cell
        }
    }
}

extension WordDetailController /*: UITableViewDelegate */ {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch cellTypeForRowAtIndexPath(indexPath) {
        case .Language:
            if self.delegate!.wordDetailController(self, canEditWord: self.word) {
                self.performSegueWithIdentifier("language", sender: self)
            }
        default:
            break
        }
    }
}

extension WordDetailController /*: UIViewController */ {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.destinationViewController {
        case is LanguageSelectController:
            let controller = segue.destinationViewController as! LanguageSelectController
            controller.delegate = self
        default:
            break
        }
    }
}

extension WordDetailController /*: UIScrollViewDelegate*/ {
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.view!.endEditing(true)
        // fucking nice
    }
}

extension WordDetailController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {   //delegate method
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    //This is an observation
    //TODO should be in same scope (extension) as where observer is set
    func textFieldDidChange(textField: UITextField) {
        //TODO use switch
        if textField == self.wordField {
            self.editingName = textField.text!
        }
        else {
            self.editingDetail = textField.text!
        }
        self.validate()
    }
}

extension WordDetailController: PHOREchoRecorderDelegate {
    func recording(recorder: PHOREchoRecorder, didFinishSuccessfully success: Bool) {
        guard success else {
            return
        }
        self.validate()
    }
}

extension WordDetailController: LanguageSelectControllerDelegate {
    func languageSelectController(controller: AnyObject, didSelectLanguage tag: String, withNativeName name: String) {
        self.editingLanguageTag = tag
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        self.validate()
        self.navigationController!.popToViewController(self, animated: true)
    }
}

extension WordDetailController: WordDetailDelegate {
    func wordDetailController(controller: WordDetailController, canEditWord word: Word) -> Bool {
        return true
    }
    
    func wordDetailController(controller: WordDetailController, didSaveWord word: Word) {
        let hud = MBProgressHUD.showHUDAddedTo(controller.view!, animated: true)
        hud.labelText = "Uploading reply"
        hud.delegate = self
        self.hud = hud
        let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
        networkManager.postWord(word, withFilesInPath: NSTemporaryDirectory(), asReplyToWordWithID: self.word.serverId, withProgress: {(PGprogress: Float) -> Void in
            self.hud!.mode = .AnnularDeterminate
            self.hud!.progress = PGprogress
            if PGprogress == 1 {
                self.hud!.hide(true)
                // http://stackoverflow.com/questions/9411271/how-to-perform-uikit-call-on-mainthread-from-inside-a-block
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    controller.navigationController!.popToRootViewControllerAnimated(true)
                })
            }
            }, onFailure: {(error: NSError) -> Void in
                self.hud!.hide(false)
                MBProgressHUD.flashError(error)
        })
    }
    
    func wordDetailController(controller: WordDetailController, canReplyWord word: Word) -> Bool {
        return false
    }
}

extension WordDetailController: MBProgressHUDDelegate {
    func hudWasHidden(hud: MBProgressHUD) {
        self.hud = nil
    }
}