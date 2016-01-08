//
//  Profile.swift
//  Echo
//
//  Created by William Entriken on 1/6/16.
//
//

import Foundation

class Profile: NSObject {
    
    //TODO: rename these and make optional
    var userID: Int = 0
    var username: String = ""
    lazy var usercode: String  = {
        return UIDevice.currentDevice().identifierForVendor!.UUIDString
    }()
    var learningLanguageTag: String = ""
    var nativeLanguageTag: String = ""
    var location: String = ""
    var photo: UIImage = UIImage()
    var deviceToken: String = ""
    
    static var currentUser: Profile = {
        let retval: Profile = Profile();
        var needToSync: Bool = false
        var defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let storedProfile = defaults.objectForKey("userProfile") as? [String : AnyObject] ?? [String : AnyObject]()
        if let username = storedProfile["username"] as? String {
            retval.username = username
        } else {
            //TODO make this lazy variable?
            retval.username = "user\(arc4random() % 1000000)"
            needToSync = true
        }
        if let userCode = storedProfile["usercode"] as? String {
            retval.usercode = userCode
        } else {
            needToSync = true
        }
        if let userID = storedProfile["userID"] as? Int {
            retval.userID = userID
        }
        if let learningLanguageTag = storedProfile["learningLanguageTag"] as? String {
            retval.learningLanguageTag = learningLanguageTag
        }
        if let nativeLanguageTag = storedProfile["nativeLanguageTag"] as? String {
            retval.nativeLanguageTag = nativeLanguageTag
        }
        if let location = storedProfile["location"] as? String {
            retval.location = location
        }
        if let photo = storedProfile["photo"] as? String {
            retval.photo = UIImage(imageLiteral: photo)
        }
        if needToSync {
            retval.syncToDisk()
        }
        return retval
    }()
    
    //TODO: temp hack to fix compiler bug
    static func currentUserProfile() -> Profile {
        return Profile.currentUser
    }
    
    override init() {
        super.init()
    }
    
    func syncOnlineOnSuccess(success: (recommendedLessons: [AnyObject]) -> Void, onFailure failure: (error: NSError) -> Void) {
        assert(self.usercode != "", "Can only sync current user's profile")
        let networkManager: NetworkManager = NetworkManager.sharedNetworkManager()
        networkManager.postUserProfile(self, onSuccess: { (username: String!, userID: NSNumber!, recommendedLessons: [AnyObject]!) -> Void in
            self.username = username
            self.userID = userID.integerValue
            self.syncToDisk()
            success(recommendedLessons: recommendedLessons)
        }) { (error: NSError!) -> Void in
            failure(error: error)
        }
    }
    
    func syncToDisk() {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(self.toDictionary(), forKey: "userProfile")
        defaults.synchronize()
    }
    
    func profileCompleteness() -> Float {
        let denominator: Float = 5
        var numerator: Float = 0
        if self.username.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            numerator++
        }
        if self.learningLanguageTag.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            numerator++
        }
        if self.nativeLanguageTag.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            numerator++
        }
        if self.location.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            numerator++
        }
        /*
        TODO: after this is optional then check this
        if self.photo != nil {
            numerator++
        }
        */
        return numerator / denominator
    }
    // http://stackoverflow.com/questions/1282830/uiimagepickercontroller-uiimage-memory-and-more
    
    //TODO: ERROR, THIS CRASHES THE APP
    private class func imageWithImage(image: UIImage, scaledToSizeWithSameAspectRatio targetSize: CGSize) -> UIImage {
        let targetDiag = sqrt(targetSize.height*targetSize.height + targetSize.width*targetSize.width)
        let currentDiag = sqrt(image.size.height*image.size.height + image.size.width*image.size.width)
        let scale = targetDiag / currentDiag
        let newHeight = image.size.height * scale
        let newWidth = image.size.width * scale
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func toDictionary() -> [String : AnyObject] {
        var retval = [String : AnyObject]()
        retval["username"] = username
        retval["usercode"] = usercode
        retval["learningLanguageTag"] = learningLanguageTag
        retval["nativeLanguageTag"] = nativeLanguageTag
        retval["location"] = location
        retval["deviceToken"] = deviceToken
        let thumbnail = Profile.imageWithImage(photo, scaledToSizeWithSameAspectRatio: CGSizeMake(100, 100))
        let jpegData = UIImageJPEGRepresentation(thumbnail, 0.8)
        //TODO the modification should happen when SAVING the photo not here
        retval["photo"] = jpegData?.base64EncodedStringWithOptions(.Encoding76CharacterLineLength)
        return retval
    }
    
    func toJSON() -> NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(self.toDictionary(), options: [])
    }
}