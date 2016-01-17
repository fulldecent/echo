//
//  NetworkManager.swift
//  Echo
//
//  Created by William Entriken on 1/13/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import AFNetworking
import MBProgressHUD
import Alamofire

//TODO use NSProgress for all progress blocks
// http://oleb.net/blog/2014/03/nsprogress/

// V2.0 API ///////////////////////////////////////////////////////
//	GET		audio/2528.caf
//	DELETE	events/125[.json]
//	POST	events/feedbackLesson/125/
//	GET		events/eventsTargetingMe/?[since_id=ID][max_id=ID]
//	GET		events/eventsIMayBeInterestedIn/?[since_id=ID][max_id=ID]
//	DELETE	lessons/172[.json]
//	GET		lessons/175.json[?preview=yes]
//	GET		lessons/fr/[?search=bonjour]
//	POST	lessons/
//	PUT		lessons/LESSONCODE/words/WORDCODE/files/FILECODE[.m4a]
//	GET		users/172.png
//	GET		users/172.json
//	POST	users/
//	GET		users/me/updates?lastLessonSeen=172&lastMessageSeen=229&lessonIDs[]=170&lessonIDs=171&lessonTimestamps[]=1635666&...
//	PUT		users/me/likesLessons/175 (DEPRECATED IN 1.0.15)
//	DELETE	users/me/likesLessons/175 (DEPRECATED IN 1.0.15)
//	PUT		users/me/flagsLessons/175
//	GET		words/824.json
//	DELETE	words/[practice/]166[.json]
//	POST	words/practice/
//	POST	words/practice/225
//	POST	words/practice/225/replies/


class NetworkManager {
    private let SERVER_ECHO_API_URL = "https://learnwithecho.com/api/2.0/"
    private let BASE_URL = NSURL(string: "https://learnwithecho.com/api/2.0/")!
    
    enum FlagReason : Int {
        case InappropriateTitle
        case InaccurateContent
        case PoorQuality
    }

    struct MissingFile {
        let wordUUID: String
        let audioUUID: String
    }
    
    static var sharedNetworkManager: NetworkManager = {
        return NetworkManager()
    }()
    
    lazy var usercode = Profile.currentUser.usercode
    
    private lazy var sessionManager: AFHTTPSessionManager = {
        let retval = AFHTTPSessionManager(baseURL: NSURL(string: self.SERVER_ECHO_API_URL))
        let authenticateRequests = AFJSONRequestSerializer()
        authenticateRequests.setAuthorizationHeaderFieldWithUsername("xxx", password: self.usercode)
        retval.requestSerializer = authenticateRequests
        return retval
    }()
    
    // THIS IS THE FUTURE
    private let alamoManager: Alamofire.Manager = {
        let user = "david"
        let password = "framework"
        let credentialData = "\(user):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        var headers = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        headers["Authorization"] = "Basic \(base64Credentials)"
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = headers
        return Alamofire.Manager(configuration: configuration)
    }()
    
    // PUBLIC API
    
