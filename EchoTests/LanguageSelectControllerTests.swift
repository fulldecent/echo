//
//  LanguageSelectControllerTests.swift
//  Echo
//
//  Created by Full Decent on 4/11/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import XCTest
@testable import Echo

class LanguageSelectControllerTests: XCTestCase {

    var viewController: LanguageSelectController!

    override func setUp() {
        super.setUp()
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle(forClass: self.dynamicType))
        viewController = storyboard.instantiateViewControllerWithIdentifier("LanguageSelectController") as! LanguageSelectController
        viewController.loadView()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertTrue(true, "A passing test")
    }
}
