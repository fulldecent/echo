//
//  NetworkManager.swift
//  Echo
//
//  Created by William Entriken on 1/13/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import AFNetworking
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
    
    /// The singleton instance
    static var sharedNetworkManager: NetworkManager = {
        return NetworkManager()
    }()
    
    /// Override for the usercode performing the actions
    lazy var usercode = Profile.currentUser.usercode
    
    // OLD METHODS HERE USE AFNETWORKING
    private lazy var sessionManager: AFHTTPSessionManager = {
        let retval = AFHTTPSessionManager(baseURL: NSURL(string: self.SERVER_ECHO_API_URL))
        let authenticateRequests = AFJSONRequestSerializer()
        authenticateRequests.setAuthorizationHeaderFieldWithUsername("xxx", password: self.usercode)
        retval.requestSerializer = authenticateRequests
        return retval
    }()
    
    // THIS IS THE FUTURE
    private lazy var alamoManager: Alamofire.Manager = {
        let user = "xxx"
        let password = self.usercode
        let credentialData = "\(user):\(password)".dataUsingEncoding(NSUTF8StringEncoding)!
        let base64Credentials = credentialData.base64EncodedStringWithOptions([])
        var headers = Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        headers["Authorization"] = "Basic \(base64Credentials)"
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = headers
        return Alamofire.Manager(configuration: configuration)
    }()
    
    // PUBLIC API
    
    /// Remove a lesson from the server
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
    
    /// Retrieve a lesson from the server
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
    
    /// Retrieve lessons from the server with a specified language and term
    func searchLessonsWithLangTag(langTag: String, andSearhText searchText: String, onSuccess successBlock: ((lessonPreviews: [Lesson]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "lessons/\(langTag)/?search=\(searchText)"
        sessionManager.GET(relativePath, parameters: nil, progress: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            guard let responseObjects = responseObject as? [[String: AnyObject]] else {
                failureBlock?(error: NSError(domain: "Wrong response type", code: 9999, userInfo: nil))
                return
            }
            let lessons = responseObjects.map(Lesson.init)
            successBlock?(lessonPreviews: lessons)
        }, failure: {
            (_, error: NSError) -> Void in
            failureBlock?(error: error)
        })
    }
    
    /// Post a lesson to the server
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
    
    /// Find the URL for a user's profile photo
    func photoURLForUserWithID(userID: Int) -> NSURL {
        let relativeURL: String = "users/\(userID).png"
        return NSURL(string: relativeURL, relativeToURL: BASE_URL)!
    }
    
    /// Update a user's profile on the server
    func postUserProfile(profile: Profile, onSuccess successBlock: ((username: String, userId: Int, recommendedLessons: [Lesson]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "users", relativeToURL: self.BASE_URL)!
        let parameters = Profile.currentUser.toDictionary()
  
        self.alamoManager.request(.POST, url, parameters: parameters, encoding: .JSON).responseJSON {
            response in
            switch response.result {
            case .Success(let responseObject as [String: AnyObject]):
                guard let username = responseObject["username"] as? String else {
                    return
                }
                guard let userId = responseObject["userID"] as? Int else {
                    return
                }
                guard let recommendedLessonJsonTexts = responseObject["recommendedLessons"] as? [[String : AnyObject]] else {
                    return
                }
                let recommendedLessons = recommendedLessonJsonTexts.map(Lesson.init)
                successBlock?(username: username, userId: userId, recommendedLessons: recommendedLessons)
            case .Failure(let error):
                failureBlock?(error: error)
            default:
                failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
            }
        }
    }
    
    /// Get a list of server resources updated since we last saw them
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
    
    /// Flag a lesson on the server to recommend its deletion
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
    
    /// Download a word from the server
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
    
    /// Upload a practice word to the server
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
    
    /// Post a reply to a practice word
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
    
    /// Delete an event on the server
    func deleteEventWithID(serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "events/\(serverId)"
        sessionManager.DELETE(relativePath, parameters: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            successBlock?()
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    /// Send feedback to the author of a lesson
    func postFeedback(feedback: String, toAuthorOfLessonWithID serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "events/feedbackLesson/\(serverId)/"
        sessionManager.POST(relativePath, parameters: nil, progress: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            successBlock?()
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    /// Get events from the server that target the current user
    func getEventsTargetingMeOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        sessionManager.GET("events/eventsTargetingMe/", parameters: nil, progress: nil, success: {
            (_, responseObject: AnyObject?) -> Void in
            guard let jsonObjects = responseObject as? [[String: AnyObject]] else {
                return
            }
            let events = jsonObjects.map(Event.init)
            successBlock?(events: events)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    /// Get events from the server relevant to the current user but not targeting them
    func getEventsIMayBeInterestedInOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        sessionManager.GET("events/eventsIMayBeInterestedIn/", parameters: nil, progress: nil, success: {(_, responseObject: AnyObject?) -> Void in
            guard let jsonObjects = responseObject as? [[String: AnyObject]] else {
                return
            }
            let events = jsonObjects.map(Event.init)
            successBlock?(events: events)
            }, failure: {(_, error: NSError) -> Void in
                failureBlock?(error: error)
        })!
    }
    
    /// Retrieve an audio file from the server
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
