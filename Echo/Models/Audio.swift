// Audio.swift
// Echo
//
// Created by Full Decent on 1/18/17.
// Copyright © 2017 William Entriken. All rights reserved.
//

import Foundation

struct Audio: Codable, Sendable, Identifiable, Hashable {
    let id: Int
    
    nonisolated func localURL() -> URL {
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        return documentURL.appendingPathComponent("audio-\(id).caf")
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "fileID"
    }
}
