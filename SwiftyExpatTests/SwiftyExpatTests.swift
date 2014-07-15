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
  
  var p : Expat! = nil
    
  override func setUp() {
    super.setUp()
    
    p = Expat()
      .onStartElement   { name, attrs in println("<\(name) \(attrs)") }
      .onEndElement     { name in println(">\(name)") }
      .onStartNamespace { prefix, uri in println("+NS[\(prefix)] = \(uri)") }
      .onEndNamespace   { prefix      in println("-NS[\(prefix)]") }
  }
  
  override func tearDown() {
    p = nil
    super.tearDown()
  }
  
  func testSimpleParsing() {
    XCTAssert(true, "Pass")

    let testXML = "<hello xmlns='YoYo' a='5'><x>world</x></hello>"
    p.write(testXML)
    p.close() // EOF
  }
  
  /*
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock() {
        // Put the code you want to measure the time of here.
    }
  }
  */
}
