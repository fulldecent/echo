//
//  NetworkManagerTest.swift
//  Echo
//
//  Created by William Entriken on 3/10/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import XCTest
@testable import Echo

class LessonSetTests: XCTestCase {
    var lessonSet: LessonSet!
    
    override func setUp() {
        super.setUp()
        lessonSet = LessonSet(name: "TEST")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLessonTransferProgress() {
        XCTAssert(false)
    }
    
    func testWriteToDisk() {
        lessonSet.writeToDisk()
        XCTAssert(true)
    }
    
    func testSyncStaleLessonsWithProgress() {
        XCTAssert(false)

    }

    func testDeleteLesson() {
        let lesson = Lesson()
        lessonSet.addOrUpdateLesson(lesson)
        let beforeCount = lessonSet.lessons.count
        lessonSet.deleteLesson(lesson)
        let afterCount = lessonSet.lessons.count
        XCTAssertEqual(afterCount, beforeCount - 1)
    }
    
    func testDeleteLessonAndStopSharing() {
        let lesson = Lesson()
        lessonSet.addOrUpdateLesson(lesson)
        let beforeCount = lessonSet.lessons.count
        lessonSet.deleteLesson(lesson)
        let afterCount = lessonSet.lessons.count
        XCTAssertEqual(afterCount, beforeCount - 1)
    }
    
    func testAddOrUpdateLesson() {
        let lesson = Lesson()
        let beforeCount = lessonSet.lessons.count
        lessonSet.addOrUpdateLesson(lesson)
        let afterCount = lessonSet.lessons.count
        lessonSet.deleteLesson(lesson)
        XCTAssertEqual(afterCount, beforeCount + 1)
    }
    
    func testSetRemoteUpdatesForLessonsWithIDs() {
        let lesson = Lesson()
        lessonSet.addOrUpdateLesson(lesson)
        lesson.serverId = 25
        lesson.remoteChangesSinceLastSync = false
        lessonSet.setRemoteUpdatesForLessonsWithIDs([25])
        XCTAssertEqual(lesson.remoteChangesSinceLastSync, true)
    }
    
    func testGetWordWithFiles() {
        let asyncExpectation = expectationWithDescription("ready")
        let testWordId = 500
        LessonSet.getWordWithFiles(testWordId, withProgress: {
            (word, progress) in
            XCTAssertEqual(word.serverId, 500)
            asyncExpectation.fulfill()
            }, onFailure: {
                (error) -> Void in
                XCTAssertNil(error, "Request failure")
        })
        self.waitForExpectationsWithTimeout(5) { error in
            XCTAssertNil(error, "Request timeout")
        }
    }
}
