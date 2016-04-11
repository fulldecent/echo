//
//  Lesson.swift
//  Echo
//
//  Created by William Entriken on 1/3/16.
//
//

import Foundation

//TODO make a lesson preview type

public class Lesson: NSObject /* we need it for the Hashable conformance */ {
    
    private let kLessonID = "lessonID"
    private let kLessonCode = "lessonCode"
    private let kLanguageTag = "languageTag"
    private let kName = "name"
    private let kDetail = "detail"
    private let kServerTimeOfLastCompletedSync = "updated"
    private let kLocalChangesSinceLastSync = "localChangesSinceLastSync"
    private let kRemoteChangesSinceLastSync = "remoteChangesSinceLastSync"
    private let kWords = "words"
    private let kLikes = "likes"
    private let kFlags = "flags"
    
    private let kWordID = "wordID"
    private let kWordCode = "wordCode"
    private let kUserID = "userID"
    private let kUserName = "userName"
    private let kFiles = "files"
    private let kCompleted = "completed"
    
    private let kFileID = "fileID"
    private let kFileCode = "fileCode"

    //TODO: make optional and remove convention that 0 = not on server
    var serverId: Int = 0
    
    //TOOD: make detail, user*, and server/local/remote & a couple more optional and others required, do not initialize to ""
    var languageTag: String = ""
    var name: String = ""
    var detail: String = ""
    var serverTimeOfLastCompletedSync: Int = 0
    var localChangesSinceLastSync: Bool = false
    var remoteChangesSinceLastSync: Bool = false
    var words: [Word] = [Word]()
    var userID: Int = 0
    var userName: String = ""
    var numLikes: Int = 0
    var numFlags: Int = 0
    var numUsers: Int = 0
    
    lazy var uuid: String = NSUUID().UUIDString
    
    func fileURL() -> NSURL? {
        guard let url: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last else {
            return nil
        }
        if self.serverId > 0 {
            return url.URLByAppendingPathComponent("\(self.serverId)")
        }
        return url.URLByAppendingPathComponent("\(self.uuid)")
    }
    
    func deleteFromDisk() {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        if let url: NSURL = self.fileURL() {
            _ = try? fileManager.removeItemAtURL(url)
        }
    }
    
    func setToLesson(target: Lesson) {
        self.serverId = target.serverId
        self.uuid = target.uuid
        self.languageTag = target.languageTag
        self.name = target.name
        self.detail = target.detail
        self.userID = target.userID
        self.userName = target.userName
        self.words = target.words
        for word: Word in target.words {
            word.lesson = self
        }
    }
    
    func removeStaleFiles() {
        let fileManager: NSFileManager = NSFileManager.defaultManager()
        let wordsOnDiskURL = try? fileManager.contentsOfDirectoryAtURL(self.fileURL()!, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants)

        for wordOnDiskURL in wordsOnDiskURL ?? [] {
            var willKeepWord: Bool = false
            for word: Word in self.words {
                if word.fileURL() == wordOnDiskURL {
                    willKeepWord = true
                }
                if willKeepWord {
                    let filesOnDiskURL = try? fileManager.contentsOfDirectoryAtURL(wordOnDiskURL, includingPropertiesForKeys: nil, options:NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants)
                    
                    for fileOnDiskURL in filesOnDiskURL ?? [] {
                        var willKeepFile: Bool = false
                        for audio: Audio in word.audios {
                            if audio.fileURL() == fileOnDiskURL {
                                willKeepFile = true
                            }
                        }
                        if !willKeepFile {
                            do {
                                try fileManager.removeItemAtURL(fileOnDiskURL)
                            } catch {
                                NSLog("removeItemAtPath failed \(fileOnDiskURL)")
                            }
                        }
                    }
                }
            }
            if !willKeepWord {
                do {
                    try fileManager.removeItemAtURL(wordOnDiskURL)
                } catch {
                    NSLog("removeItemAtPath failed \(wordOnDiskURL)")
                }
            }
        }
    }
    
    //TODO: dont allow this, need a better initializer
    public override init() {
        
    }
    
