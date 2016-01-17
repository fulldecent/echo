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

//todo: this should be a static class constant, but not yet supported in swift
let SERVER_ECHO_API_URL = "https://learnwithecho.com/api/2.0/"

//TODO: yes, this violates patterns
var staticHud: MBProgressHUD = {
    let retval = MBProgressHUD(forView: UIApplication.sharedApplication().keyWindow)
    retval.mode = .CustomView
    return retval
}()

class NetworkManager {
    private let BASE_URL = NSURL(string: "https://learnwithecho.com/api/2.0/")!
    
    enum FlagReason : Int {
        case InappropriateTitle
        case InaccurateContent
        case PoorQuality
    }
    
    static var sharedNetworkManager: NetworkManager = {
        return NetworkManager()
    }()
    
    private var requestManager: AFHTTPRequestOperationManager = {
        let me = Profile.currentUser
        let retval = AFHTTPRequestOperationManager(baseURL: NSURL(string: SERVER_ECHO_API_URL))
        let authenticateRequests = AFJSONRequestSerializer()
        authenticateRequests.setAuthorizationHeaderFieldWithUsername("xxx", password: me.usercode)
        retval.requestSerializer = authenticateRequests
        return retval
    }()
    
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
        let request: AFHTTPRequestOperation = self.requestManager.DELETE(relativePath, parameters: nil, success: {(operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
                successBlock?()
            }, failure: {(operation: AFHTTPRequestOperation?, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.start()
    }
    
    //TODO: remove MOD TIME
    func getLessonWithID(serverId: Int, asPreviewOnly preview: Bool, onSuccess successBlock: ((lesson: Lesson, modifiedTime: Int) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String
        if preview {
            relativePath = "lessons/\(serverId).json?preview=yes"
        } else {
            relativePath = "lessons/\(serverId).json"
        }
        let request = requestManager.GET(relativePath, parameters: nil, success: {
            (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            if let responseHash = responseObject as? [String: AnyObject] {
                successBlock?(lesson: Lesson(packed: responseHash), modifiedTime: responseHash["updated"] as! Int)
            }
            }) { (requestOperation: AFHTTPRequestOperation?, error: NSError) -> Void in
                failureBlock?(error: error)
        }
        request!.start()
    }
    
    func getLessonWithID2(serverId: Int, onSuccess successBlock: ((lesson: Lesson) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = self.BASE_URL.URLByAppendingPathComponent("lessons/\(serverId).json")
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
        let request: AFHTTPRequestOperation = self.requestManager.GET(relativePath, parameters: nil, success: {
            (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            var lessons = [Lesson]()
            for item: AnyObject in responseObject as! [AnyObject] {
                lessons.append(Lesson(packed: item as! [String : AnyObject]))
            }
            successBlock?(lessonPreviews: lessons)
            }, failure: {
                (operation: AFHTTPRequestOperation?, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.start()
    }
    
    //todo; [[String: String]] should be a struct
    func postLesson(lesson: Lesson, onSuccess successBlock: ((newLessonID: Int, newServerVersion: Int, neededWordAndFileCodes: [[String: String]]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let request = requestManager.POST("lessons/", parameters: nil, success: {
            (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            guard responseObject is [String: AnyObject] else {
                return
            }
            guard let serverId = responseObject["lessonID"] as? Int else {
                return
            }
            guard let updated = responseObject["updated"] as? Int else {
                return
            }
            guard let neededFiles = responseObject["neededFiles"] as? [[String: String]] else {
                return
            }
            successBlock?(newLessonID: serverId, newServerVersion: updated, neededWordAndFileCodes: neededFiles)
            }, failure: {
                (requestOperation: AFHTTPRequestOperation?, error: NSError) -> Void in
                failureBlock?(error: error)
            })!
        request.start()
    }
    
    //TODO api should not be nested
    func putAudioFileAtPath(filePath: String, forLesson lesson: Lesson, withWord word: Word, usingCode code: String, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "lessons/\(lesson.uuid)/words/\(word.uuid)/files/\(code).caf"
        let request: AFHTTPRequestOperation = self.requestManager.PUT(relativePath, parameters: nil, success: {
            (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            progressBlock?(progress: 1)
            }, failure: {
                (operation: AFHTTPRequestOperation?, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.setUploadProgressBlock({(bytesWritten: UInt, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void in
            if totalBytesExpectedToWrite > 0 {
                progressBlock?(progress: Float(totalBytesWritten) / Float(totalBytesExpectedToWrite))
            }
        })
        request.start()
    }
    
    func photoURLForUserWithID(userID: Int) -> NSURL {
        let relativeURL: String = "users/\(userID).png"
        return NSURL(string: relativeURL, relativeToURL: NSURL(string: SERVER_ECHO_API_URL)!)!
    }
    
    func postUserProfile(profile: Profile, onSuccess successBlock: ((username: String, userId: Int, recommendedLessons: [Lesson]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let JSONDict: [String : AnyObject] = Profile.currentUser.toDictionary()
        let request: AFHTTPRequestOperation = self.requestManager.POST("users", parameters: JSONDict, success: {(operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            guard responseObject is [String : AnyObject] else {
                return
            }
            guard let username = responseObject["username"] as? String else {
                return
            }
            guard let userId = responseObject["userID"] as? Int else {
                return
            }
            guard let recommendedLessonJsonTexts = responseObject["recommendedLessons"] as? [[String : AnyObject]] else {
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
        request.start()
    }
    
    //TODO: I do not need new server versions, just the list of updated lessons
    func getUpdatesForLessons(lessons: [Lesson], newLessonsSinceID serverId: Int, messagesSinceID messageID: Int, onSuccess successBlock: ((lessonsIDsWithNewServerVersions: [Int : Int], numNewLessons: Int, numNewMessages: Int) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
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
        let request: AFHTTPRequestOperation = self.requestManager.GET(relativePath, parameters: requestParams, success: {(operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            guard responseObject is [String : AnyObject] else {
                return
            }
            guard let updatedLessons = responseObject["updatedLessons"] as? [Int : Int] else {
                return
            }
            guard let newLessons = responseObject["newLessons"] as? Int else {
                return
            }
            guard let unreadMessages = responseObject["unreadMessages"] as? Int else {
                return
            }
            successBlock?(lessonsIDsWithNewServerVersions:updatedLessons, numNewLessons: newLessons, numNewMessages: unreadMessages)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.start()
    }
    
    func doFlagLesson(lesson: Lesson, withReason flagReason: FlagReason, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "users/me/flagsLessons/\(Int(lesson.serverId))"
        let flagString: String = "\(flagReason)"
        let request: AFHTTPRequestOperation = self.requestManager.PUT(relativePath, parameters: nil, success: {(operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            successBlock?()
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.inputStream = NSInputStream(data: flagString.dataUsingEncoding(NSUTF8StringEncoding)!)
        request.start()
    }
    
    func getWordWithID(wordID: Int, onSuccess successBlock: ((word: Word) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "words/\(wordID).json"
        let request: AFHTTPRequestOperation = self.requestManager.GET(relativePath, parameters: nil, success: {(operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            guard let responseJsonObject = responseObject as? [String : AnyObject] else {
                return
            }
            successBlock?(word: Word(packed: responseJsonObject))
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.start()
    }
    
    func postWord(word: Word, AsPracticeWithFilesInPath filePath: String, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let request: AFHTTPRequestOperation = self.requestManager.POST("words/practice/", parameters: nil, constructingBodyWithBlock: {
            (formData: AFMultipartFormData) -> Void in
            formData.appendPartWithFormData(word.toJSON()!, name: "word")
            var fileNum: Int = 0
            for file: Audio in word.audios {
                fileNum++
                let fileName: String = "file\(fileNum)"
                let fileData: NSData = NSData(contentsOfURL: file.fileURL()!)!
                formData.appendPartWithFileData(fileData, name: fileName, fileName: fileName, mimeType: "audio/mp4a-latm")
            }
            }, success: {(operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
                progressBlock?(progress: 1)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.setDownloadProgressBlock({(bytesRead: UInt, totalBytesRead: Int64, totalBytesExpectedToRead: Int64) -> Void in
            if totalBytesExpectedToRead > 0 {
                progressBlock?(progress: Float(totalBytesRead) / Float(totalBytesExpectedToRead))
            }
        })
        request.start()
    }
    
    func postWord(word: Word, withFilesInPath filePath: String, asReplyToWordWithID wordID: Int, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "words/practice/\(wordID)/replies/"
        let request: AFHTTPRequestOperation = self.requestManager.POST(relativePath, parameters: nil, constructingBodyWithBlock: {
            (formData: AFMultipartFormData) -> Void in
            formData.appendPartWithFormData(word.toJSON()!, name: "word")
            var fileNum: Int = 0
            for file: Audio in word.audios {
                fileNum++
                let fileName: String = "file\(fileNum)"
                let fileData: NSData = NSData(contentsOfURL: file.fileURL()!)!
                formData.appendPartWithFileData(fileData, name: fileName, fileName: fileName, mimeType: "audio/mp4a-latm")
            }
            }, success: {(operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
                progressBlock?(progress: 1)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.setDownloadProgressBlock({(bytesRead: UInt, totalBytesRead: Int64, totalBytesExpectedToRead: Int64) -> Void in
            if totalBytesExpectedToRead > 0 {
                progressBlock?(progress: Float(totalBytesRead) / Float(totalBytesExpectedToRead))
            }
        })
        request.start()
    }
    
    func deleteEventWithID(serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "events/\(serverId)"
        let request: AFHTTPRequestOperation = self.requestManager.DELETE(relativePath, parameters: nil, success: {
            (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            successBlock?()
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.start()
    }
    
    func postFeedback(feedback: String, toAuthorOfLessonWithID serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "events/feedbackLesson/\(serverId)/"
        let request: AFHTTPRequestOperation = self.requestManager.POST(relativePath, parameters: nil, success: {
            (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            successBlock?()
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.start()
    }
    
    func getEventsTargetingMeOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let request: AFHTTPRequestOperation = self.requestManager.GET("events/eventsTargetingMe/", parameters: nil, success: {
            (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
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
        request.start()
    }
    
    func getEventsIMayBeInterestedInOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let request: AFHTTPRequestOperation = self.requestManager.GET("events/eventsIMayBeInterestedIn/", parameters: nil, success: {(operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
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
        request.start()
    }
    
    //TODO: side effects, should just return the audio directly
    func pullAudio(audio: Audio, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "audio/\(audio.serverId).caf"
        let request: AFHTTPRequestOperation = self.requestManager.GET(relativePath, parameters: nil, success: {
            (operation: AFHTTPRequestOperation, responseObject: AnyObject) -> Void in
            progressBlock?(progress: 1)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
        request.setDownloadProgressBlock({(bytesRead: UInt, totalBytesRead: Int64, totalBytesExpectedToRead: Int64) -> Void in
            if totalBytesExpectedToRead > 0 {
                progressBlock?(progress: Float(totalBytesRead) / Float(totalBytesExpectedToRead + 1))
            }
        })
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let dirURL = audio.fileURL()?.URLByDeletingLastPathComponent!
        //todo this line is retarded
        _ = try? fileManager.createDirectoryAtURL(dirURL!, withIntermediateDirectories: true, attributes: nil)
        let out = NSOutputStream(URL: audio.fileURL()!, append: false)
        out!.open()
        request.outputStream = out
        request.start()
    }
    
    class func hudFlashError(error: NSError) {
        let hud = staticHud
        hud.hide(false)
        hud.show(true)
        let view: UITextView = UITextView(frame: CGRectMake(0, 0, 200, 200))
        view.text = error.localizedDescription
        view.font = hud.labelFont
        view.textColor = UIColor.whiteColor()
        view.backgroundColor = UIColor.clearColor()
        view.sizeToFit()
        hud.customView = view
        hud.hide(true, afterDelay: 1.2)
    }
}