//
//  main.swift
//  SwiftyExpat
//
//  Created by Helge Heß on 7/12/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

import Foundation

struct Expat : OutputStream {
  
  let parser : XML_Parser
  
  init(encoding: String = "UTF-8", nsSeparator: Character = ":") {
    let sepUTF8   = ("" + nsSeparator).utf8
    let separator = sepUTF8[sepUTF8.startIndex]
    
    var newParser : XML_Parser = nil
    encoding.withCString { cs in
      // if I use parser, swiftc crashes (if Expat is a class)
      // FIXME: use String for separator, and codepoints to get the Int?
      newParser = XML_ParserCreateNS(cs, 58 /* ':' */)
    }
    assert(newParser != nil)
    
    parser = newParser
  }
  
  
  /* feed the parser */
  
  func write(cs: CString) {
    let cslen   = strlen(cs)
    let isFinal = cslen == 0
    XML_Parse(parser, cs, Int32(cslen), isFinal ? 1 : 0)
  }
  
  func write(s: String) {
    s.withCString { cs in self.write(cs) }
  }
 
  
  /* callbacks */
  
  func onStartElement(cb: ( String ) -> Void) {
    XML_SetStartElementHandler(parser, {
      // void *userData, const XML_Char *name, const XML_Char **atts
      ( userData, name, attrs ) in
      let sName = String.fromCString(name)! // unwrap, must be set
      cb(sName)
    })
  }
}

func testit() {
  println("testing it ...")
  
  var p = Expat()
  
  p.onStartElement { name in println("name: \(name)") }

  let testXML = "<hello a='5'><x>world</x></hello>"
  p.write(testXML)
  p.write("") // EOF
  
  // XML_SetElementHandler(p, startCB, endCB)
}
