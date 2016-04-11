//
//  LessonViewController.swift
//  Echo
//
//  Created by William Entriken on 1/13/16.
//
//

import Foundation
import UIKit
import MBProgressHUD
import Google

protocol LessonViewDelegate: class {
    func lessonView(controller: LessonViewController, didSaveLesson lesson: Lesson)
    func lessonView(controller: LessonViewController, wantsToUploadLesson lesson: Lesson)
    func lessonView(controller: LessonViewController, wantsToDeleteLesson lesson: Lesson)
}

class LessonViewController: UITableViewController {
    private var currentWordIndex = 0
    private var wordListIsShuffled = false
    private var editingFromSwipe = false
    private var hud: MBProgressHUD? = nil
    private var actionIsToLessonAuthor = false
    var lesson: Lesson! {
        didSet {
            var buttons = [UIBarButtonItem]()
            if lesson.isByCurrentUser() {
                buttons.append(self.editButtonItem())
                if lesson.words.count == 0 {
                    self.editing = true
                }
            }
            buttons.append(UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(LessonViewController.lessonSharePressed(_:))))
            self.navigationItem.rightBarButtonItems = buttons
        }
    }
    weak var delegate: LessonViewDelegate? = nil
    @IBOutlet var lessonLabel: UITextField!
    @IBOutlet var detailLabel: UITextField!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "LessonView")
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject: AnyObject])
    }
    
    @IBAction func lessonFlagPressed(sender: AnyObject) {
        self.actionIsToLessonAuthor = true
        let title = "Flag lesson"
        let message = "Flagging a lesson is public and will delete your copy of the lesson. To continue, choose a reason."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .ActionSheet)
        alert.addAction(UIAlertAction(title: "Inappropriate title", style: .Default, handler: {
            (UIAlertAction) -> Void in
            let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true)
            hud.mode = .Indeterminate
            hud.labelText = "Sending..."
            self.hud = hud
            let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
            networkManager.doFlagLesson(self.lesson, withReason: .InappropriateTitle, onSuccess: {
                () -> Void in
                hud.mode = .Determinate
                hud.progress = 1
                hud.hide(true)
                self.delegate!.lessonView(self, wantsToDeleteLesson: self.lesson)
                self.navigationController!.popViewControllerAnimated(true)
                }, onFailure: {(error: NSError) -> Void in
                    hud.hide(false)
                    MBProgressHUD.flashError(error)
            })
        }))
        alert.addAction(UIAlertAction(title: "Inaccurate content", style: .Default, handler: {
            (UIAlertAction) -> Void in
            let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true)
            hud.mode = .Indeterminate
            hud.labelText = "Sending..."
            self.hud = hud
            let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
            networkManager.doFlagLesson(self.lesson, withReason: .InaccurateContent, onSuccess: {
                () -> Void in
                hud.mode = .Determinate
                hud.progress = 1
                hud.hide(true)
                self.delegate!.lessonView(self, wantsToDeleteLesson: self.lesson)
                self.navigationController!.popViewControllerAnimated(true)
                }, onFailure: {(error: NSError) -> Void in
                    hud.hide(false)
                    MBProgressHUD.flashError(error)
            })
        }))
        alert.addAction(UIAlertAction(title: "Poor quality", style: .Default, handler: {
            (UIAlertAction) -> Void in
            let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true)
            hud.mode = .Indeterminate
            hud.labelText = "Sending..."
            self.hud = hud
            let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
            networkManager.doFlagLesson(self.lesson, withReason: .PoorQuality, onSuccess: {
                () -> Void in
                hud.mode = .Determinate
                hud.progress = 1
                hud.hide(true)
                self.delegate!.lessonView(self, wantsToDeleteLesson: self.lesson)
                self.navigationController!.popViewControllerAnimated(true)
                }, onFailure: {(error: NSError) -> Void in
                    hud.hide(false)
                    MBProgressHUD.flashError(error)
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func lessonSharePressed(sender: AnyObject) {
        // Create the item to share (in this example, a url)
        let urlString: String = "https://learnwithecho.com/lessons/\(Int(self.lesson!.serverId))"
        let url: NSURL = NSURL(string: urlString)!
        let title: String = "I am practicing a lesson in \(Languages.nativeDescriptionForLanguage(self.lesson.languageTag)): \(self.lesson.name)"
        let itemsToShare: [AnyObject] = [url, title]
        let activityVC: UIActivityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        activityVC.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll]
        //or whichever you don't need
        self.presentViewController(activityVC, animated: true, completion: { _ in })
    }
    
    @IBAction func lessonReplyAuthorPressed(sender: AnyObject) {
        let alert = UIAlertController(title: "Send feedback", message: "", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler(nil)
        alert.addAction(UIAlertAction(title: "Send", style: .Default, handler: {
            (UIAlertAction) -> Void in
            let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true)
            hud.mode = .Indeterminate
            hud.labelText = "Sending..."
            let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
            let message: String = alert.textFields![0].text!
            networkManager.postFeedback(message, toAuthorOfLessonWithID: self.lesson.serverId, onSuccess: {
                () -> Void in
                hud.mode = .Determinate
                hud.progress = 1
                hud.hide(true)
                }, onFailure: {(error: NSError) -> Void in
                    hud.hide(true)
                    MBProgressHUD.flashError(error)
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func sharePressed(sender: AnyObject) {
        self.lesson.localChangesSinceLastSync = true
        self.delegate!.lessonView(self, wantsToUploadLesson: self.lesson)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        if editing == self.editing {
            return
        }
        self.tableView.beginUpdates()
        let shuffleRow = [NSIndexPath(forRow: 0, inSection: Section.Words.rawValue)]
        let addRow = [NSIndexPath(forRow: (self.lesson.words).count, inSection: Section.Words.rawValue)]
        if !self.editingFromSwipe {
            if editing {
                if self.lesson.words.count > 0 {
                    self.tableView.deleteRowsAtIndexPaths(shuffleRow, withRowAnimation: .Automatic)
                }
                self.tableView.insertRowsAtIndexPaths(addRow, withRowAnimation: .Automatic)
                self.navigationItem.setHidesBackButton(true, animated: true)
            }
            else {
                self.tableView.deleteRowsAtIndexPaths(addRow, withRowAnimation: .Automatic)
                if self.lesson.words.count > 0 {
                    self.tableView.insertRowsAtIndexPaths(shuffleRow, withRowAnimation: .Automatic)
                }
                self.navigationItem.setHidesBackButton(false, animated: true)
            }
        }
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: animated)
        if !self.editingFromSwipe {
            if !editing {
                if self.lesson.isShared() {
                    self.lesson.localChangesSinceLastSync = true
                }
                self.delegate!.lessonView(self, didSaveLesson: self.lesson)
                self.title = self.lesson.name
            }
            self.tableView.reloadSections(NSIndexSet(index: Section.Actions.rawValue), withRowAnimation: .Automatic)
            self.tableView.reloadSections(NSIndexSet(index: Section.Byline.rawValue), withRowAnimation: .Automatic)
            self.tableView.reloadSections(NSIndexSet(index: Section.EditingInfo.rawValue), withRowAnimation: .Automatic)
        }
        self.tableView.endUpdates()
    }
    func nameTextFieldDidChange(textField: UITextField) {
        self.lesson.name = textField.text!
    }
    
    func detailTextFieldDidChange(textField: UITextField) {
        self.lesson.detail = textField.text!
    }
}

extension LessonViewController: WordPracticeDataSource {
    func currentWordForWordPractice(wordPractice: WordPracticeController) -> Word {
        return (self.lesson.words)[self.currentWordIndex]
    }
    
    func wordCheckedStateForWordPractice(wordPractice: WordPracticeController) -> Bool {
        let word: Word = (self.lesson.words)[self.currentWordIndex]
        return word.completed
    }
}

extension LessonViewController: WordPracticeDelegate {
    func skipToNextWordForWordPractice(wordPractice: WordPracticeController) {
        if self.wordListIsShuffled {
            self.currentWordIndex = Int(arc4random_uniform(UInt32(self.lesson.words.count)))
        }
        else {
            self.currentWordIndex = (self.currentWordIndex + 1) % (self.lesson.words).count
        }
    }
    
    func currentWordCanBeCheckedForWordPractice(wordPractice: WordPracticeController) -> Bool {
        return true
    }
    
    func wordPracticeShouldShowNextButton(wordPractice: WordPracticeController) -> Bool {
        return true
    }
    
    func wordPractice(wordPractice: WordPracticeController, setWordCheckedState state: Bool) {
        let word: Word = (self.lesson.words)[self.currentWordIndex]
        word.completed = state
        self.delegate?.lessonView(self, didSaveLesson: self.lesson)
        let path = NSIndexPath(forRow: self.currentWordIndex + 1, inSection: Section.Words.rawValue)
        self.tableView.reloadRowsAtIndexPaths([path], withRowAnimation: .Automatic)
    }
}

extension LessonViewController /*: UITableViewDataSource */ {
    enum Section: Int {
        case Actions
        case EditingInfo
        case Words
        case Byline
    }
    
    enum Cell {
        case Shared
        case NotShared
        case Shuffle
        case Word
        case AddWord
        case AuthorByline
        case EditLanguage
        case EditTitle
        case EditDescription
    }

    func cellTypeForRowAtIndexPath(indexPath: NSIndexPath) -> Cell {
        switch Section(rawValue: indexPath.section)! {
        case .Actions:
            if self.lesson.isByCurrentUser() {
                return self.lesson.isShared() ? .Shared : .NotShared
            }
            else {
                return .AuthorByline
            }
        case .EditingInfo:
            if indexPath.row == 0 {
                return .EditLanguage
            }
            else if indexPath.row == 1 {
                return .EditTitle
            }
            else {
                return .EditDescription
            }
        case .Words:
            if indexPath.row == 0 && !(self.tableView.editing && !self.editingFromSwipe) {
                return .Shuffle
            }
            else if indexPath.row == (self.lesson.words).count && (self.tableView.editing && !self.editingFromSwipe) {
                return .AddWord
            }
            else {
                return .Word
            }
        case .Byline:
            return .AuthorByline
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        switch Section(rawValue: section)! {
        case .Actions:
            return self.lesson.detail
        default:
            return ""
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .Actions:
            if self.editing && !self.editingFromSwipe {
                return 0
            }
            else {
                return 1
            }
        case .EditingInfo:
            if self.editing && !self.editingFromSwipe {
                return 3
            }
            else {
                return 0
            }
        case .Words:
            if self.lesson.words.count > 0 || (self.tableView.editing && !self.editingFromSwipe) {
                return (self.lesson.words).count + 1
            }
            else {
                return (self.lesson.words).count
            }
        case .Byline:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch self.cellTypeForRowAtIndexPath(indexPath) {
        case .NotShared:
            return tableView.dequeueReusableCellWithIdentifier("notShared")!
        case .Shared:
            return tableView.dequeueReusableCellWithIdentifier("shared")!
        case .AddWord:
            return tableView.dequeueReusableCellWithIdentifier("add")!
        case .Shuffle:
            return tableView.dequeueReusableCellWithIdentifier("shuffle")!
        case .Word:
            let cell = tableView.dequeueReusableCellWithIdentifier("word")!
            let index = (self.tableView.editing && !self.editingFromSwipe) ? indexPath.row : indexPath.row - 1
            let word = self.lesson.words[index]
            cell.textLabel!.text = word.name
            cell.detailTextLabel!.text = word.detail
            if self.lesson.isByCurrentUser() {
                cell.accessoryType = .None
            }
            else if word.completed {
                cell.accessoryType = .Checkmark
            }
            else {
                cell.accessoryType = .None
            }
            return cell
        case .AuthorByline:
            let cell = tableView.dequeueReusableCellWithIdentifier("author")!
            cell.textLabel!.text = self.lesson.userName
            let url: NSURL = NSURL(string: "https://learnwithecho.com/avatarFiles/\(Int(self.lesson.userID)).png")!
            let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)
            cell.imageView!.setImageWithURLRequest(request, placeholderImage: UIImage(named: "none40"), success: nil, failure: nil)
            let flagButton: UIButton = UIButton(type: .RoundedRect)
            flagButton.setImage(UIImage(named: "flag"), forState: .Normal)
            flagButton.frame = CGRectMake(0, 0, 40, 40)
            flagButton.addTarget(self, action: #selector(LessonViewController.lessonFlagPressed(_:)), forControlEvents: .TouchUpInside)
            cell.accessoryView = flagButton
            return cell
        case .EditLanguage:
            let cell = tableView.dequeueReusableCellWithIdentifier("editLanguage")!
            cell.detailTextLabel!.text = Languages.nativeDescriptionForLanguage(self.lesson.languageTag)
            return cell
        case .EditTitle:
            let cell = tableView.dequeueReusableCellWithIdentifier("editTitle") as! FDRightDetailWithTextFieldCell
            cell.textField.text = self.lesson.name
            cell.textField.addTarget(self, action: #selector(LessonViewController.nameTextFieldDidChange(_:)), forControlEvents: .EditingChanged)
            return cell
        case .EditDescription:
            let cell = tableView.dequeueReusableCellWithIdentifier("editDetail") as! FDRightDetailWithTextFieldCell
            cell.textField.text = self.lesson.detail
            cell.textField.addTarget(self, action: #selector(LessonViewController.detailTextFieldDidChange(_:)), forControlEvents: .EditingChanged)
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .Actions:
            cell.backgroundColor = UIColor(hue: 0.63, saturation: 0.1, brightness: 0.97, alpha: 1)
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        switch Section(rawValue: indexPath.section)! {
        case .Words:
            return false
        default:
            return self.lesson.isByCurrentUser() && self.cellTypeForRowAtIndexPath(indexPath) == .Word
        }
    }
    
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if proposedDestinationIndexPath.section != sourceIndexPath.section {
            return sourceIndexPath
        }
        if proposedDestinationIndexPath.row < self.lesson.words.count {
            return proposedDestinationIndexPath
        }
        else {
            return sourceIndexPath
        }
    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let word = self.lesson.words.removeAtIndex(sourceIndexPath.row)
        self.lesson.words.insert(word, atIndex: destinationIndexPath.row)
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .Words:
            if editingStyle == .Insert {
                self.currentWordIndex = Int(self.lesson.words.count)
                self.performSegueWithIdentifier("editWord", sender: self)
            } else if editingStyle == .Delete {
                let index = self.editingFromSwipe ? indexPath.row - 1 : indexPath.row
                self.tableView.beginUpdates()
                self.lesson.words.removeAtIndex(index)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                if self.lesson.words.count == 0 {
                    self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: Section.Words.rawValue)], withRowAnimation: .Automatic)
                }
                self.tableView.endUpdates()
                self.lesson.removeStaleFiles()
            }
        default:
            break
        }
    }
}

extension LessonViewController /*: UITableViewDelegate */ {
    override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        self.editingFromSwipe = true
        super.tableView(tableView, willBeginEditingRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        super.tableView(tableView, didEndEditingRowAtIndexPath: indexPath)
        self.editingFromSwipe = false
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if self.editing {
            switch self.cellTypeForRowAtIndexPath(indexPath) {
            case .AddWord:
                return indexPath
            default:
                return nil
            }
        }
        else {
            switch self.cellTypeForRowAtIndexPath(indexPath) {
            case .Word, .Shuffle, .AddWord:
                return indexPath
            default:
                return nil
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch self.cellTypeForRowAtIndexPath(indexPath) {
        case .Shuffle:
            self.wordListIsShuffled = true
            if self.wordListIsShuffled {
                self.currentWordIndex = Int(arc4random_uniform(UInt32(self.lesson.words.count)))
            } else {
                self.currentWordIndex = (self.currentWordIndex + 1) % (self.lesson.words).count
            }
            self.performSegueWithIdentifier("echoWord", sender: self)
        case .AddWord:
            self.tableView(tableView, commitEditingStyle: .Insert, forRowAtIndexPath: indexPath)
        case .Word:
            self.currentWordIndex = Int(indexPath.row) - 1
            self.wordListIsShuffled = false
            self.performSegueWithIdentifier("echoWord", sender: self)
        case .AuthorByline:
            break
        default:
            break
        }
        
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if !self.lesson.isByCurrentUser() {
            return .None
        }
        switch self.cellTypeForRowAtIndexPath(indexPath) {
        case .AddWord:
            return .Insert
        case .Word:
            return .Delete
        default:
            return .None
        }
        
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        self.currentWordIndex = Int(indexPath.row) - 1
        self.wordListIsShuffled = false
        self.performSegueWithIdentifier("editWord", sender: self)
    }
}

extension LessonViewController /*: UIViewController*/ {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.destinationViewController {
        case is WordPracticeController:
            let controller = segue.destinationViewController as! WordPracticeController
            controller.delegate = self
            controller.datasource = self
        case is WordDetailController:
            let controller = segue.destinationViewController as! WordDetailController
            controller.delegate = self
            if self.currentWordIndex < (self.lesson.words).count {
                controller.word = (self.lesson.words)[self.currentWordIndex]
            } else {
                let word: Word = Word()
                word.languageTag = self.lesson.languageTag
                word.lesson = self.lesson
                controller.word = word
            }
        default:
            break
        }
    }
}

extension LessonViewController: WordDetailDelegate {
    func wordDetailController(controller: WordDetailController, didSaveWord word: Word) {
        // PRECONDITION: self.tableView.editing && !self.editingFromSwipe
        let indexPath = NSIndexPath(forRow: self.currentWordIndex, inSection: Section.Words.rawValue)
        if self.currentWordIndex == self.lesson.words.count {
            self.lesson.words.append(word)
            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        else {
            self.lesson.words[self.currentWordIndex] = word
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        }
        if self.lesson.isShared() {
            self.lesson.localChangesSinceLastSync = true
        }
        self.delegate?.lessonView(self, didSaveLesson: self.lesson)
        controller.navigationController!.popViewControllerAnimated(true)
    }
    
    func wordDetailController(controller: WordDetailController, canEditWord word: Word) -> Bool {
        return true
    }
    
    func wordDetailController(controller: WordDetailController, canReplyWord word: Word) -> Bool {
        return false
    }
}

extension LessonViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension LessonViewController: MBProgressHUDDelegate {
    func hudWasHidden(hud: MBProgressHUD) {
        self.hud = nil
    }
}