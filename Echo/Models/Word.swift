//
//  Word.swift
//  Echo
//
//  Created by Full Decent on 1/18/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation

struct Word: Codable, Sendable, Identifiable, Hashable {
    let id: Int
    let name: String
    let audios: [Audio]
    var complete: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id = "wordID"
        case name
        case audios = "files"
        case complete
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        audios = try container.decode([Audio].self, forKey: .audios)
        complete = try container.decodeIfPresent(Bool.self, forKey: .complete) ?? false
    }

    // Convenience initializer for programmatic construction (e.g., previews/tests)
    nonisolated init(id: Int, name: String, audios: [Audio], complete: Bool) {
        self.id = id
        self.name = name
        self.audios = audios
        self.complete = complete
    }
}
