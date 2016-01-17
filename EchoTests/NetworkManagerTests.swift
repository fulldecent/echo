//
//  NetworkManagerTest.swift
//  Echo
//
//  Created by William Entriken on 1/16/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import XCTest
@testable import Echo

class NetworkManagerTests: XCTestCase {
    var networkManager: NetworkManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager.sharedNetworkManager
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDeleteLesson() {
        let asyncExpectation = expectationWithDescription("non-existant lesson deleted")
        let fakeLessonId = 999999
        networkManager.deleteLessonWithID(fakeLessonId, onSuccess: {
            () -> Void in
            asyncExpectation.fulfill()
            XCTAssert(true)
        }, onFailure: {
            (error) -> Void in
            XCTAssertNil(error, "Something went horribly wrong")
        })
        self.waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "Something went horribly wrong")
        }
    }
    
    func testGetLesson() {
        let asyncExpectation = expectationWithDescription("ready")
        let testLessonId = 369
        networkManager.getLessonWithID(testLessonId, asPreviewOnly: false, onSuccess: {
            (lesson, modifiedTime) -> Void in
            let expectedLessonName = "Consonant practice"
            let actualLessonName = lesson.name
            XCTAssertEqual(expectedLessonName, actualLessonName)
            let expectedFirstWordName = "Wood"
            let actualFirstWordName = lesson.words[0].name
            XCTAssertEqual(expectedFirstWordName, actualFirstWordName)
            asyncExpectation.fulfill()
            }, onFailure: {
                (error) -> Void in
                XCTAssertNil(error, "Request failure")
        })
        self.waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "Request timeout")
        }
    }
    
    //ALAMOFIRE
    func testGetLessonWithID2() {
        let asyncExpectation = expectationWithDescription("ready")
        let testLessonId = 369
        networkManager.getLessonWithID2(testLessonId, onSuccess: {
            (lesson) -> Void in
            let expectedLessonName = "Consonant practice"
            let actualLessonName = lesson.name
            XCTAssertEqual(expectedLessonName, actualLessonName)
            let expectedFirstWordName = "Wood"
            let actualFirstWordName = lesson.words[0].name
            XCTAssertEqual(expectedFirstWordName, actualFirstWordName)
            asyncExpectation.fulfill()
            }, onFailure: {
                (error) -> Void in
                XCTAssertNil(error, "Request failure")
        })
        self.waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "Request timeout")
        }
    }
    
    func testSearchLessons() {
        let asyncExpectation = expectationWithDescription("ready")
        let langTag = "en"
        let searchText = ""
        networkManager.searchLessonsWithLangTag(langTag, andSearhText: searchText, onSuccess: {
            (lessonPreviews: [Lesson]) -> Void in
            XCTAssertGreaterThan(lessonPreviews.count, 5)
            XCTAssertEqual("en", lessonPreviews[0].languageTag)
            asyncExpectation.fulfill()
        }, onFailure: {
            error in
            XCTAssertNil(error, "Request failure")
        })
        self.waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "Request timeout")
        }
    }
    
    func testPhotoURL() {
        let userId = 25
        let url = networkManager.photoURLForUserWithID(userId)
        let expectedURL = "https://learnwithecho.com/api/2.0/users/25.png"
        XCTAssertEqual(url.absoluteString, expectedURL)
    }

    func testGetWord() {
        let asyncExpectation = expectationWithDescription("ready")
        let testWordId = 500
        networkManager.getWordWithID(testWordId, onSuccess: {
            (word) -> Void in
            let expectedWordName = "Carnicero"
            let actualWordName = word.name
            XCTAssertEqual(expectedWordName, actualWordName)
            asyncExpectation.fulfill()
        }, onFailure: {
            (error) -> Void in
            XCTAssertNil(error, "Request failure")
        })
        self.waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "Request timeout")
        }
    }
    

    
    
/*
OTHER API

internal func postLesson(lesson: Lesson, onSuccess successBlock: ((newLessonID: Int, newServerVersion: Int, neededWordAndFileCodes: [[String : String]]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func putAudioFileAtPath(filePath: String, forLesson lesson: Lesson, withWord word: Word, usingCode code: String, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func postUserProfile(profile: Profile, onSuccess successBlock: ((username: String, userId: Int, recommendedLessons: [Lesson]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func getUpdatesForLessons(lessons: [Lesson], newLessonsSinceID serverId: Int, messagesSinceID messageID: Int, onSuccess successBlock: ((lessonsIDsWithNewServerVersions: [Int : Int], numNewLessons: Int, numNewMessages: Int) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func doFlagLesson(lesson: Lesson, withReason flagReason: FlagReason, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func postWord(word: Word, AsPracticeWithFilesInPath filePath: String, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func postWord(word: Word, withFilesInPath filePath: String, asReplyToWordWithID wordID: Int, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func deleteEventWithID(serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func postFeedback(feedback: String, toAuthorOfLessonWithID serverId: Int, onSuccess successBlock: (() -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func getEventsTargetingMeOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func getEventsIMayBeInterestedInOnSuccess(successBlock: ((events: [Event]) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal func pullAudio(audio: Audio, withProgress progressBlock: ((progress: Float) -> Void)?, onFailure failureBlock: ((error: NSError) -> Void)?)

internal class func hudFlashError(error: NSError)

*/

}
