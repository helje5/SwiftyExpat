//
//  SwiftyExpatTests.swift
//  SwiftyExpatTests
//
//  Created by Helge Heß on 7/12/14.
//  Copyright (c) 2014-2020 Always Right Institute. All rights reserved.
//

import Cocoa
import XCTest
import SwiftyExpat
#if Xcode // wasn't there an SPM flag?
#else
  import Expat
#endif

class SwiftyExpatTests: XCTestCase {
  
  var p : Expat! = nil
    
  override func setUp() {
    super.setUp()
    
    p = Expat()
      .onStartElement   { name, attrs in print("<\(name) \(attrs)")       }
      .onEndElement     { name        in print(">\(name)")                }
      .onStartNamespace { prefix, uri in print("+NS[\(prefix ?? "")] = \(uri)")}
      .onEndNamespace   { prefix      in print("-NS[\(prefix ?? "")]")    }
      .onCharacterData  { content     in print("TEXT: \(content ?? "")")  }
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
    XCTAssert(result.boolValue)
    
    result = p.close() // EOF
    print("Feed result: \(result)")
    XCTAssert(result.boolValue)
  }

  func testErrorHandling() {
    print("\n----------")
    
    var result  : ExpatResult
    let testXML = "<hello xmlns='YoYo' a='5'>x>world</x></hello>"
    
    result = p.feed(testXML)
    print("Feed result: \(result)")
    XCTAssert(!result.boolValue)
    
    result = p.close() // EOF
    XCTAssert(!result.boolValue)
  }
  
  func testRawAPI() {
    print("\n----------")
    
    let p = XML_ParserCreate("UTF-8")
    defer { XML_ParserFree(p); }
    
    XML_SetStartElementHandler(p) { _, name, attrs in
      #if swift(>=3.0)
        let nameString = String(cString: name!)
      #else
        let nameString = String.fromCString(name)!
      #endif
      print("start tag \(nameString)")
    }
    XML_SetEndElementHandler  (p) { _, name in
      #if swift(>=3.0)
        let nameString = String(cString: name!)
      #else
        let nameString = String.fromCString(name)!
      #endif
      print("end tag \(nameString)")
    }
    
    XML_Parse(p, "<hello/>", 8, 0)
    XML_Parse(p, "", 0, 1)
  }

  static var allTests = [
    ( "testSimpleParsing" , testSimpleParsing ),
    ( "testErrorHandling" , testErrorHandling ),
    ( "testRawAPI"        , testRawAPI        )
  ]
}
