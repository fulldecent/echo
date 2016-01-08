//
//  ProfileViewController.swift
//  Echo
//
//  Created by William Entriken on 1/8/16.
//
//

import Foundation
import CoreLocation

//TODO: rename EditProfileViewController
//TODO: add CANCEL button and present as flyover (see Twitter app as example)
class ProfileViewController: UITableViewController {
    // Model
    let editingProfile = Profile()

    // UI elements
    @IBOutlet var name: UITextField! = nil
    @IBOutlet var learningLang: UILabel!
    @IBOutlet var nativeLang: UILabel!
    @IBOutlet var photo: UIImageView!
    @IBOutlet var location: UILabel!
    

    // Controllers
    var hud: MBProgressHUD? = nil
    let locationManager: CLLocationManager = {
        let retval = CLLocationManager()
        retval.delegate = (self as! CLLocationManagerDelegate)
        retval.desiredAccuracy = kCLLocationAccuracyKilometer
        retval.distanceFilter = kCLDistanceFilterNone
        return retval
    }()
    let takeController: FDTakeController = {
        let retval = FDTakeController()
        retval.allowsEditingPhoto = true
        retval.delegate = (self as! FDTakeDelegate)
        return retval
    }()
    
    weak var delegate: DownloadLessonViewControllerDelegate?

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
        takeController.popOverPresentRect = sender.frame
        takeController.takePhotoOrChooseFromLibrary()
    }
    
    @IBAction func save(sender: AnyObject) {
        let me: Profile = Profile.currentUserProfile()
        me.photo = editingProfile.photo
        me.username = self.name.text!
        me.learningLanguageTag = editingProfile.learningLanguageTag
        me.nativeLanguageTag = editingProfile.nativeLanguageTag
        if let photoImage = self.photo.image {
            me.photo = photoImage
        }
        me.location = self.location.text!
        
        if let hud = MBProgressHUD.showHUDAddedTo(self.view!, animated: true) {
            hud.mode = .Indeterminate
            hud.labelText = "Sending"
            self.hud = hud
        }
        me.syncOnlineOnSuccess({(recommendedLessons: [AnyObject]) -> Void in
            //TODO: search and remove ! throughout code
            for lesson: Lesson in recommendedLessons as! [Lesson] {
                self.delegate?.downloadLessonViewController(self, gotStubLesson: lesson)
            }
            self.hud?.hide(true)
            me.syncToDisk()
            self.navigationController!.popViewControllerAnimated(true)
            }, onFailure: {(error: NSError) -> Void in
                self.hud?.hide(false)
                NetworkManager.hudFlashError(error)
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
        
        let currentUser = Profile.currentUserProfile()
        self.editingProfile.username = currentUser.username
        self.editingProfile.learningLanguageTag = currentUser.learningLanguageTag
        self.editingProfile.nativeLanguageTag = currentUser.nativeLanguageTag
        self.editingProfile.location = currentUser.location
        self.editingProfile.photo = currentUser.photo
        self.name.text = self.editingProfile.username
        self.learningLang.text = self.editingProfile.learningLanguageTag
        self.nativeLang.text = self.editingProfile.nativeLanguageTag
        self.location.text = self.editingProfile.location
        self.photo.image = self.editingProfile.photo
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let tracker = GAI.sharedInstance().defaultTracker
        tracker.set(kGAIScreenName, value: "ProfileView")        
        let builder = GAIDictionaryBuilder.createAppView()
        tracker.send(builder.build() as [NSObject : AnyObject])
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
        // fucking nice
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        return "Full profile is shared online"
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath)!
//TODO: scrap these two lines
        if cell.reuseIdentifier == "photo" {
            self.choosePhoto(nil as UIButton!)
        }
        else if cell.reuseIdentifier == "location" {
            self.checkIn(nil as UIButton!)
        }
    }
}

extension ProfileViewController: FDTakeDelegate {
    func takeController(controller: FDTakeController, gotPhoto photo: UIImage, withInfo info: [NSObject : AnyObject]) {
        self.photo.image = photo
    }
}

extension ProfileViewController: LanguageSelectControllerDelegate {
    func languageSelectController(controller: AnyObject, didSelectLanguage tag: String, withNativeName name: String) {
//TODO: this is wrong, use a BLOCK to figure out which one we need
        self.learningLang.text = name
        self.editingProfile.learningLanguageTag = tag
        
        self.nativeLang.text = name
        self.editingProfile.nativeLanguageTag = tag
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
            let view: UITextView = UITextView(frame: CGRectMake(0, 0, 200, 200))
            view.text = error.localizedDescription
            view.font = hud.labelFont
            view.textColor = UIColor.whiteColor()
            view.backgroundColor = UIColor.clearColor()
            view.sizeToFit()
            hud.customView = view
            hud.mode = .CustomView
            hud.hide(true, afterDelay: 2)
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