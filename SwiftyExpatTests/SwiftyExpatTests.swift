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
      .onStartElement   { name, attrs in print("<\(name) \(attrs)")       }
      .onEndElement     { name        in print(">\(name)")                }
      .onStartNamespace { prefix, uri in print("+NS[\(prefix)] = \(uri)") }
      .onEndNamespace   { prefix      in print("-NS[\(prefix)]")          }
      .onCharacterData  { content     in print("TEXT: \(content)")        }
      .onError          { error       in print("ERROR \(error)")          }
  }
  
  override func tearDown() {
    p = nil
    super.tearDown()
  }
  
  func testSimpleParsing() {
    print("\n----------")
    
    var result  : ExpatResult
    let testXML = "<hello xmlns='YoYo' a='5'><x>world</x></hello>"
    
    result = p.feed(testXML)
    XCTAssert(result)
    
    result = p.close() // EOF
    print("Feed result: \(result)")
    XCTAssert(result)
  }

  func testErrorHandling() {
    print("\n----------")
    
    var result  : ExpatResult
    let testXML = "<hello xmlns='YoYo' a='5'>x>world</x></hello>"
    
    result = p.feed(testXML)
    print("Feed result: \(result)")
    XCTAssert(!result)
    
    result = p.close() // EOF
    XCTAssert(!result)
  }
}
