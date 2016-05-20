//
//  ProfileViewController.swift
//  Echo
//
//  Created by William Entriken on 1/8/16.
//
//

import Foundation
import CoreLocation
import UIKit
import FDTake
import MBProgressHUD
import Google

class ProfileViewController: UITableViewController {
    var profile: Profile!

    // UI elements
    @IBOutlet var name: UITextField! = nil
    @IBOutlet var learningLang: UILabel!
    @IBOutlet var nativeLang: UILabel!
    @IBOutlet var photo: UIImageView!
    @IBOutlet var location: UILabel!

    // Controllers
    var hud: MBProgressHUD? = nil
    lazy var locationManager: CLLocationManager = {
        let retval = CLLocationManager()
        retval.delegate = self
        retval.desiredAccuracy = kCLLocationAccuracyKilometer
        retval.distanceFilter = kCLDistanceFilterNone
        return retval
    }()
    lazy var takeController: FDTakeController = {
        let retval = FDTakeController()
        retval.allowsEditing = true
        retval.allowsVideo = false
        retval.didGetPhoto = { (photo, _) in
            self.photo.image = photo
        }
        return retval
    }()
    
    weak var delegate: DownloadLessonDelegate?

    //MARK: - Main

    @IBAction func checkIn(sender: AnyObject) {
        if let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true) {
            hud.mode = .Indeterminate
            hud.labelText = "Getting location"
            self.hud = hud
        }
        locationManager.startUpdatingLocation()
    }
    
    @IBAction func choosePhoto(sender: UIButton) {
        takeController.presentingRect = sender.frame
        takeController.present()
    }
    
    @IBAction func save(sender: AnyObject) {
        let me: Profile = Profile.currentUser
//        me.photo = profile.photo
        me.username = self.name.text!
        me.learningLanguageTag = profile.learningLanguageTag
        me.nativeLanguageTag = profile.nativeLanguageTag
//        if let photoImage = self.photo.image {
//            me.photo = photoImage
//        }
        me.location = self.location.text!
        
        if let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true) {
            hud.mode = .Indeterminate
            hud.labelText = "Sending"
            self.hud = hud
        }
        me.syncOnlineOnSuccess({(recommendedLessons: [Lesson]) -> Void in
            for lesson: Lesson in recommendedLessons {
                self.delegate?.downloadLessonViewController(self, gotStubLesson: lesson)
            }
            self.hud?.hide(true)
            me.syncToDisk()
            self.navigationController!.popViewControllerAnimated(true)
            }, onFailure: {(error: NSError) -> Void in
                self.hud?.hide(false)
                MBProgressHUD.flashError(error)
        })
        let tracker = GAI.sharedInstance().defaultTracker
        let builder = GAIDictionaryBuilder.createEventWithCategory("Usage", action: "Social", label: "Saved profile", value: me.profileCompleteness())
        tracker.send(builder.build() as [NSObject : AnyObject])
    }
    
    //MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cell: FDRightDetailWithTextFieldCell = self.tableView(self.tableView, cellForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0)) as! FDRightDetailWithTextFieldCell
        self.name = cell.textField
        
        let currentUser = Profile.currentUser
        self.profile.username = currentUser.username
        self.profile.learningLanguageTag = currentUser.learningLanguageTag
        self.profile.nativeLanguageTag = currentUser.nativeLanguageTag
        self.profile.location = currentUser.location
//        self.profile.photo = currentUser.photo
        self.name.text = self.profile.username
        self.learningLang.text = self.profile.learningLanguageTag
        self.nativeLang.text = self.profile.nativeLanguageTag
        self.location.text = self.profile.location
//        self.photo.image = self.profile.photo
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "ProfileView")
        tracker.send(GAIDictionaryBuilder.createScreenView().build() as [NSObject: AnyObject])
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let controller = segue.destinationViewController as? LanguageSelectController else {
            return
        }
        if segue.identifier == "chooseLearningLang" {
            controller.navigationItem.title = "Learning language"
        } else /* segue.identifier == "chooseNativeLang" */ {
            controller.navigationItem.title = "Native language"
        }
        controller.delegate = (self as LanguageSelectControllerDelegate)
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.view!.endEditing(true)
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return "Full profile is shared online"
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
//TODO: scrap these two lines and use Storyboard
        if cell.reuseIdentifier == "photo" {
            self.choosePhoto(nil as UIButton!)
        }
        else if cell.reuseIdentifier == "location" {
            self.checkIn(nil as UIButton!)
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }
}

extension ProfileViewController: LanguageSelectControllerDelegate {
    func languageSelectController(controller: AnyObject, didSelectLanguage tag: String, withNativeName name: String) {
//TODO: this is wrong, use a BLOCK to figure out which one we need
        self.learningLang.text = name
        self.profile.learningLanguageTag = tag
        
        self.nativeLang.text = name
        self.profile.nativeLanguageTag = tag
        self.navigationController!.popToViewController(self, animated: true)
    }
}

extension ProfileViewController: CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations[0]
        manager.stopUpdatingLocation()
        self.location.text = String(format: "%+3.2f, %+3.2f", location.coordinate.latitude, location.coordinate.longitude)
        hud?.hide(true)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        hud?.hide(false)
        if let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true) {
            hud.delegate = self
            hud.mode = .Text
            hud.labelText = "Error"
            hud.detailsLabelText = error.localizedDescription
            NSLog("GOT LOCATION ERROR %@", error.localizedDescription)
            self.hud = hud
        }
    }
}

extension ProfileViewController: MBProgressHUDDelegate {
    func hudWasHidden(hud: MBProgressHUD) {
        self.hud = nil
    }
}