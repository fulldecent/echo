//
//  NetworkManager.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation
import Alamofire // ~4.2.0
import UIKit

//TODO use NSProgress for all progress blocks
// http://oleb.net/blog/2014/03/nsprogress/

// V2.0 API - THE PARTS WE'RE USING ///////////////////////////////
//	GET		lessons/fr/[?search=bonjour]
//	GET		lessons/175.json[?preview=yes]
//	DELETE	lessons/172[.json]
//	GET		audio/2528.caf

// NOT USING API
//	GET		events/eventsTargetingMe/?[since_id=ID][max_id=ID]
//	GET		events/eventsIMayBeInterestedIn/?[since_id=ID][max_id=ID]
//	PUT		lessons/LESSONCODE/words/WORDCODE/files/FILECODE[.m4a]
//	GET		users/172.png
//	GET		users/172.json
//	GET		users/me/updates?lastLessonSeen=172&lastMessageSeen=229&lessonIDs[]=170&lessonIDs=171&lessonTimestamps[]=1635666&...
//	GET		words/824.json
//	POST	words/practice/
//	POST	words/practice/225
//	POST	words/practice/225/replies/
//	DELETE	words/[practice/]166[.json]
//	PUT		users/me/flagsLessons/175
//	DELETE	events/125[.json]
//	POST	lessons/
//	POST	users/
//	POST	events/feedbackLesson/125/
//	PUT		users/me/likesLessons/175 (DEPRECATED IN 1.0.15)
//	DELETE	users/me/likesLessons/175 (DEPRECATED IN 1.0.15)


class NetworkManager {
    let baseURL = NSURL(string: "https://learnwithecho.com/api/2.0/")!
    
    struct MissingFile {
        let wordUUID: String
        let audioUUID: String
    }
    
    /// The singleton instance
    static let shared: NetworkManager = {
        let userUUID = UIDevice.current.identifierForVendor!.uuidString
        let manager = NetworkManager(userUUID: userUUID)
        return manager
    }()
    
    /// The testing singleton instance
    private static let testing: NetworkManager = {
        let userUUID = "01234567-0123-0123-0123-012345678901"
        let manager = NetworkManager(userUUID: userUUID)
        return manager
    }()
    
    let userUUID: String
    
    private init(userUUID: String) {
        self.userUUID = userUUID
    }
    
    func authenticationHeaders() -> HTTPHeaders {
        var headers: HTTPHeaders = [:]
        let authorizationHeader = Request.authorizationHeader(user: "xxx", password: self.userUUID)!
        headers[authorizationHeader.key] = authorizationHeader.value
        return headers
    }
}
