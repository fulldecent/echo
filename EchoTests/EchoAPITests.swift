//
//  AudioTests.swift
//  Echo
//
//  Created by William Entriken on 2025-10-30.
//

import Testing
import Foundation
@testable import Echo

@MainActor
@Suite("Echo API tests")
struct EchoAPITests {
    private let api = EchoAPI.shared
    private let languageWithLessonsAvailable: Language = .fr
    private let validLessonId = 415
    private let validAudioId = 3171
    private let validUserId = 2966
    
    @Test("Search for French language returns some lessons")
    func searchFrLessons() async {
        let lessonPreviews = try! await api.searchLessonPreviews(language: languageWithLessonsAvailable)
        #expect(lessonPreviews.count > 0)
    }
    
    @Test("Load a lesson and return all details")
    func loadLesson415() async {
        let lesson = try! await api.getLessonMetadata(id: validLessonId)
        #expect(lesson.words.count > 0)
    }
    
    @Test("Load an audio")
    func loadAudio3171() async {
        let audio = try! await api.getAudio(id: validAudioId)
        #expect(audio.count > 0)
    }
    
    @Test("Load a user avatar")
    func loadAnAvatar() async {
        let avatar = try! await api.getUserAvatarFile(id: validUserId)
        #expect(avatar.count > 0)
    }
}
