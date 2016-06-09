//
//  NetworkManager.swift
//  Echo
//
//  Created by William Entriken on 1/13/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import Foundation
import Alamofire

//TODO use NSProgress for all progress blocks
// http://oleb.net/blog/2014/03/nsprogress/

// V2.0 API ///////////////////////////////////////////////////////
//	GET		audio/2528.caf
//	DELETE	events/125[.json]
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
//	PUT		users/me/flagsLessons/175
//	GET		words/824.json
//	DELETE	words/[practice/]166[.json]
//	POST	words/practice/
//	POST	words/practice/225
//	POST	words/practice/225/replies/
//
// NOT USING API
//	POST	events/feedbackLesson/125/
//	PUT		users/me/likesLessons/175 (DEPRECATED IN 1.0.15)
//	DELETE	users/me/likesLessons/175 (DEPRECATED IN 1.0.15)


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
    static var sharedNetworkManager = {
        return NetworkManager()
    }()
    
    /// Override for the usercode performing the actions
    lazy var usercode = Profile.currentUser.usercode
    
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
        let url = NSURL(string: "lessons/\(serverId)", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.DELETE, url).responseJSON() {
            response in
            switch response.result {
            case .Success:
                successBlock?()
            case .Failure(let error):
                failureBlock?(error: error)
            }
        }
    }
    
    /// Retrieve a lesson from the server
    func getLessonWithID(serverId: Int, asPreviewOnly preview: Bool, onSuccess: ((lesson: Lesson) -> Void)?, onFailure: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "lessons/\(serverId).json", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.GET, url).validate().responseJSON() {
            response in
            switch response.result {
            case .Success(let JSON as [String: AnyObject]):
                let lesson = Lesson(packed: JSON)
                onSuccess?(lesson: lesson)
            case .Failure(let error):
                onFailure?(error: error)
            default:
                onFailure?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
            }
        }
    }
    
    /// Retrieve lessons from the server with a specified language and term
    func searchLessonsWithLangTag(langTag: String, andSearhText searchText: String, onSuccess successBlock: ((lessonPreviews: [Lesson]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "lessons/\(langTag)/?search=\(searchText)", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.GET, url).validate().responseJSON() {
            response in
            switch response.result {
            case .Success(let JSON as [[String: AnyObject]]):
                let lessons = JSON.map(Lesson.init)
                successBlock?(lessonPreviews: lessons)
            case .Failure(let error):
                failureBlock?(error: error)
            default:
                failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
            }
        }
    }
    
    /// Post a lesson to the server
    func postLesson(lesson: Lesson, onSuccess successBlock: ((newLessonID: Int, newServerVersion: Int, neededWordAndFileCodes: [MissingFile]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "lessons/", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.POST, url).validate().responseJSON() {
            response in
            switch response.result {
            case .Success(let JSON as [String: AnyObject]):
                guard let serverId = JSON["lessonID"] as? Int else {
                    return
                }
                guard let updated = JSON["updated"] as? Int else {
                    return
                }
                guard let neededFiles = JSON["neededFiles"] as? [[String: String]] else {
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
            case .Failure(let error):
                failureBlock?(error: error)
            default:
                failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
            }
        }
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
        
        
        self.alamoManager.upload(request, file: localFileURL)
            .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                if totalBytesExpectedToRead > 0 {
                    progressBlock?(progress: Float(totalBytesRead) / Float(totalBytesExpectedToRead))
                }
            }
            .validate()
            .response { _, _, _, error in
                if let error = error {
                    failureBlock?(error: error)
                } else {
                }
        }
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
                    failureBlock?(error: NSError(domain: "No username", code: 0, userInfo: nil))
                    return
                }
                guard let userId = responseObject["userID"] as? Int else {
                    failureBlock?(error: NSError(domain: "No userID", code: 0, userInfo: nil))
                    return
                }
                let recommendedLessonJsonTexts = responseObject["recommendedLessons"] as? [[String : AnyObject]]
                let recommendedLessons = recommendedLessonJsonTexts?.map(Lesson.init)
                successBlock?(username: username, userId: userId, recommendedLessons: recommendedLessons ?? [])
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
        var requestParams = [String : AnyObject]()
        requestParams["lessonIDs"] = lessonIDsToCheck
        requestParams["lessonTimestamps"] = lessonTimestampsToCheck
        if (defaults.objectForKey("lestLessonSeen") is String) {
            requestParams["lastLessonSeen"] = defaults.objectForKey("lastLessonSeen")
        }
        if (defaults.objectForKey("lastMessageSeen") is String) {
            requestParams["lastMessageSeen"] = defaults.objectForKey("lastMessageSeen")
        }
        
        let url = NSURL(string: "users/me/updates", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.GET, url, parameters: requestParams).validate().responseJSON() {
            response in
            switch response.result {
            case .Success(let JSON as [String : AnyObject]):
                guard let newLessons = JSON["newLessons"] as? Int else {
                    failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
                    return
                }
                guard let unreadMessages = JSON["unreadMessages"] as? Int else {
                    failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
                    return
                }
                let updatedLessons: [Int]
                if let updatedLessonsWithIds = JSON["updatedLessons"] as? [Int : Int] {
                    updatedLessons = [Int](updatedLessonsWithIds.keys)
                } else {
                    updatedLessons = []
                }
                successBlock?(updatedLessonIds:updatedLessons, numNewLessons: newLessons, numNewMessages: unreadMessages)
            case .Failure(let error):
                failureBlock?(error: error)
            default:
                failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
            }
        }
    }
    
    /// Flag a lesson on the server to recommend its deletion
    func doFlagLesson(lesson: Lesson, withReason flagReason: FlagReason, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let relativePath: String = "users/me/flagsLessons/\(Int(lesson.serverId))"
        let URL = NSURL(string: relativePath, relativeToURL: self.BASE_URL)!
        let request = NSURLRequest(URL: URL)
        let flagString = "\(flagReason)"
        let uploadData = flagString.dataUsingEncoding(NSUTF8StringEncoding)!
        self.alamoManager.upload(request, data: uploadData)
            .validate()
            .response { _, _, _, error in
                if let error = error {
                    failureBlock?(error: error)
                } else {
                }
        }
    }
    
    /// Download a word from the server
    func getWordWithID(wordID: Int, onSuccess successBlock: ((word: Word) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "words/\(wordID).json", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.GET, url).validate().responseJSON() {
            response in
            switch response.result {
            case .Success(let JSON as [String : AnyObject]):
                let word = Word(packed: JSON)
                successBlock?(word: word)
            case .Failure(let error):
                failureBlock?(error: error)
            default:
                failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
            }
        }
    }
    
    /// Upload a practice word to the server
    func postWord(word: Word, AsPracticeWithFilesInPath filePath: String, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "words/practice/", relativeToURL: self.BASE_URL)!
        self.alamoManager.upload(
            .POST,
            url,
            multipartFormData: { multipartFormData in
                for (fileNum, file) in word.audios.enumerate() {
                    let fileName = "file\(fileNum)"
                    let fileData = NSData(contentsOfURL: file.fileURL()!)!
                    multipartFormData.appendBodyPart(data: fileData, name: fileName, fileName: fileName, mimeType: "audio/mp4a-latm")
                }
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                        if totalBytesExpectedToRead > 0 {
                            dispatch_async(dispatch_get_main_queue()) {
                                progressBlock?(progress: Float(totalBytesRead) / Float(totalBytesExpectedToRead))
                            }
                        }
                    }
                    upload.responseJSON { response in
                        switch response.result {
                        case .Success:
                            break
                        case .Failure(let error):
                            failureBlock?(error: error)
                        }
                    }
                    case .Failure(let encodingError):
                    print(encodingError)
                }
            }
        )
    }
    
    /// Post a reply to a practice word
    func postWord(word: Word, withFilesInPath filePath: String, asReplyToWordWithID wordID: Int, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "words/practice/\(wordID)/replies/", relativeToURL: self.BASE_URL)!
        self.alamoManager.upload(
            .POST,
            url,
            multipartFormData: { multipartFormData in
                multipartFormData.appendBodyPart(data: word.toJSON()!, name: "word")
                for (fileNum, file) in word.audios.enumerate() {
                    let fileName = "file\(fileNum)"
                    let fileData = NSData(contentsOfURL: file.fileURL()!)!
                    multipartFormData.appendBodyPart(data: fileData, name: fileName, fileName: fileName, mimeType: "audio/mp4a-latm")
                }
            },
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                        if totalBytesExpectedToRead > 0 {
                            dispatch_async(dispatch_get_main_queue()) {
                                progressBlock?(progress: Float(totalBytesRead) / Float(totalBytesExpectedToRead))
                            }
                        }
                    }
                    upload.responseJSON { response in
                        switch response.result {
                        case .Success:
                            break
                        case .Failure(let error):
                            failureBlock?(error: error)
                        }
                    }
                case .Failure(let encodingError):
                    print(encodingError)
                }
            }
        )
    }
    
    /// Delete an event on the server
    func deleteEventWithID(serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "events/\(serverId)", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.DELETE, url).responseJSON() {
            response in
            switch response.result {
            case .Success:
                successBlock?()
            case .Failure(let error):
                failureBlock?(error: error)
            }
        }
    }
    
    /// Get events from the server that target the current user
    func getEventsTargetingMeOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "events/eventsTargetingMe/", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.GET, url).validate().responseJSON() {
            response in
            switch response.result {
            case .Success(let JSON as [[String: AnyObject]]):
                let events = JSON.map(Event.init)
                successBlock?(events: events)
            case .Failure(let error):
                failureBlock?(error: error)
            default:
                failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
            }
        }
    }
    
    /// Get events from the server relevant to the current user but not targeting them
    func getEventsIMayBeInterestedInOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        let url = NSURL(string: "events/eventsIMayBeInterestedIn/", relativeToURL: self.BASE_URL)!
        self.alamoManager.request(.GET, url).validate().responseJSON() {
            response in
            switch response.result {
            case .Success(let JSON as [[String: AnyObject]]):
                let events = JSON.map(Event.init)
                successBlock?(events: events)
            case .Failure(let error):
                failureBlock?(error: error)
            default:
                failureBlock?(error: NSError(domain: "Server bad response format", code: 9999, userInfo: nil))
            }
        }
    }
    
    /// Retrieve an audio file from the server
    func pullAudio(audio: Audio, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?) {
        assert(audio.serverId != nil)
        let relativePath: String = "audio/\(audio.serverId!).caf"
        let url = NSURL(string: relativePath, relativeToURL: self.BASE_URL)!
        let localFileURL = audio.fileURL()!
        
        let destination: Alamofire.Request.DownloadFileDestination = {_,_ in return localFileURL}
        self.alamoManager.download(.GET, url, destination: destination)
            .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                if totalBytesExpectedToRead > 0 {
                    dispatch_async(dispatch_get_main_queue()) {
                        progressBlock?(progress: Float(totalBytesRead) / Float(totalBytesExpectedToRead))
                    }
                }
            }
            .validate()
            .response { _, _, _, error in
                if let error = error {
                    failureBlock?(error: error)
                } else {
                }
        }
    }
}
