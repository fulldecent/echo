//
//  EchoTests.swift
//  EchoTests
//
//  Created by Full Decent on 1/13/16.
//  Copyright © 2016 William Entriken. All rights reserved.
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
    
    func testCreateAudio() {
        let word = Echo.Word(packed: ["name": "a word"])
        let _ = Audio(word: word)
    }
    
}