    func deleteLessonWithID(serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "lessons/\(serverId)"
        sessionManager.DELETE(relativePath, parameters: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            successBlock?()
        }, failure: {
            (_, error: NSError) -> Void in
            failureBlock?(error: error)
        })
    }
    
    func getLessonWithID(serverId: Int, asPreviewOnly preview: Bool, onSuccess successBlock: ((lesson: Lesson) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String
        if preview {
            relativePath = "lessons/\(serverId).json?preview=yes"
        } else {
            relativePath = "lessons/\(serverId).json"
        }
        sessionManager.GET(relativePath, parameters: nil, progress: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            if let responseHash = responseObject as? [String: AnyObject] {
                successBlock?(lesson: Lesson(packed: responseHash))
            }
        }, failure: {
            (_, error: NSError) -> Void in
            failureBlock?(error: error)
        })
    }
    
    // THIS IS THE FUTURE
    func getLessonWithID2(serverId: Int, onSuccess successBlock: ((lesson: Lesson) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "lessons/\(serverId).json", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.GET, url).responseJSON() {
            response in
            switch response.result {
            case .Success(let JSON as [String: AnyObject]):
                let lesson = Lesson(packed: JSON)
                successBlock?(lesson: lesson)
            case .Failure(let error):
                failureBlock?(error: error)
            default:
                failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
            }
        }
    }
    
    func searchLessonsWithLangTag(langTag: String, andSearhText searchText: String, onSuccess successBlock: ((lessonPreviews: [Lesson]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "lessons/\(langTag)/?search=\(searchText)"
        sessionManager.GET(relativePath, parameters: nil, progress: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            var lessons = [Lesson]()
            for item: AnyObject in responseObject as! [AnyObject] {
                lessons.append(Lesson(packed: item as! [String : AnyObject]))
            }
            successBlock?(lessonPreviews: lessons)
        }, failure: {
            (_, error: NSError) -> Void in
            failureBlock?(error: error)
        })
    }
    
    func postLesson(lesson: Lesson, onSuccess successBlock: ((newLessonID: Int, newServerVersion: Int, neededWordAndFileCodes: [MissingFile]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        sessionManager.POST("lessons/", parameters: nil, progress: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            guard responseObject is [String: AnyObject] else {
                return
            }
            guard let serverId = responseObject?["lessonID"] as? Int else {
                return
            }
            guard let updated = responseObject?["updated"] as? Int else {
                return
            }
            guard let neededFiles = responseObject?["neededFiles"] as? [[String: String]] else {
                return
            }
            var neededFileStructs = [MissingFile]()
            for neededFile in neededFiles {
                guard let wordUUID = neededFile["wordCode"] else {
                    return
                }
                guard let audioUUID = neededFile["fileCode"] else {
                    return
                }
                neededFileStructs.append(MissingFile(wordUUID: wordUUID, audioUUID: audioUUID))
            }
            successBlock?(newLessonID: serverId, newServerVersion: updated, neededWordAndFileCodes: neededFileStructs)
            }, failure: {
                (_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    //TODO: should only accept one Audio
    //  requires guaranteeing that Audio has Word and Word has lesson
    //  need to remove empty initializers for Audio and Word which do not have parents
    //Progress callback is called on the session queue
    func putAudioFileAtPath(filePath: String, forLesson lesson: Lesson, withWord word: Word, usingCode code: String, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "lessons/\(lesson.uuid)/words/\(word.uuid)/files/\(code).caf"
        let URL = NSURL(string: relativePath, relativeToURL: self.BASE_URL)!
        let request = NSURLRequest(URL: URL)
        let localFileURL = NSURL(string: filePath)!
        let uploadTask = sessionManager.uploadTaskWithRequest(request, fromFile: localFileURL, progress: {
            progress in
            if progress.totalUnitCount > 0 {
                progressBlock?(progress: Float(progress.fractionCompleted))
            }
        }, completionHandler: {
            response, path, error in
            guard error == nil else {
                failureBlock?(error: error!)
                return
            }
        })
        uploadTask.resume()
    }
    
    func photoURLForUserWithID(userID: Int) -> NSURL {
        let relativeURL: String = "users/\(userID).png"
        return NSURL(string: relativeURL, relativeToURL: BASE_URL)!
    }
    
    func postUserProfile(profile: Profile, onSuccess successBlock: ((username: String, userId: Int, recommendedLessons: [Lesson]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let JSONDict: [String : AnyObject] = Profile.currentUser.toDictionary()
        sessionManager.POST("users", parameters: JSONDict, progress: nil, success: {(_, responseObject: AnyObject?) -> Void in
            guard responseObject is [String : AnyObject] else {
                return
            }
            guard let username = responseObject?["username"] as? String else {
                return
            }
            guard let userId = responseObject?["userID"] as? Int else {
                return
            }
            guard let recommendedLessonJsonTexts = responseObject?["recommendedLessons"] as? [[String : AnyObject]] else {
                return
            }
            var recommendedLessons = [Lesson]()
            for recommendedLessonJsonText in recommendedLessonJsonTexts {
                recommendedLessons.append(Lesson(packed: recommendedLessonJsonText))
            }
            successBlock?(username: username, userId: userId, recommendedLessons: recommendedLessons)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    func getUpdatesForLessons(lessons: [Lesson], newLessonsSinceID serverId: Int, messagesSinceID messageID: Int, onSuccess successBlock: ((updatedLessonIds: [Int], numNewLessons: Int, numNewMessages: Int) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        var lessonIDsToCheck = [Int]()
        var lessonTimestampsToCheck: [AnyObject] = [AnyObject]()
        for lesson in lessons {
            guard lesson.serverId != 0 else {
                continue
            }
            lessonIDsToCheck.append(lesson.serverId)
            if lesson.serverTimeOfLastCompletedSync != 0 {
                lessonTimestampsToCheck.append(lesson.serverTimeOfLastCompletedSync)
            }
            else {
                lessonTimestampsToCheck.append(0)
            }
        }
        let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        var requestParams: [NSObject : AnyObject] = [NSObject : AnyObject]()
        requestParams["lessonIDs"] = lessonIDsToCheck
        requestParams["lessonTimestamps"] = lessonTimestampsToCheck
        if (defaults.objectForKey("lestLessonSeen") is String) {
            requestParams["lastLessonSeen"] = defaults.objectForKey("lastLessonSeen")
        }
        if (defaults.objectForKey("lastMessageSeen") is String) {
            requestParams["lastMessageSeen"] = defaults.objectForKey("lastMessageSeen")
        }
        let relativePath: String = "users/me/updates"
        sessionManager.GET(relativePath, parameters: requestParams, progress: nil, success: {(_, responseObject: AnyObject?) -> Void in
            guard responseObject is [String : AnyObject] else {
                return
            }
            guard let updatedLessonsWithIds = responseObject?["updatedLessons"] as? [Int : Int] else {
                return
            }
            guard let newLessons = responseObject?["newLessons"] as? Int else {
                return
            }
            guard let unreadMessages = responseObject?["unreadMessages"] as? Int else {
                return
            }
            let updatedLessons = [Int](updatedLessonsWithIds.keys)
            
            successBlock?(updatedLessonIds:updatedLessons, numNewLessons: newLessons, numNewMessages: unreadMessages)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    func doFlagLesson(lesson: Lesson, withReason flagReason: FlagReason, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "users/me/flagsLessons/\(Int(lesson.serverId))"
        let URL = NSURL(string: relativePath, relativeToURL: self.BASE_URL)!
        let request = NSURLRequest(URL: URL)
        let flagString = "\(flagReason)"
        let uploadData = flagString.dataUsingEncoding(NSUTF8StringEncoding)
        let uploadTask = sessionManager.uploadTaskWithRequest(request, fromData: uploadData, progress: nil, completionHandler: {
            response, path, error in
            guard error == nil else {
                failureBlock?(error: error!)
                return
            }
            successBlock?()
        })
        uploadTask.resume()
    }
    
    func getWordWithID(wordID: Int, onSuccess successBlock: ((word: Word) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "words/\(wordID).json"
        sessionManager.GET(relativePath, parameters: nil, progress: nil, success: {(_, responseObject: AnyObject?) -> Void in
            guard let responseJsonObject = responseObject as? [String : AnyObject] else {
                return
            }
            successBlock?(word: Word(packed: responseJsonObject))
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    func postWord(word: Word, AsPracticeWithFilesInPath filePath: String, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        sessionManager.POST("words/practice/", parameters: nil, constructingBodyWithBlock: {
            (formData: AFMultipartFormData) -> Void in
            formData.appendPartWithFormData(word.toJSON()!, name: "word")
            var fileNum: Int = 0
            for file: Audio in word.audios {
                fileNum++
                let fileName: String = "file\(fileNum)"
                let fileData: NSData = NSData(contentsOfURL: file.fileURL()!)!
                formData.appendPartWithFileData(fileData, name: fileName, fileName: fileName, mimeType: "audio/mp4a-latm")
            }
            }, progress: {
                (progress) -> Void in
                if progress.totalUnitCount > 0 {
                    progressBlock?(progress: Float(progress.fractionCompleted))
                }
            }, success: {(_, responseObject: AnyObject?) -> Void in
                progressBlock?(progress: 1)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })
    }
    
    func postWord(word: Word, withFilesInPath filePath: String, asReplyToWordWithID wordID: Int, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "words/practice/\(wordID)/replies/"
        sessionManager.POST(relativePath, parameters: nil, constructingBodyWithBlock: {
            (formData: AFMultipartFormData) -> Void in
            formData.appendPartWithFormData(word.toJSON()!, name: "word")
            var fileNum: Int = 0
            for file: Audio in word.audios {
                fileNum++
                let fileName: String = "file\(fileNum)"
                let fileData: NSData = NSData(contentsOfURL: file.fileURL()!)!
                formData.appendPartWithFileData(fileData, name: fileName, fileName: fileName, mimeType: "audio/mp4a-latm")
            }
            }, progress: {
                (progress) -> Void in
                if progress.totalUnitCount > 0 {
                    progressBlock?(progress: Float(progress.fractionCompleted))
                }
            }, success: {(_, responseObject: AnyObject?) -> Void in
                progressBlock?(progress: 1)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })
    }
    
    func deleteEventWithID(serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "events/\(serverId)"
        sessionManager.DELETE(relativePath, parameters: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            successBlock?()
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    func postFeedback(feedback: String, toAuthorOfLessonWithID serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "events/feedbackLesson/\(serverId)/"
        sessionManager.POST(relativePath, parameters: nil, progress: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            successBlock?()
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    func getEventsTargetingMeOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        sessionManager.GET("events/eventsTargetingMe/", parameters: nil, progress: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            guard responseObject is [[String: AnyObject]] else {
                return
            }
            var events = [Event]()
            if let arrayObject = responseObject as? [[String: AnyObject]] {
                for eventPacked in arrayObject {
                    events.append(Event(packed: eventPacked))
                }
            }
            successBlock?(events: events)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    func getEventsIMayBeInterestedInOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        sessionManager.GET("events/eventsIMayBeInterestedIn/", parameters: nil, progress: nil, success: {(_, responseObject: AnyObject?) -> Void in
            guard responseObject is [[String: AnyObject]] else {
                return
            }
            var events = [Event]()
            if let arrayObject = responseObject as? [[String: AnyObject]] {
                for eventPacked in arrayObject {
                    events.append(Event(packed: eventPacked))
                }
            }
            successBlock?(events: events)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    func pullAudio(audio: Audio, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "audio/\(audio.serverId).caf"
        let URL = NSURL(string: relativePath, relativeToURL: self.BASE_URL)!
        let request = NSURLRequest(URL: URL)
        let localFileURL = audio.fileURL()!
        let task = sessionManager.downloadTaskWithRequest(request, progress: {
            (progress) -> Void in
            if progress.totalUnitCount > 0 {
                progressBlock?(progress: Float(progress.fractionCompleted))
            }
            }, destination: {_, _ in return localFileURL}, completionHandler: {
                response, path, error in
                guard error == nil else {
                    failureBlock?(error: error!)
                    return
                }
        })
        task.resume()
    }
}

//TODO: get this accepted upstream
extension MBProgressHUD {
    static func flashError(error: NSError) {
        let window = UIApplication.sharedApplication().keyWindow
        MBProgressHUD.hideAllHUDsForView(window, animated: false)
        
        let hud = MBProgressHUD(forView: window)
        hud.mode = .CustomView
        hud.removeFromSuperViewOnHide = true

        let view: UITextView = UITextView(frame: CGRectMake(0, 0, 200, 200))
        view.text = error.localizedDescription
        view.font = hud.labelFont
        view.textColor = UIColor.whiteColor()
        view.backgroundColor = UIColor.clearColor()
        view.sizeToFit()
        
        hud.customView = view
        hud.show(true)
        hud.hide(true, afterDelay: 1.2)
    }
}
