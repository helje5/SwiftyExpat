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
class Expat : OutputStream, LogicValue {
  
  var parser   : XML_Parser = nil
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
    if parser {
      XML_ParserFree(parser)
    }
  }
  
  
  /* valid? */
  
  func getLogicValue() -> Bool {
    return parser != nil
  }
  
  
  /* feed the parser */
  
  func feed(cs: ConstUnsafePointer<CChar>, final: Bool = false) -> ExpatResult {
    let cslen   = cs ? strlen(cs) : 0 // cs? checks for a NULL C string
    let isFinal : Int32 = final ? 1 : 0
    let status  : XML_Status = XML_Parse(parser, cs, Int32(cslen), isFinal)
    
    switch status.value { // the Expat enum's don't work?
      case 1: return ExpatResult.OK
      case 2: return ExpatResult.Suspended
      default:
        let error = XML_GetErrorCode(parser)
        if let cb = errorCB {
          cb(error)
        }
        return ExpatResult.Error(error)
    }
  }
  
  func write(s: String) {
    let result = feed(s)
    
    // doesn't work with associated value?: assert(ExpatResult.OK == result)
    switch result {
      case .OK: break
      default: assert(false)
    }
  }
  
  func close() -> ExpatResult {
    if isClosed { return ExpatResult.OK /* do not complain */ }

    let result = feed("", final: true)
    
    resetCallbacks()
    isClosed = true
    
    XML_ParserFree(parser)
    parser = nil
    
    return result
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
  
  func onCharacterData(cb: ( String ) -> Void) -> Self {
    //const XML_Char *s, int len);
    XML_SetCharacterDataHandler(parser) {
      _, cs, cslen in
      assert(cslen > 0)
      if cslen > 0 {
        let s = String.fromCString(cs, length: Int(cslen))!
        cb(s)
      }
    }
    return self
  }
  
  func onError(cb: ( XML_Error ) -> Void) -> Self {
    errorCB = cb
    return self
  }
  var errorCB : (( XML_Error ) -> Void)? = nil
}

extension XML_Error : Printable {
  
  var description: String {
    switch self.value {
      // doesn't work?: case .XML_ERROR_NONE: return "OK"
      case 0 /* XML_ERROR_NONE           */: return "OK"
      case 1 /* XML_ERROR_NO_MEMORY      */: return "XMLError::NoMemory"
      case 2 /* XML_ERROR_SYNTAX         */: return "XMLError::Syntax"
      case 3 /* XML_ERROR_NO_ELEMENTS    */: return "XMLError::NoElements"
      case 4 /* XML_ERROR_INVALID_TOKEN  */: return "XMLError::InvalidToken"
      case 5 /* XML_ERROR_UNCLOSED_TOKEN */: return "XMLError::UnclosedToken"
      case 6 /* XML_ERROR_PARTIAL_CHAR   */: return "XMLError::PartialChar"
      case 7 /* XML_ERROR_TAG_MISMATCH   */: return "XMLError::TagMismatch"
      case 8 /* XML_ERROR_DUPLICATE_ATTRIBUTE */: return "XMLError::DupeAttr"
      // FIXME: complete me
      default:
        return "XMLError(\(self.value))"
    }
  }
}

enum ExpatResult : Printable, LogicValue {
  
  case OK
  case Suspended
  case Error(XML_Error) // we cannot make this XML_Error, fails swiftc
  
  var description: String {
    switch self {
      case .OK:               return "OK"
      case .Suspended:        return "Suspended"
      case .Error(let error): return "XMLError(\(error))"
    }
  }
  
  func getLogicValue() -> Bool {
    switch self {
      case .OK: return true
      default:  return false
    }
  }
}
