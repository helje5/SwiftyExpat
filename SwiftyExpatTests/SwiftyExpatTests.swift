//
//  SwiftyExpatTests.swift
//  SwiftyExpatTests
//
//  Created by Helge Heß on 7/12/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

import Cocoa
import XCTest
import SwiftyExpat

class SwiftyExpatTests: XCTestCase {
    
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testExample() {
    // This is an example of a functional test case.
    XCTAssert(true, "Pass")
    SwiftyExpat.testit()
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock() {
        // Put the code you want to measure the time of here.
    }
  }
    
}