    //todo: this needs to be a struct or something
    func listOfMissingFiles() -> [[String: AnyObject]] {
        // return: [{"word":Word *,"audio":Audio *},...]
        var retval = [[String: AnyObject]]()
        for word: Word in self.words {
            let wordMissingFiles = word.listOfMissingFiles()
            for file: Audio in wordMissingFiles {
                var entry = [String : AnyObject]()
                entry["audio"] = file
                entry["word"] = word
                retval.append(entry)
            }
        }
        return retval
    }
    
    func isByCurrentUser() -> Bool {
        return Profile.currentUser.userID == self.userID
    }
    
    func isShared() -> Bool {
        return self.serverTimeOfLastCompletedSync > 0
    }
    
    func portionComplete() -> Float {
        guard self.words.count > 0 else {
            return 0
        }
        var numerator: Int = 0
        for word: Word in self.words {
            if word.completed {
                numerator += 1
            }
        }
        return Float(numerator) / Float(self.words.count)
    }
    
    func wordWithCode(wordCode: String) -> Word? {
        for word: Word in self.words {
            if (word.uuid == wordCode) {
                return word
            }
        }
        return nil
    }
    
    init(packed: [String : AnyObject]) {
        super.init()
        if let serverId = packed[kLessonID] as? Int {
            self.serverId = serverId
        }
        if let uuid = packed[kLessonCode] as? String {
            self.uuid = uuid
        }
        if let languageTag = packed[kLanguageTag] as? String {
            self.languageTag = languageTag
        }
        if let name = packed[kName] as? String {
            self.name = name
        }
        if let detail = packed[kDetail] as? String {
            self.detail = detail
        }
        if let serverTimeOfLastCompletedSync = packed[kServerTimeOfLastCompletedSync] as? Int {
            self.serverTimeOfLastCompletedSync = serverTimeOfLastCompletedSync
        }
        if let localChangesSinceLastSync = packed[kLocalChangesSinceLastSync] as? Bool {
            self.localChangesSinceLastSync = localChangesSinceLastSync
        }
        if let remoteChangesSinceLastSync = packed[kRemoteChangesSinceLastSync] as? Bool {
            self.remoteChangesSinceLastSync = remoteChangesSinceLastSync
        }
        if let userID = packed[kUserID] as? Int {
            self.userID = userID
        }
        if let userName = packed[kUserName] as? String {
            self.userName = userName
        }
        if let numLikes = packed[kLikes] as? Int {
            self.numLikes = numLikes
        }
        if let numFlags = packed[kFlags] as? Int {
            self.numFlags = numFlags
        }
        if let packedWords = packed[kWords] as? [[String : AnyObject]] {
            for packedWord in packedWords {
                let word = Word(packed: packedWord)
                word.lesson = self
                self.words.append(word)
            }
        }
    }
    
    convenience init?(JSONString: String) {
        guard let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) else {
            return nil
        }
        guard let JSONDictionary = try? NSJSONSerialization.JSONObjectWithData(JSONData, options: []) as? Dictionary<String, AnyObject> else {
            return nil
        }
        self.init(packed: JSONDictionary!)
    }
    
    func toDictionary() -> [String : AnyObject] {
        var retval = [String : AnyObject]()
        if self.serverId > 0 {
            retval[kLessonID] = self.serverId
        }
        retval[kLessonCode] = self.uuid
        retval[kLanguageTag] = self.languageTag
        retval[kName] = self.name
        retval[kDetail] = self.detail
        retval[kServerTimeOfLastCompletedSync] = self.serverTimeOfLastCompletedSync
        retval[kLocalChangesSinceLastSync] = self.localChangesSinceLastSync
        retval[kRemoteChangesSinceLastSync] = self.remoteChangesSinceLastSync
        retval[kUserName] = self.userName
        retval[kUserID] = self.userID
        
        var packedWords = [AnyObject]()
        for word in self.words {
            packedWords.append(word.toDictionary())
        }
        retval[kWords] = packedWords
        return retval
    }
    
    func toJSON() -> NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(self.toDictionary(), options: [])
    }
}



