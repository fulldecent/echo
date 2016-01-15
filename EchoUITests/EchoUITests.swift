//
//  EchoUITests.swift
//  EchoUITests
//
//  Created by Full Decent on 1/13/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import XCTest

class EchoUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}

/*
class EchoUITests: XCTestCase {

override func setUp() {
super.setUp()
continueAfterFailure = false
XCUIApplication().launch()
let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
let controller = storyboard.instantiateViewControllerWithIdentifier("LanguageSelectController")
UIApplication.sharedApplication().keyWindow?.rootViewController = controller
}

override func tearDown() {
// Put teardown code here. This method is called after the invocation of each test method in the class.
super.tearDown()
}

func testExample() {
XCUIApplication().tables.staticTexts["Practice any word"].swipeDown()

// Use recording to get started writing UI tests.
// Use XCTAssert and related functions to verify your tests produce the correct results.
}

}
*/