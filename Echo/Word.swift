//
//  Word.swift
//  Echo
//
//  Created by Full Decent on 1/18/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

// See JSON deserialization at https://developer.apple.com/swift/blog/?id=37


import Foundation

struct Word {
    let id: Int
    let language: Language
    let name: String
    let detail: String
    let audios: [Audio]
    
    private enum JSONName: String {
        case id = "wordID"
        case language = "languageTag"
        case name = "name"
        case detail = "detail"
        case audios = "files"
    }
    
    func missingFiles() -> [Audio] {
        return audios.filter {!$0.fileExistsOnDisk()}
    }
    
    init?(json: [String: Any]) {
        guard let id = json[JSONName.id.rawValue] as? Int,
            let languageString = json[JSONName.language.rawValue] as? String,
            let language = Language(rawValue: languageString),
            let name = json[JSONName.name.rawValue] as? String,
            let detail = json[JSONName.detail.rawValue] as? String
        else {
            return nil
        }
        
        self.id = id
        self.language = language
        self.name = name
        self.detail = detail
        if let audiosJSON = json[JSONName.audios.rawValue] as? [[String: Any]] {
            self.audios = audiosJSON.flatMap(Audio.init)
        } else {
            self.audios = []
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
        retval[JSONName.audios.rawValue] = audios.map {$0.toJSON()}
        return retval
    }
}
