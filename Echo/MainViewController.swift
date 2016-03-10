//
//  MainViewController.swift
//  Echo
//
//  Created by William Entriken on 1/10/16.
//
//

import Foundation
import QuartzCore
import UIKit
import MBProgressHUD
import Google
import TDBadgedCell


class MainViewController: UITableViewController {
    var lessonSet = LessonSet(name: "downloadsAndUploads")
    var practiceSet = LessonSet(name: "practiceLessons")
    var myEvents = [Event]()
    var otherEvents = [Event]()
    var hud: MBProgressHUD? = nil
    var currentLesson: Lesson? = nil // should not be necessary
    var currentWord: Word? = nil // should not be necessary
    
    @IBAction func reload() {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let networkManager = NetworkManager.sharedNetworkManager
        let lastUpdateLesson: Int = defaults.integerForKey("lastUpdateLessonList")
        let lastUpdateMessage: Int = defaults.integerForKey("lastMessageSeen")
        networkManager.getUpdatesForLessons(self.lessonSet.lessons, newLessonsSinceID: lastUpdateLesson, messagesSinceID: lastUpdateMessage, onSuccess: {
            (updatedLessonIds, numNewLessons, numNewMessages) -> Void in
            self.lessonSet.setRemoteUpdatesForLessonsWithIDs(updatedLessonIds)
            defaults.setInteger(numNewLessons, forKey: "numNewLessons")
            defaults.setInteger(numNewMessages, forKey: "numNewMessages")
            defaults.setInteger(Int(NSDate().timeIntervalSince1970), forKey: "lastUpdateLessonList")
            
            self.tableView.performSelectorOnMainThread("reloadData", withObject: nil, waitUntilDone: false)
            self.refreshControl?.endRefreshing()
            UIApplication.sharedApplication().applicationIconBadgeNumber = numNewMessages
            self.lessonSet.syncStaleLessonsWithProgress({(lesson: Lesson, progress: Float) -> Void in
                if let path = self.indexPathForLesson(lesson) {
                    self.tableView.reloadRowsAtIndexPaths([path], withRowAnimation: .None)
                }
            })
            }, onFailure: {
            (error: NSError) -> Void in
            self.refreshControl?.endRefreshing()
            MBProgressHUD.flashError(error)
            }
        )
        networkManager.getEventsIMayBeInterestedInOnSuccess({
            (events) -> Void in
            self.otherEvents = events
            self.tableView.reloadSections(NSIndexSet(index: Section.Social.rawValue), withRowAnimation: .Automatic)
            }, onFailure: nil
        )
        networkManager.getEventsTargetingMeOnSuccess({
            (events) -> Void in
            self.myEvents = events
            self.tableView.reloadSections(NSIndexSet(index: Section.Practice.rawValue), withRowAnimation: .Automatic)
            }, onFailure: nil
        )
    }
}

