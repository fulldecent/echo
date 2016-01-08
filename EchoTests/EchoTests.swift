//
//  EchoTests.swift
//  EchoTests
//
//  Created by William Entriken on 1/7/16.
//
//

import XCTest
import Echo

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
