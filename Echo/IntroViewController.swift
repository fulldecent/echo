//
//  IntroViewController.swift
//  Echo
//
//  Created by William Entriken on 12/17/15.
//
//

import Foundation
import UIKit
import MBProgressHUD
import Firebase

class IntroViewController: UIViewController, MBProgressHUDDelegate, LanguageSelectControllerDelegate {
    
    weak var delegate: DownloadLessonDelegate?
    weak var hud: MBProgressHUD?
    
    @IBAction func languageButtonClicked(sender: UIButton) {
        if sender.tag == 1 {
            self.saveLanguageWithTag("en")
        }
        if sender.tag == 2 {
            self.saveLanguageWithTag("es")
        }
        if sender.tag == 3 {
            self.saveLanguageWithTag("cmn")
        }
    }
    
    func saveLanguageWithTag(tag: String) {
        let me = Profile.currentUser
        me.learningLanguageTag = tag
        me.syncToDisk()
        let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true)
        hud.mode = MBProgressHUDMode.Indeterminate
        hud.labelText = "Sending..."
        self.hud = hud
        me.syncOnlineOnSuccess({
            (recommendedLessons) -> Void in
            for lesson in recommendedLessons {
                self.delegate?.downloadLessonViewController(self, gotStubLesson: lesson)
            }
            hud.hide(true)
            me.syncToDisk()
            self.dismissViewControllerAnimated(true, completion: nil)

            }) { (error) -> Void in
                hud.hide(false)
                MBProgressHUD.flashError(error)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        FIRAnalytics.logEventWithName("page_view", parameters: ["name": NSStringFromClass(self.dynamicType)])
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let controller = segue.destinationViewController as! LanguageSelectController
        controller.delegate = self
    }
    
    func hudWasHidden(hud: MBProgressHUD) {
        self.hud = nil
    }
    
    func languageSelectController(controller: AnyObject, didSelectLanguage tag: String, withNativeName name: String) {
        self.saveLanguageWithTag(tag)
        controller.dismissAnimated(true)
    }
}