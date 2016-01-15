//
//  Word.swift
//  Echo
//
//  Created by William Entriken on 12/20/15.
//
//

import Foundation

public class Word {
    private let kLanguageTag = "languageTag"
    private let kName = "name"
    private let kDetail = "detail"
    private let kWordID = "wordID"
    private let kWordCode = "wordCode"
    private let kUserID = "userID"
    private let kUserName = "userName"
    private let kFiles = "files"
    private let kCompleted = "completed"
    private let kFileID = "fileID"
    private let kFileCode = "fileCode"

    public weak var lesson: Lesson?

    public lazy var uuid = NSUUID().UUIDString

    //TODO: make this an optional instead of arbitrary 0=not on server
    public var serverId: Int = 0

    //TOOD: make detail, user* optional and others required, do not initialize to ""
    public var languageTag: String = ""
    public var name: String = ""
    public var detail: String = ""
    public var userID: String = ""
    public var userName: String = ""
    public var audios = [Audio]()

    // client side data
    public var completed: Bool = false
    
    public func fileURL() -> NSURL? {
        let base = self.lesson?.fileURL()
        if self.serverId > 0 { //TODO temp hack, should test NIL
            return base?.URLByAppendingPathComponent(String(self.serverId))
        }
        return base?.URLByAppendingPathComponent(self.uuid)
    }
    
    public func listOfMissingFiles() -> [Audio] {
        var retval = [Audio]()
        for audio in self.audios {
            if !audio.fileExistsOnDisk() {
                retval.append(audio)
            }
        }
        return retval
    }
    
    public func fileWithCode(fileCode: String) -> Audio? {
        for audio in self.audios {
            if (audio.uuid == fileCode) {
                return audio
            }
        }
        return nil
    }
    
    //TODO: dont allow this, need a better initializer
    public init() {
        
    }
    
    public init(packed: [String : AnyObject]) {
        if let serverId = packed[kWordID] as? Int {
            self.serverId = serverId
        }
        if let uuid = packed[kWordCode] as? String {
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
        if let userID = packed[kUserID] as? String {
            self.userID = userID
        }
        if let userName = packed[kUserName] as? String {
            self.userName = userName
        }
        if let completed = packed[kCompleted] as? Bool {
            self.completed = completed
        }
        
        if let files = packed[kFiles] as? [[String : AnyObject]] {
            for file in files {
                let audio = Audio(word: self)
                if let fileID = file[kFileID] as? Int {
                    audio.serverId = fileID
                }
                if let fileCode = file[kFileCode] as? String {
                    audio.uuid = fileCode
                }
                self.audios.append(audio)
            }
        }
    }
    
    public convenience init?(JSONString: String) {
        guard let JSONData = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) else {
            return nil
        }
        guard let JSONDictionary = try? NSJSONSerialization.JSONObjectWithData(JSONData, options: []) as? Dictionary<String, AnyObject> else {
            return nil
        }
        self.init(packed: JSONDictionary!)
    }
    
    public func toDictionary() -> [String : AnyObject] {
        var retval = [String : AnyObject]()
        if self.serverId > 0 {
            retval[kWordID] = self.serverId
        }
        retval[kWordCode] = self.uuid
        retval[kLanguageTag] = self.languageTag
        retval[kName] = self.name
        retval[kDetail] = self.detail
        retval[kUserName] = self.userName
        retval[kUserID] = self.userID

        var packedFiles = [AnyObject]()
        for audio in self.audios {
            var fileDict = [String : AnyObject]()
            if audio.serverId > 0 {
                fileDict[kFileID] = audio.serverId
            }
            if audio.uuid != "" {
                fileDict[kFileCode] = audio.uuid
            }
            packedFiles.append(fileDict)            
        }
        
        retval[kFiles] = packedFiles
        if self.completed {
            retval[kCompleted] = self.completed
        }
        return retval
    }

    public func toJSON() -> NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(self.toDictionary(), options: [])
    }
}