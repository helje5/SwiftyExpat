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
  
  let parser   : XML_Parser
  var isClosed = false
  
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
    println("freeing parser ...")
    XML_ParserFree(parser)
  }
  
  
  /* feed the parser */
  
  func write(cs: CString) {
    let cslen = strlen(cs)
    XML_Parse(parser, cs, Int32(cslen), 0)
  }
  
  func write(s: String) {
    s.withCString { cs in self.write(cs) }
  }
  
  func close() {
    if isClosed { return }

    let isFinal : Int32 = 1
    XML_Parse(parser, "", 0, isFinal)
    
    resetCallbacks()
    isClosed = true
  }
  
  func resetCallbacks() {
    // reset callbacks to fixup any potential cycles
    XML_SetElementHandler           (parser, nil, nil)
    XML_SetCharacterDataHandler     (parser, nil)
    XML_SetProcessingInstructionHandler(parser, nil)
    XML_SetCommentHandler           (parser, nil)
    XML_SetCdataSectionHandler      (parser, nil, nil)
    XML_SetDefaultHandler           (parser, nil)
    XML_SetDefaultHandlerExpand     (parser, nil)
    XML_SetDoctypeDeclHandler       (parser, nil, nil)
    XML_SetUnparsedEntityDeclHandler(parser, nil)
    XML_SetNotationDeclHandler      (parser, nil)
    XML_SetNamespaceDeclHandler     (parser, nil, nil)
    XML_SetNotStandaloneHandler     (parser, nil)
    XML_SetExternalEntityRefHandler (parser, nil)
    XML_SetSkippedEntityHandler     (parser, nil)
    XML_SetUnknownEncodingHandler   (parser, nil, nil)
  }
  
  
  /* callbacks */
  
  func onStartElement(cb: ( String, [ String : String ] ) -> Void) -> Self {
    XML_SetStartElementHandler(parser) {
      _, name, attrs in
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
  
  func onEndElement(cb: ( String ) -> Void) -> Self {
    XML_SetEndElementHandler(parser) { _, name in
      let sName = String.fromCString(name)! // unwrap, must be set
      cb(sName)
    }
    return self
  }
  
  func onStartNamespace(cb: ( String?, String ) -> Void) -> Self {
    XML_SetStartNamespaceDeclHandler(parser) {
      _, prefix, uri in
      let sPrefix = String.fromCString(prefix)
      let sURI    = String.fromCString(uri)!
      cb(sPrefix, sURI)
    }
    return self
  }
  func onEndNamespace(cb: ( String? ) -> Void) -> Self {
    XML_SetEndNamespaceDeclHandler(parser) {
      _, prefix in
      let sPrefix = String.fromCString(prefix)
      cb(sPrefix)
    }
    return self
  }
  
}
