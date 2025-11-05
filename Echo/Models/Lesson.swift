//
//  Lesson.swift
//  Echo
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation

struct Lesson: Codable, Sendable, Identifiable, Hashable {
    let id: Int
    let language: Language
    let name: String
    let username: String
    let userId: Int
    let likes: Int
    let words: [Word]
    
    nonisolated init(id: Int, language: Language, name: String, username: String, userId: Int, likes: Int, words: [Word]) {
        self.id = id
        self.language = language
        self.name = name
        self.username = username
        self.userId = userId
        self.likes = likes
        self.words = words
    }
    
    nonisolated func userAvatarLocalURL() -> URL {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        return documentURL.appendingPathComponent("user-avatar-\(userId).png")
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        language = try container.decode(Language.self, forKey: .language)
        name = try container.decode(String.self, forKey: .name)
        username = try container.decode(String.self, forKey: .username)
        userId = try container.decode(Int.self, forKey: .userId)
        likes = try container.decode(Int.self, forKey: .likes)
        words = try container.decodeIfPresent([Word].self, forKey: .words) ?? []
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "lessonID"
        case language = "languageTag"
        case name
        case username = "userName"
        case userId = "userID"
        case likes
        case words
    }
}
