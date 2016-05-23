//
//  DownloadLessonViewController.swift
//  Echo
//
//  Created by William Entriken on 1/11/16.
//
//

import Foundation
import MessageUI
import UIKit
import Firebase
import MBProgressHUD
import AlamofireImage

protocol DownloadLessonDelegate: class {
    func downloadLessonViewController(controller: UIViewController, gotStubLesson lesson: Lesson)
}

class DownloadLessonViewController: UITableViewController {
    weak var delegate: DownloadLessonDelegate?
    var lessons = [Lesson]()

    func populateRowsWithSearch(searchString: String, languageTag tag: String) {
        let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
        networkManager.searchLessonsWithLangTag(tag, andSearhText: searchString, onSuccess: { (lessonPreviews: [Lesson]) -> Void in
            self.lessons = lessonPreviews
            self.tableView.reloadData()
            }) {(error: NSError!) -> Void in
                MBProgressHUD.flashError(error)
        }
    }
}

extension DownloadLessonViewController /*: UIViewController */ {
    override func viewDidLoad() {
        super.viewDidLoad()
        let me: Profile = Profile.currentUser
        self.navigationItem.rightBarButtonItem!.title = me.learningLanguageTag
        self.populateRowsWithSearch("", languageTag: me.learningLanguageTag)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        FIRAnalytics.logEventWithName("page_view", parameters: ["name": NSStringFromClass(self.dynamicType)])
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let destination = segue.destinationViewController as? LanguageSelectController else {
            return
        }
        destination.delegate = self
    }
    
}

extension DownloadLessonViewController /*: UITableViewDataSource */ {
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row < self.lessons.count {
            return 69
        }
        else {
            return tableView.rowHeight
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lessons.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == self.lessons.count {
            return tableView.dequeueReusableCellWithIdentifier("request", forIndexPath: indexPath)
        }
        let lesson: Lesson = (self.lessons)[indexPath.row]
        let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("lesson", forIndexPath: indexPath)
        (cell.viewWithTag(1) as! UILabel).text = lesson.name
        (cell.viewWithTag(2) as! UILabel).text = lesson.detail
        let dateFormatter: NSDateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .NoStyle
        let date = NSDate(timeIntervalSince1970: Double(lesson.serverTimeOfLastCompletedSync))
        let formattedDateString: String = dateFormatter.stringFromDate(date)
        (cell.viewWithTag(3) as! UILabel).text = formattedDateString
        if lesson.numLikes > 0 {
            (cell.viewWithTag(4) as! UILabel).text = "\(Int(lesson.numLikes))"
            (cell.viewWithTag(7) as! UIImageView).hidden = false
        } else {
            (cell.viewWithTag(4) as! UILabel).text = ""
            (cell.viewWithTag(7) as! UIImageView).hidden = true
        }
        if lesson.numFlags > 0 {
            (cell.viewWithTag(5) as! UILabel).text = "\(Int(lesson.numFlags))"
            (cell.viewWithTag(8) as! UIImageView).hidden = false
        } else {
            (cell.viewWithTag(5) as! UILabel).text = ""
            (cell.viewWithTag(8) as! UIImageView).hidden = true
        }
        (cell.viewWithTag(6) as! UILabel).text = lesson.userName
        let placeholderImage = UIImage(named: "user")!
        let userPhotoUrl = networkManager.photoURLForUserWithID(lesson.userID)
        (cell.viewWithTag(9) as! UIImageView).af_setImageWithURL(
            userPhotoUrl,
            placeholderImage: placeholderImage,
            filter: nil,
            imageTransition: .CrossDissolve(0.2)
        )
        return cell
    }
}

extension DownloadLessonViewController /*: UITableViewDelegate*/ {
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < self.lessons.count {
            self.delegate!.downloadLessonViewController(self, gotStubLesson: (self.lessons)[indexPath.row])
            FIRAnalytics.logEventWithName("learning", parameters: ["action": "Download Lesson"])
        }
        else {
            if MFMailComposeViewController.canSendMail() {
                let picker = MFMailComposeViewController()
                picker.mailComposeDelegate = self
                picker.setSubject("Idea for Echo lesson/\(self.navigationItem.rightBarButtonItem!.title)")
                picker.setToRecipients(["echo@phor.net"])
                picker.setMessageBody("(TYPE YOUR IDEA IN HERE)", isHTML: false)
                self.presentViewController(picker, animated: true, completion: nil)
            }
        }
    }
   
}

extension DownloadLessonViewController: LanguageSelectControllerDelegate {
    func languageSelectController(controller: AnyObject, didSelectLanguage tag: String, withNativeName name: String) {
        self.populateRowsWithSearch("", languageTag: tag)
        self.navigationItem.rightBarButtonItem!.title = tag
        self.navigationController!.popToViewController(self, animated: true)
    }
}

extension DownloadLessonViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        self.dismissViewControllerAnimated(true, completion: { _ in })
    }
}