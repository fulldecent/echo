//
//  Event.swift
//  Echo
//
//  Created by William Entriken on 1/6/16.
//
//

import Foundation

//TODO: objc hack
enum EventTypes: String {
    case PostLesson = "postLesson"
    case LikeLesson = "likeLesson"
    case FlagLesson = "flagLesson"
    case FlagUser = "flagUser"
    case UpdateUser = "updateUser"
    case PostPractice = "postPractice"
    case FeedbackLesson = "feedbackLesson"
    case ReplyPractice = "replyPractice"
}

//TODO: Does not need NSObject, don't need it anywhere
class Event: NSObject {
    private let kEventID = "id"
    private let kEventType = "eventType"
    private let kTimestamp = "timestamp"
    private let kActingUserID = "actingUserID"
    private let kTargetUserID = "targetUserID"
    private let kTargetWordID = "targetWordID"
    private let kTargetLessonID = "targetLessonID"
    private let kHtmlDescription = "description"
    private let kWasRead = "wasRead"
    // hacks
    private let kActingUserName = "actingUserName"
    private let kTargetWordName = "targetWordName"
    
    //TODO: make these optionals and do not have default values
    var eventID: Int = 0 //TODO: rename to id
    var eventType: EventTypes = .PostLesson //TODO: rename
    var eventTypeIsPractice: Bool = false //TODO: HUGE HACK!
    
    var timestamp: Int = 0
    var actingUserID: Int = 0
    var targetUserID: Int = 0
    var targetWordID: Int = 0
    var targetLessonID: Int = 0
    var htmlDescription: String = ""
    var wasRead: Bool = false
    var actingUserName: String = "" //TODO: hack
    var targetWordName: String = "" //TODO: hack
    
    init(packed: [String : AnyObject]) {
        if let eventID = packed[kEventID] as? Int {
            self.eventID = eventID
        }
        if let timestamp = packed[kTimestamp] as? Int {
            self.timestamp = timestamp
        }
        if let actingUserID = packed[kActingUserID] as? Int {
            self.actingUserID = actingUserID
        }
        if let targetUserID = packed[kTargetUserID] as? Int {
            self.targetUserID = targetUserID
        }
        if let targetWordID = packed[kTargetWordID] as? Int {
            self.targetWordID = targetWordID
        }
        if let targetLessonID = packed[kTargetLessonID] as? Int {
            self.targetLessonID = targetLessonID
        }
        if let htmlDescription = packed[kHtmlDescription] as? String {
            self.htmlDescription = htmlDescription
        }
        if let wasRead = packed[kWasRead] as? Bool {
            self.wasRead = wasRead
        }
        //hacks
        if let actingUserName = packed[kActingUserName] as? String {
            self.actingUserName = actingUserName
        }
        if let targetWordName = packed[kTargetWordName] as? String {
            self.targetWordName = targetWordName
        }
        
        if let eventTypeString = packed[kEventType] as? String {
            if let eventType = EventTypes(rawValue: eventTypeString) as EventTypes? {
                self.eventType = eventType
            }
        }
        self.eventTypeIsPractice = self.eventType == .PostPractice
        super.init()
    }
    
    func toDictionary() -> [String : AnyObject] {
        var retval = [String : AnyObject]()
        
        if self.eventID > 0 {
            retval[kEventID] = self.eventID
        }
        if self.timestamp > 0 {
            retval[kTimestamp] = self.timestamp
        }
        if self.actingUserID > 0 {
            retval[kActingUserID] = self.actingUserID
        }
        if self.targetUserID > 0 {
            retval[kTargetUserID] = self.targetUserID
        }
        if self.targetWordID > 0 {
            retval[kTargetWordID] = self.targetWordID
        }
        if self.targetLessonID > 0 {
            retval[kTargetLessonID] = self.targetLessonID
        }
        if self.htmlDescription != "" {
            retval[kHtmlDescription] = self.htmlDescription
        }
        if self.wasRead {
            retval[kWasRead] = self.wasRead
        }
        retval[kEventType] = self.eventType.rawValue
        return retval
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
    
    func toJSON() -> NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(self.toDictionary(), options: [])
    }
}
