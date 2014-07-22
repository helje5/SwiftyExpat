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
public class Expat : OutputStream, LogicValue {
  
  var parser   : XML_Parser = nil
  var isClosed = false
  
  public init(encoding: String = "UTF-8", nsSeparator: Character = ":") {
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
  
  public func getLogicValue() -> Bool {
    return parser != nil
  }
  
  
  /* feed the parser */
  
  public func feedRaw
    (cs: ConstUnsafePointer<CChar>, final: Bool = false) -> ExpatResult
  {
    // v4: for some reason this accepts a 'String', but for such it doesn't
    //     actually work
    let cslen   = cs ? strlen(cs) : 0 // cs? checks for a NULL C string
    let isFinal : Int32      = final ? 1 : 0
    println("CS is \(cs) len \(cslen)")
    let status  : XML_Status = XML_Parse(parser, cs, Int32(cslen), isFinal)
    
    switch status { // the Expat enum's don't work?
      case XML_STATUS_OK:        return ExpatResult.OK
      case XML_STATUS_SUSPENDED: return ExpatResult.Suspended
      default:
        let error = XML_GetErrorCode(parser)
        if let cb = errorCB {
          cb(error)
        }
        return ExpatResult.Error(error)
    }
  }
  public func feed(s: String, final: Bool = false) -> ExpatResult {
    return s.withCString {
      (cs: ConstUnsafePointer<CChar>) -> ExpatResult in
      return self.feedRaw(cs, final: final)
    }
  }
  
  public func write(s: String) {
    let result = self.feed(s)
    
    // doesn't work with associated value?: assert(ExpatResult.OK == result)
    switch result {
      case .OK: break
      default: assert(false)
    }
  }
  
  public func close() -> ExpatResult {
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
  
  public func onStartElement(cb: ( String, [String : String] ) -> Void)-> Self {
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
  
  public func onEndElement(cb: ( String ) -> Void) -> Self {
    XML_SetEndElementHandler(parser) { _, name in
      let sName = String.fromCString(name)! // unwrap, must be set
      cb(sName)
    }
    return self
  }
  
  public func onStartNamespace(cb: ( String?, String ) -> Void) -> Self {
    XML_SetStartNamespaceDeclHandler(parser) {
      _, prefix, uri in
      let sPrefix = String.fromCString(prefix)
      let sURI    = String.fromCString(uri)!
      cb(sPrefix, sURI)
    }
    return self
  }
  
  public func onEndNamespace(cb: ( String? ) -> Void) -> Self {
    XML_SetEndNamespaceDeclHandler(parser) {
      _, prefix in
      let sPrefix = String.fromCString(prefix)
      cb(sPrefix)
    }
    return self
  }
  
  public func onCharacterData(cb: ( String ) -> Void) -> Self {
    //const XML_Char *s, int len);
    XML_SetCharacterDataHandler(parser) {
      _, cs, cslen in
      assert(cslen > 0)
      assert(cs    != nil)
      println("CS: \(cs[0]) len \(cslen)")
      if cslen > 0 {
        if let s = String.fromCString(cs, length: Int(cslen)) {
          cb(s)
        }
        else {
          println("ERROR: could not convert CString to String?! (len=\(cslen))")
          println("buf \(cs.memory)")
        }
      }
    }
    return self
  }
  
  public func onError(cb: ( XML_Error ) -> Void) -> Self {
    errorCB = cb
    return self
  }
  var errorCB : (( XML_Error ) -> Void)? = nil
}


/* hack to make some structs work */
// FIXME: can't figure out how to access XML_Error. Maybe because it
//        is not 'public'?

extension XML_Error : Equatable {
  // struct: init(_ value: UInt32); var value: UInt32;
}
extension XML_Status : Equatable {
  // struct: init(_ value: UInt32); var value: UInt32;
}
public func ==(lhs: XML_Error, rhs: XML_Error) -> Bool {
  // this just recurses (of course):
  //   return lhs == rhs
  // this failes, maybe because it's not public?:
  //   return lhs.value == rhs.value
  // Hard hack, does it actually work? :-)
  return isByteEqual(lhs, rhs)
}
public func ==(lhs: XML_Status, rhs: XML_Status) -> Bool {
  return isByteEqual(lhs, rhs)
}


extension XML_Error : Printable {
  
  public var description: String {
    switch self {
      // doesn't work?: case .XML_ERROR_NONE: return "OK"
      case XML_ERROR_NONE:                return "OK"
      case XML_ERROR_NO_MEMORY:           return "XMLError::NoMemory"
      case XML_ERROR_SYNTAX:              return "XMLError::Syntax"
      case XML_ERROR_NO_ELEMENTS:         return "XMLError::NoElements"
      case XML_ERROR_INVALID_TOKEN:       return "XMLError::InvalidToken"
      case XML_ERROR_UNCLOSED_TOKEN:      return "XMLError::UnclosedToken"
      case XML_ERROR_PARTIAL_CHAR:        return "XMLError::PartialChar"
      case XML_ERROR_TAG_MISMATCH:        return "XMLError::TagMismatch"
      case XML_ERROR_DUPLICATE_ATTRIBUTE: return "XMLError::DupeAttr"
      // FIXME: complete me
      default:
        return "XMLError(\(self))"
    }
  }
}

public enum ExpatResult : Printable, LogicValue {
  
  case OK
  case Suspended
  case Error(XML_Error) // we cannot make this XML_Error, fails swiftc
  
  public var description: String {
    switch self {
      case .OK:               return "OK"
      case .Suspended:        return "Suspended"
      case .Error(let error): return "XMLError(\(error))"
    }
  }
  
  public func getLogicValue() -> Bool {
    switch self {
      case .OK: return true
      default:  return false
    }
  }
}
