//
//  EchoTests.swift
//  EchoTests
//
//  Created by Full Decent on 1/15/17.
//  Copyright © 2017 William Entriken. All rights reserved.
//

import XCTest
@testable import Echo

class EchoTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLessonDownload() {
        Lesson.lesson(withId: 284) { lesson in
            XCTAssertEqual(lesson.id, 284)
            XCTAssertEqual(lesson.name, "US States")
        }
        
        waitForExpectations(timeout: 5000) { error in
            XCTFail()
        }
    }
    
}