extension MainViewController /*: UIViewController */ {
    override func viewDidLoad() {
        super.viewDidLoad()        
        //TODO: check if this is still needed
        self.tableView.contentInset = UIEdgeInsetsMake(20, self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController!.setNavigationBarHidden(true, animated: animated)
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "MainView")
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject: AnyObject])

        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let lastUpdateLessonList = defaults.objectForKey("lastUpdateLessonList") as? NSDate
        if lastUpdateLessonList == nil || lastUpdateLessonList!.timeIntervalSinceNow < -5 * 60 {
            self.reload()
        }
        super.viewWillAppear(true)
        //   self.refreshControl.layer.zPosition = self.tableView.backgroundView.layer.zPosition + 1;
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let me: Profile = Profile.currentUser
        if me.learningLanguageTag == "" {
            self.performSegueWithIdentifier("intro", sender: self)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController!.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MainViewController /*: UITableViewController, UITableViewDelegate, UITableViewDataSource */ {
    enum Section: Int {
        case Practice
        case Lessons
        case Social
    }
    
    enum CellType {
        case Lesson
        case LessonEditable
        case LessonDownload
        case LessonUpload
        case DownloadLesson
        case CreateLesson
        case NewPractice
        case EditProfile
        case Event
    }
    
    func cellTypeForRowAtIndexPath(indexPath: NSIndexPath) -> CellType {
        switch Section(rawValue: indexPath.section)! {
        case .Lessons:
            if indexPath.row == 0 {
                return .DownloadLesson
            }
            if indexPath.row == 1 {
                return .CreateLesson
            }
            let lesson = self.lessonForRowAtIndexPath(indexPath)!
            if self.lessonSet.lessonTransferProgress[lesson] != nil {
                if lesson.localChangesSinceLastSync {
                    return .LessonUpload
                } else {
                    return .LessonDownload
                }
            }
            else if lesson.isByCurrentUser() {
                return .LessonEditable
            }
            else {
                return .Lesson
            }
        case .Practice:
            if indexPath.row == 0 {
                return .EditProfile
            }
            else if indexPath.row == 1 {
                return .NewPractice
            }
            else {
                return .Event
            }
        case .Social:
            return .Event
        }
    }
    
    func lessonForRowAtIndexPath(indexPath: NSIndexPath) -> Lesson? {
        guard Section(rawValue: indexPath.section) == .Lessons else {
            return nil
        }
        guard indexPath.row > 1 && indexPath.row < self.lessonSet.lessons.count + 2 else {
            return nil
        }
        return (self.lessonSet.lessons)[indexPath.row - 2]
    }
    
    func indexPathForLesson(lesson: Lesson) -> NSIndexPath? {
        if let index = self.lessonSet.lessons.indexOf(lesson) {
            return NSIndexPath(forRow: index + 2, inSection: Int(Section.Lessons.rawValue))
        }
        return nil
    }
    
    func eventForRowAtIndexPath(indexPath: NSIndexPath) -> Event? {
        if Section(rawValue: indexPath.section) == .Practice {
            return (self.myEvents)[indexPath.row - 2]
        }
        else if Section(rawValue: indexPath.section) == .Social {
            return (self.otherEvents)[indexPath.row]
        }
        return nil
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .Lessons:
            return self.lessonSet.lessons.count + 2
        case .Practice:
            return self.myEvents.count + 2
        case .Social:
            return self.otherEvents.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch self.cellTypeForRowAtIndexPath(indexPath) {
        case .Lesson:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("lesson") as! TDBadgedCell
            let lesson = self.lessonForRowAtIndexPath(indexPath)!
            cell.textLabel!.text = lesson.name
            cell.detailTextLabel!.text = lesson.detail
            switch lesson.portionComplete() {
            case 0:
                cell.badgeString = "New"
            case 1:
                cell.badgeString = nil
            default:
                cell.badgeString = "\(Int(Float(100) * lesson.portionComplete()))%% done"
            }
            return cell
        case .LessonEditable:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("lessonEditable")!
            let lesson = self.lessonForRowAtIndexPath(indexPath)!
            cell.textLabel!.text = lesson.name
            if lesson.isShared() {
                cell.detailTextLabel!.text = "Shared online"
            }
            else {
                cell.detailTextLabel!.text = "Not yet shared online"
            }
            return cell
        case .LessonDownload:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("lessonDownload")!
            let lesson = self.lessonForRowAtIndexPath(indexPath)!
            cell.textLabel!.text = lesson.name
            let percent: Float = self.lessonSet.lessonTransferProgress[lesson]!
            cell.detailTextLabel!.text = "Downloading – \(Int(percent * 100))%%"
            return cell
        case .LessonUpload:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("lessonUpload")!
            let lesson = self.lessonForRowAtIndexPath(indexPath)!
            cell.textLabel!.text = lesson.name
            let percent: Float = self.lessonSet.lessonTransferProgress[lesson]!
            cell.detailTextLabel!.text = "Uploading – \(Int(percent * 100))%%"
            return cell
        case .DownloadLesson:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("downloadLesson") as! TDBadgedCell
            let me: Profile = Profile.currentUser
            let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
            cell.detailTextLabel!.text = "New \(Languages.nativeDescriptionForLanguage(me.learningLanguageTag)) lesson"
            cell.badgeString = nil
            if let count = defaults.objectForKey("newLessonCount") as? Int {
                if count > 0 {
                    cell.badgeString = defaults.objectForKey("newLessonCount")!.stringValue
                    cell.badgeRightOffset = 8
                }
            }
            return cell
        case .CreateLesson:
            return self.tableView.dequeueReusableCellWithIdentifier("createLesson")!
        case .NewPractice:
            return self.tableView.dequeueReusableCellWithIdentifier("newPractice")!
        case .EditProfile:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("editProfile") as! TDBadgedCell
            let me: Profile = Profile.currentUser
            cell.textLabel!.text = me.username
            switch me.profileCompleteness() {
            case 1.0:
                cell.badgeString = nil
            default:
                cell.badgeString = "\(Int(me.profileCompleteness() * 100))% done"
            }
            return cell
        case .Event:
            let cell = self.tableView.dequeueReusableCellWithIdentifier("social")!
            let event = self.eventForRowAtIndexPath(indexPath)!
            cell.selectionStyle = event.eventType == .PostPractice ? .Default : .None
            let dateFormatter: NSDateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .MediumStyle
            dateFormatter.timeStyle = .NoStyle
            let date: NSDate = NSDate(timeIntervalSince1970: event.timestamp)
            let formattedDateString: String = dateFormatter.stringFromDate(date)
            cell.detailTextLabel!.text = formattedDateString
            cell.detailTextLabel!.text = "\(event.actingUserName) / \(formattedDateString)"
            let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
            let placeholder = UIImage(named: "none40")!
            let userPhoto: NSURL = networkManager.photoURLForUserWithID(event.actingUserID)
            let request: NSMutableURLRequest = NSMutableURLRequest(URL: userPhoto)
            cell.imageView!.setImageWithURLRequest(request, placeholderImage: placeholder, success: nil, failure: nil)
            cell.textLabel!.text = event.htmlDescription
            cell.textLabel!.text = event.targetWordName
            cell.accessoryType = event.eventType == .PostPractice ? .DisclosureIndicator : .None
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var lesson: Lesson
        switch self.cellTypeForRowAtIndexPath(indexPath) {
        case .Lesson, .LessonEditable:
            lesson = self.lessonForRowAtIndexPath(indexPath)!
            self.currentLesson = lesson
            self.performSegueWithIdentifier("lesson", sender: self)
        case .LessonDownload, .LessonUpload, .DownloadLesson, .CreateLesson, .NewPractice, .EditProfile:
            break
        case .Event:
            let event: Event = self.eventForRowAtIndexPath(indexPath)!
            let practiceID: Int = event.targetWordID
            if event.eventType != .PostPractice {
                return
            }
            let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true)
            hud.mode = .Indeterminate
            self.hud = hud
            LessonSet.getWordWithFiles(practiceID, withProgress: {
                (word: Word, progress: Float) -> Void in
                hud.mode = .AnnularDeterminate
                hud.progress = progress
                if progress == 1.0 {
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let controller: WordDetailController = storyboard.instantiateViewControllerWithIdentifier("WordDetailController") as! WordDetailController
                    self.currentWord = word
                    controller.word = word
                    controller.delegate = self
                    self.navigationController!.pushViewController(controller, animated: true)
                    hud.hide(true)
                }
                }, onFailure: {(error: NSError) -> Void in
                    hud.hide(true)
                    MBProgressHUD.flashError(error)
            })
            
        }
        
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        self.currentLesson = self.lessonForRowAtIndexPath(indexPath)
        self.performSegueWithIdentifier("lessonInformation", sender: self)
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if (self.lessonForRowAtIndexPath(indexPath) != nil) {
            return .Delete
        }
        else {
            return .None
        }
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        self.currentLesson = self.lessonForRowAtIndexPath(indexPath)!
        if self.currentLesson!.isByCurrentUser() && self.currentLesson!.isShared() {
            let message: String = "You are deleting this lesson from your device. Would you like to continue sharing online?"
            let alert = UIAlertController(title: "Delete", message: message, preferredStyle: UIAlertControllerStyle.ActionSheet)
            alert.addAction(UIAlertAction(title: "Continue sharing", style: .Default, handler: {
                (UIAlertAction) -> Void in
                self.lessonSet.deleteLesson(self.currentLesson!)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }))
            alert.addAction(UIAlertAction(title: "Stop sharing", style: .Destructive, handler: {
                (UIAlertAction) -> Void in
                self.lessonSet.deleteLessonAndStopSharing(self.currentLesson!, onSuccess: {
                    () -> Void in
                    self.lessonSet.deleteLesson(self.currentLesson!)
                    self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    }, onFailure: {(error: NSError) -> Void in
                        MBProgressHUD.flashError(error)
                })
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            self.lessonSet.deleteLesson(self.lessonForRowAtIndexPath(indexPath)!)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            self.currentLesson = nil
        }
    }
}

extension MainViewController /*: UIViewController*/ {
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.destinationViewController {
        case is LessonViewController:
            let controller = segue.destinationViewController as! LessonViewController
            controller.lesson = self.currentLesson
            controller.delegate = self
            if (segue.identifier == "createLesson") {
                let me: Profile = Profile.currentUser
                let lesson: Lesson = Lesson()
                lesson.languageTag = me.nativeLanguageTag
                lesson.userID = me.userID
                lesson.userName = me.username
                controller.lesson = lesson
            }
        case is IntroViewController:
            let controller = segue.destinationViewController as! IntroViewController
            controller.delegate = self
        case is DownloadLessonViewController:
            let controller = segue.destinationViewController as! DownloadLessonViewController
            controller.delegate = self
        case is ProfileViewController:
            let controller = segue.destinationViewController as! ProfileViewController
            controller.profile = Profile.currentUser
            controller.delegate = self
        case is WordDetailController:
            let controller = segue.destinationViewController as! WordDetailController
            let me: Profile = Profile.currentUser
            controller.delegate = self
            self.currentLesson = Lesson()
            let word: Word = Word()
            word.languageTag = me.learningLanguageTag
            controller.word = word
            let newButton = UIBarButtonItem(barButtonSystemItem: .Done, target: controller.navigationItem.rightBarButtonItem!.target, action: controller.navigationItem.rightBarButtonItem!.action)
            controller.navigationItem.rightBarButtonItem = newButton
            controller.actionButton = newButton
            controller.validate()
        default:
            break
        }
    }
}

extension MainViewController: LessonViewDelegate {
    func lessonView(controller: LessonViewController, didSaveLesson lesson: Lesson) {
        self.lessonSet.addOrUpdateLesson(lesson)
        self.tableView.reloadData()
    }
    
    func lessonView(controller: LessonViewController, wantsToUploadLesson lesson: Lesson) {
        self.lessonSet.syncStaleLessonsWithProgress({
            (lesson: Lesson, progress: Float) -> Void in
            let indexPath = self.indexPathForLesson(lesson)!
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        })
        self.navigationController!.popToRootViewControllerAnimated(true)
    }
    
    func lessonView(controller: LessonViewController, wantsToDeleteLesson lesson: Lesson) {
        self.lessonSet.deleteLesson(lesson)
        self.tableView.reloadData()
    }
}

extension MainViewController: DownloadLessonDelegate {
    func downloadLessonViewController(controller: UIViewController, gotStubLesson lesson: Lesson) {
        NSLog("GOT STUB LESSON: %ld", Int(lesson.serverId))
        NSLog("%@", NSThread.callStackSymbols())
        lesson.remoteChangesSinceLastSync = true
        self.lessonSet.addOrUpdateLesson(lesson)
        // may or may not add a row
        self.tableView.reloadSections(NSIndexSet(index: Section.Lessons.rawValue), withRowAnimation: .Automatic)
        self.lessonSet.syncStaleLessonsWithProgress({
            (lesson: Lesson, progress: Float) -> Void in
            if let indexPath = self.indexPathForLesson(lesson) {
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)                
            }
        })
        self.navigationController!.popToRootViewControllerAnimated(true)
    }
}

extension MainViewController: WordDetailDelegate {
    func wordDetailController(controller: WordDetailController, didSaveWord word: Word) {
        let hud = MBProgressHUD.showHUDAddedTo(controller.view!, animated: true)
        hud.mode = .Indeterminate
        hud.labelText = "Sending..."
        self.hud = hud
        let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
        networkManager.postWord(word, AsPracticeWithFilesInPath: NSTemporaryDirectory(), withProgress: {
            (progress: Float) -> Void in
            hud.mode = .AnnularDeterminate
            hud.progress = progress
            NSLog("How do I say: upload progress %@", progress)
            if progress == 1.0 {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let newController = storyboard.instantiateViewControllerWithIdentifier("WordDetailController") as! WordDetailController
                newController.delegate = self
                newController.word = ((self.practiceSet.lessons)[0] ).words[0]
                // http://stackoverflow.com/questions/9411271/how-to-perform-uikit-call-on-mainthread-from-inside-a-block
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    controller.navigationController!.popViewControllerAnimated(false)
                    self.navigationController!.pushViewController(newController, animated: true)
                })
                NSLog("saved practice word")
            }
            }, onFailure: {(error: NSError) -> Void in
                hud.hide(false)
                MBProgressHUD.flashError(error)
        })
    }
    
    func wordDetailController(controller: WordDetailController, canEditWord word: Word) -> Bool {
        return !word.name.isEmpty
        // edit new, virgin word
    }
    
    func wordDetailController(controller: WordDetailController, canReplyWord word: Word) -> Bool {
        return true
    }
}

extension MainViewController: WordPracticeDelegate {
    func currentWordForWordPractice(wordPractice: WordPracticeController) -> Word {
        return self.currentWord!
    }
    
    func wordCheckedStateForWordPractice(wordPractice: WordPracticeController) -> Bool {
        return false
    }
    
    func skipToNextWordForWordPractice(wordPractice: WordPracticeController) {
    }
    
    func currentWordCanBeCheckedForWordPractice(wordPractice: WordPracticeController) -> Bool {
        return false
    }
    
    func wordPractice(wordPractice: WordPracticeController, setWordCheckedState state: Bool) {
    }
    
    func wordPracticeShouldShowNextButton(wordPractice: WordPracticeController) -> Bool {
        return false
    }
}
