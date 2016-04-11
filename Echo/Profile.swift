//
//  Profile.swift
//  Echo
//
//  Created by William Entriken on 1/6/16.
//
//

import Foundation
import UIKit

enum UserAchievements: String {
    case CompletedProfile = "completed profile"
}

class Profile {
    var userID: Int = 0 //TODO: rename to serverId
    var username = "user\(arc4random() % 1000000)" //TODO: rename to name
    lazy var usercode = UIDevice.currentDevice().identifierForVendor!.UUIDString //TODO: rename to UUID
    var learningLanguageTag = ""
    var nativeLanguageTag = ""
    var location = ""
    var photoJPEG = NSData()
    var achievements = [UserAchievements]()
    
    static var currentUser: Profile = {
        let defaults = NSUserDefaults.standardUserDefaults()
        let profileJSON = defaults.objectForKey("profile") as? String ?? ""
        return Profile(JSONString: profileJSON)!
    }()
    
    //TODO: make this more accurate
    func isMe() -> Bool {
        return true
    }
    
    func syncOnlineOnSuccess(success: (recommendedLessons: [Lesson]) -> Void, onFailure failure: (error: NSError) -> Void) {
        assert(self.usercode != "", "Can only sync current user's profile")
        let networkManager: NetworkManager = NetworkManager.sharedNetworkManager
        networkManager.postUserProfile(self, onSuccess: { (username: String!, userID: Int, recommendedLessons: [Lesson]!) -> Void in
            self.username = username
            self.userID = userID
            self.syncToDisk()
            success(recommendedLessons: recommendedLessons)
        }) { (error: NSError!) -> Void in
            failure(error: error)
        }
    }
    
    func syncToDisk() {
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(self.toDictionary(), forKey: "userProfile")
    }
    
    func profileCompleteness() -> Float {
        let denominator: Float = 5
        var numerator: Float = 0
        if self.username.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            numerator = numerator + 1
        }
        if self.learningLanguageTag.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            numerator = numerator + 1
        }
        if self.nativeLanguageTag.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            numerator = numerator + 1
        }
        if self.location.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            numerator = numerator + 1
        }
        if self.photoJPEG.length > 0 {
            numerator = numerator + 1
        }
        return numerator / denominator
    }
    
    init(packed: [String : AnyObject]) {
        if let username = packed["username"] as? String {
            self.username = username
        }
        if let userCode = packed["userCode"] as? String {
            self.usercode = userCode
        }
        if let userID = packed["userID"] as? Int {
            self.userID = userID
        }
        if let learningLanguageTag = packed["learningLanguageTag"] as? String {
            self.learningLanguageTag = learningLanguageTag
        }
        if let nativeLanguageTag = packed["nativeLanguageTag"] as? String {
            self.nativeLanguageTag = nativeLanguageTag
        }
        if let location = packed["location"] as? String {
            self.location = location
        }
        if let photoJPEG = packed["photoJPEG"] as? String {
            let decodedData = NSData(base64EncodedString: photoJPEG, options: [])
            self.photoJPEG = decodedData!
        }
        if let achievements = packed["achievements"] as? [String] {
            self.achievements = achievements.flatMap({UserAchievements(rawValue: $0)})
        }
    }
    
    convenience init?(JSONString: String) {
        guard let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) else {
            return nil
        }
        let JSONDictionary = try? NSJSONSerialization.JSONObjectWithData(JSONData, options: []) as? [String: AnyObject]
        self.init(packed: (JSONDictionary ?? [String: AnyObject]())!)
    }
    
    func toDictionary() -> [String : AnyObject] {
        var retval = [String : AnyObject]()
        retval["username"] = username
        retval["userCode"] = usercode
        retval["learningLanguageTag"] = learningLanguageTag
        retval["nativeLanguageTag"] = nativeLanguageTag
        retval["location"] = location
        retval["photoJPEG"] = photoJPEG.base64EncodedStringWithOptions([])
        retval["achievements"] = achievements.map({$0.rawValue})
        return retval
    }
    
    func toJSON() -> NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(self.toDictionary(), options: [])
    }
}