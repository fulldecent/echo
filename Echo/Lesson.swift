//
//  Lesson.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation
import Alamofire

public struct Lesson {
    /// Server ID
    let id: Int
    let language: Language
    let name: String
    let detail: String
    let userName: String
    let updated: Date
    let likes: Int
    let words: [Word]
    
    private enum JSONName: String {
        case id = "lessonID"
        case language = "languageTag"
        case name = "name"
        case detail = "detail"
        case userName = "userName"
        case updated = "updated"
        case likes = "likes"
        case words = "words"
    }
    
    func missingFiles() -> [Audio] {
        return words.flatMap {$0.missingFiles()}
    }
    
    init?(json: [String : Any]) {
        guard let id = json[JSONName.id.rawValue] as? Int,
            let languageString = json[JSONName.language.rawValue] as? String,
            let language = Language(rawValue: languageString),
            let name = json[JSONName.name.rawValue] as? String,
            let detail = json[JSONName.detail.rawValue] as? String,
            let userName = json[JSONName.userName.rawValue] as? String,
            let updated = json[JSONName.updated.rawValue] as? Int,
            let likes = json[JSONName.likes.rawValue] as? Int
        else {
            return nil
        }

        self.id = id
        self.language = language
        self.name = name
        self.detail = detail
        self.userName = userName
        self.updated = Date(timeIntervalSince1970: TimeInterval(updated))
        self.likes = likes
        if let wordsJSON = json[JSONName.words.rawValue] as? [[String: Any]] {
            self.words = wordsJSON.flatMap(Word.init)
        } else {
            self.words = []
        }
    }
    
    func toJSON() -> [String : Any] {
        var retval = [String : Any]()
        if id > 0 {
            retval[JSONName.id.rawValue] = id
        }
        retval[JSONName.language.rawValue] = language.rawValue
        retval[JSONName.name.rawValue] = name
        retval[JSONName.detail.rawValue] = detail
        retval[JSONName.userName.rawValue] = userName
        retval[JSONName.updated.rawValue] = Int(updated.timeIntervalSince1970)
        retval[JSONName.likes.rawValue] = likes
        retval[JSONName.words.rawValue] = words.map {$0.toJSON()} 
        return retval
    }
    
    func fetchFiles(completion: @escaping (_ success: Bool) -> Void) -> Progress {
        print("Download STARTED for : \(id)")

        //let filesToGet = missingFiles()
        let filesToGet = words.flatMap {$0.audios} //TEMPORARY
        let progress = Progress(totalUnitCount: Int64(filesToGet.count))
        progress.kind = .file
        progress.setUserInfoObject(Progress.FileOperationKind.downloading, forKey: .fileOperationKindKey)
        progress.setUserInfoObject(filesToGet.count, forKey: .fileTotalCountKey)
        var totalDone = 0
        for audio in filesToGet {
            var isFirstUpdate = true
            audio.fetchFile(withProgress: { childProgress in
                if isFirstUpdate {
                    progress.addChild(childProgress, withPendingUnitCount: 1)
                }
                isFirstUpdate = false
                if childProgress.completedUnitCount >= childProgress.totalUnitCount {
                    totalDone = totalDone + 1
                    if totalDone == filesToGet.count {
                        completion(true)
                    }
                }
            })
        }
        return progress
    }
    
    static func lessons(in language:Language, completion: @escaping ([Lesson]) -> Void) {
        let url = NetworkManager.shared.baseURL.appendingPathComponent("lessons/\(language.rawValue)/")!
        let headers = NetworkManager.shared.authenticationHeaders()
        Alamofire.request(url, headers: headers)
            .responseJSON { response in
                var lessons: [Lesson] = []
                if let lessonsJSON = response.result.value as? [[String: Any]] {
                    for lessonJSON in lessonsJSON {
                        if let lesson = Lesson(json: lessonJSON) {
                            lessons.append(lesson)
                        }
                    }
                }
                completion(lessons)
        }
    }

    static func lesson(withId lessonId:Int, completion: @escaping (Lesson) -> Void) {
        let url = NetworkManager.shared.baseURL.appendingPathComponent("lessons/\(lessonId).json")!
        let headers = NetworkManager.shared.authenticationHeaders()
        Alamofire.request(url, headers: headers)
            .responseJSON { response in
                if let lessonJSON = response.result.value as? [String: Any] {
                    if let lesson = Lesson(json: lessonJSON) {
                        completion(lesson)
                    }
                }
        }
    }
}
