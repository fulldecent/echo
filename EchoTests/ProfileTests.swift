//
//  ProfileTests.swift
//  Echo
//
//  Created by Full Decent on 1/21/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import XCTest
@testable import Echo

class ProfileTests: XCTestCase {
    let testingUserCode = "f15700ba-4ebc-42d8-b08c-deadcafebabe"
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testIdempotence() {
        let profile1 = Profile.currentUser
        let profile2 = Profile.currentUser
        XCTAssert(profile1 === profile2)
    }
    
    func testEmptyJSONString() {
        let emptyString = ""
        let profile = Profile(JSONString: emptyString)
        XCTAssertNotNil(profile)
    }
    
    func testSyncToServer() {
        let emptyString = ""
        let profile = Profile(JSONString: emptyString)!
        profile.usercode = testingUserCode
        let expectation = expectationWithDescription("Swift Expectations")
        profile.syncOnlineOnSuccess(
            {
                (recommendedLessons) -> Void in
                expectation.fulfill()
            }
            , onFailure:
            {
                (error) -> Void in
                XCTFail(error.localizedDescription)
        }
        )
        waitForExpectationsWithTimeout(5.0, handler:nil)
    }
}
