//
//  AudioTests.swift
//  Echo
//
//  Created by William Entriken on 2025-10-30.
//

import Testing
import Foundation
@testable import Echo

/*
@MainActor
@Suite("Audio tests")
struct AudioTests {
    let validID = 5060
    let fileManager = FileManager.default
    var documentsURL: URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask).first! }
    
    @Test("fileURL generates correct path")
    func fileURLPath() {
        let audio = Audio(id: validID)
        let expected = documentsURL.appendingPathComponent("\(validID).caf")
        #expect(audio.fileURL == expected)
    }
    
    @Test("existsOnDisk returns false for missing file")
    func existsOnDiskMissing() {
        let audio = Audio(id: validID)
        try? fileManager.removeItem(at: audio.fileURL)
        #expect(audio.existsOnDisk == false)
    }
    
    @Test("existsOnDisk returns true for existing file")
    func existsOnDiskPresent() {
        let audio = Audio(id: validID)
        try? fileManager.removeItem(at: audio.fileURL)
        fileManager.createFile(atPath: audio.fileURL.path, contents: Data())
        #expect(audio.existsOnDisk == true)
        try? fileManager.removeItem(at: audio.fileURL)
    }
    
    @Test("deleteFromDisk removes file")
    func deleteFromDisk() {
        let audio = Audio(id: validID)
        try? fileManager.removeItem(at: audio.fileURL)
        fileManager.createFile(atPath: audio.fileURL.path, contents: Data())
        audio.deleteFromDisk()
        #expect(audio.existsOnDisk == false)
    }
    
    // Uses live network access
    @Test("fetchFile gets the expected file")
    func fetchFileDownloadsCorrectSize() async throws {
        let audio = Audio(id: validID)
        try? fileManager.removeItem(at: audio.fileURL)
        
        var progressReported = false
        try await audio.fetchFile { progress in
            if progress > 0 && progress < 1 {
                progressReported = true
            }
        }
        
        #expect(progressReported)
        
        let data = try Data(contentsOf: audio.fileURL)
        #expect(data.count == 16601)
        
        try? fileManager.removeItem(at: audio.fileURL)
    }
}
*/
