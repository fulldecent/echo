//
//  LanguageSelectControllerTests.swift
//  Echo
//
//  Created by William Entriken on 1/20/16.
//  Copyright © 2016 William Entriken. All rights reserved.
//

import XCTest

class LanguageSelectControllerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments.append("skipEntryViewController")
        app.launch()
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        let storyboard = UIStoryboard(name: "MainStoryboard", bundle: NSBundle.mainBundle())
        let controller = storyboard.instantiateViewControllerWithIdentifier("LanguageSelectController")
        UIApplication.sharedApplication().keyWindow?.rootViewController = controller

        
        XCUIApplication().tables.staticTexts["Easy words to confuse"].swipeUp()
        
        // Failed to find matching element please file bug (bugreport.apple.com) and provide output from Console.app
        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
