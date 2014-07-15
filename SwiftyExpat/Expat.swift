//
//  Expat.swift
//  SwiftyExpat
//
//  Created by Helge Heß on 7/15/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

/**
 * Simple wrapper for the Expat parser. Though the block based Expat is
 * reasonably easy to use as-is.
 *
 * Done as a class as this is no value object (and struct's have no deinit())
 */
class Expat : OutputStream {
  
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
  deinit {
    XML_ParserFree(parser)
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
  
  func close() {
    
  }
  
  
  /* callbacks */
  
  func onStartElement(cb: ( String, [ String : String ] ) -> Void) -> Self {
    XML_SetStartElementHandler(parser) {
      // void *userData, const XML_Char *name, const XML_Char **atts
      ( userData, name, attrs ) in
      let sName = String.fromCString(name)! // unwrap, must be set
      
      var sAttrs = [ String : String]()
      if attrs != nil {
        var i = 0
        while attrs[i] { // Note: you cannot compare it with nil?!
          let name  = String.fromCString(attrs[i])
          let value = String.fromCString(attrs[i + 1])
          sAttrs[name!] = value! // force unwrap
          i += 2
        }
      }
      
      cb(sName, sAttrs)
    }
    
    return self
  }
  
}
