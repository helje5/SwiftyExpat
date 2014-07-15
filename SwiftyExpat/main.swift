//
//  main.swift
//  SwiftyExpat
//
//  Created by Helge Heß on 7/12/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

import Foundation

func testit() {
  println("testing it ...")
  
  var p : XML_Parser = nil
  
  "UTF-8".withCString { cs in
    p = XML_ParserCreateNS(cs, 58 /* ':' */)
  }
  
  XML_SetStartElementHandler(p, {
    // void *userData, const XML_Char *name, const XML_Char **atts
    ( userData, name, attrs ) in
    println("name: \(name) \(attrs)")
  })

  let testXML = "<hello>world</hello>"
  testXML.withCString { cs in
    XML_Parse(p, cs, Int32(strlen(cs)), 1)
  }
  
  // XML_SetElementHandler(p, startCB, endCB)
}
