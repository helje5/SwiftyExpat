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
      .onEndElement     { name        in println(">\(name)")          }
      .onStartNamespace { prefix, uri in println("+NS[\(prefix)] = \(uri)") }
      .onEndNamespace   { prefix      in println("-NS[\(prefix)]")    }
      .onCharacterData  { content     in println("TEXT: \(content)")  }
      .onError          { error       in println("ERROR \(error)")    }
  }
  
  override func tearDown() {
    p = nil
    super.tearDown()
  }
  
  func testSimpleParsing() {
    XCTAssert(true, "Pass")
    
    var result  : ExpatResult
    let testXML = "<hello xmlns='YoYo' a='5'><x>world</x></hello>"
    
    result = p.feed(testXML)
    XCTAssert(result)
    
    result = p.close() // EOF
    XCTAssert(result)
  }

  func testErrorHandling() {
    XCTAssert(true, "Pass")
    
    var result  : ExpatResult
    let testXML = "<hello xmlns='YoYo' a='5'>x>world</x></hello>"
    
    result = p.feed(testXML)
    println("Feed result: \(result)")
    XCTAssert(!result)
    
    result = p.close() // EOF
    XCTAssert(!result)
  }
}
