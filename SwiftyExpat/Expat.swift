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
 *
 * Sample:
 *  let p = Expat()
 *    .onStartElement   { name, attrs in println("<\(name) \(attrs)")       }
 *    .onEndElement     { name        in println(">\(name)")                }
 *    .onError          { error       in println("ERROR: \(error)")         }
 *  p.write("<hello>world</hello>")
 *  p.close()
 */
public final class Expat : OutputStreamType, BooleanType {
  
  public let nsSeparator : Character
  
  var parser      : XML_Parser! = nil
  var isClosed    = false
  
  public init(encoding: String = "UTF-8", nsSeparator: Character = "<") {
    self.nsSeparator = nsSeparator
    let sepUTF8   = ("" + String(self.nsSeparator)).utf8
    let separator = sepUTF8[sepUTF8.startIndex]
    
    // self.parser = ... doesn't work because of the 'self' bitcast
    let newParser : XML_Parser = encoding.withCString { cs in
      // if I use parser, swiftc crashes (if Expat is a class)
      // FIXME: use String for separator, and codepoints to get the Int?
      let newParser = XML_ParserCreateNS(cs, XML_Char(separator))
      assert(newParser != nil)
      
      // TBD: what is the better way to do this?
      let ud = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
      XML_SetUserData(newParser, ud)
      return newParser
    }
    
    parser = newParser
  }
  deinit {
    if parser != nil {
      XML_ParserFree(parser)
      parser = nil
    }
  }
  
  
  /* valid? */
  
  public var boolValue : Bool {
    return parser != nil
  }
  
  
  /* feed the parser */
  
  public func feedRaw
    (cs: UnsafePointer<CChar>, final: Bool = false) -> ExpatResult
  {
    // v4: for some reason this accepts a 'String', but for such it doesn't
    //     actually work
    let cslen   = cs != nil ? strlen(cs) : 0 // cs? checks for a NULL C string
    let isFinal : Int32 = final ? 1 : 0
    
    //dumpCharBuf(cs, Int(cslen))
    let status  : XML_Status = XML_Parse(parser, cs, Int32(cslen), isFinal)
    
    switch status { // the Expat enum's don't work?
      case XML_STATUS_OK:        return ExpatResult.OK
      case XML_STATUS_SUSPENDED: return ExpatResult.Suspended
      default:
        let error = XML_GetErrorCode(parser)
        if let cb = cbError {
          cb(error)
        }
        return ExpatResult.Error(error)
    }
  }
  public func feed(s: String, final: Bool = false) -> ExpatResult {
    return s.withCString { cs -> ExpatResult in
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
    return result
  }
  
  func registerCallbacks() {
    XML_SetStartElementHandler(parser) { ud, name, attrs in
      let me = unsafeBitCast(ud, Expat.self)
      guard let cb = me.cbStartElement else { return }
      
      let sName = String.fromCString(name)! // unwrap, must be set
      
      // FIXME: we should not copy stuff, but have a wrapper which works on the
      //        attrs structure 'on demand'
      let sAttrs = makeAttributesDictionary(attrs)
      cb(sName, sAttrs)
    }
    
    XML_SetEndElementHandler(parser) { ud, name in
      let me = unsafeBitCast(ud, Expat.self)
      guard let cb = me.cbEndElement else { return }
      
      let sName = String.fromCString(name)! // unwrap, must be set
      cb(sName)
    }
    
    XML_SetStartNamespaceDeclHandler(parser) { ud, prefix, uri in
      let me = unsafeBitCast(ud, Expat.self)
      guard let cb = me.cbStartNS else { return }
      
      let sPrefix = String.fromCString(prefix)
      let sURI    = String.fromCString(uri)!
      cb(sPrefix, sURI)
    }
    XML_SetEndNamespaceDeclHandler(parser) { ud, prefix in
      let me = unsafeBitCast(ud, Expat.self)
      guard let cb = me.cbEndNS else { return }
      
      let sPrefix = String.fromCString(prefix)
      cb(sPrefix)
    }
    
    XML_SetCharacterDataHandler(parser) { ud, cs, cslen in
      assert(cslen > 0)
      assert(cs    != nil)
      // println("CS: \(cs[0]) len \(cslen)")
      guard cslen > 0 else { return }

      let me = unsafeBitCast(ud, Expat.self)
      guard let cb = me.cbCharacterData else { return }

      guard let s = String.fromCString(cs, length: Int(cslen)) else {
        print("ERROR: could not convert CString to String?! (len=\(cslen))")
        dumpCharBuf(cs, len: Int(cslen))
        return
      }
      
      cb(s)
    }
  }
  
  func resetCallbacks() {
    // reset callbacks to fixup any potential cycles
    cbStartElement = nil
    cbEndElement   = nil
    
    // we really don't need to do this. nothing is retained here
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
  
  public typealias AttrDict              = [ String : String ]
  public typealias StartElementHandler   = ( String, AttrDict) -> Void
  public typealias EndElementHandler     = ( String ) -> Void
  public typealias StartNamespaceHandler = ( String?, String ) -> Void
  public typealias EndNamespaceHandler   = ( String? ) -> Void
  public typealias CDataHandler          = ( String? ) -> Void
  public typealias ErrorHandler          = ( XML_Error ) -> Void
  
  var cbStartElement  : StartElementHandler?
  var cbEndElement    : EndElementHandler?
  var cbStartNS       : StartNamespaceHandler?
  var cbEndNS         : EndNamespaceHandler?
  var cbCharacterData : CDataHandler?
  var cbError         : ErrorHandler?
  
  public func onStartElement(cb: StartElementHandler)-> Self {
    cbStartElement = cb
    return self
  }
  public func onEndElement(cb: EndElementHandler) -> Self {
    cbEndElement = cb
    return self
  }
  
  public func onStartNamespace(cb: StartNamespaceHandler) -> Self {
    cbStartNS = cb
    return self
  }
  public func onEndNamespace(cb: EndNamespaceHandler) -> Self {
    cbEndNS = cb
    return self
  }
  
  public func onCharacterData(cb: CDataHandler) -> Self {
    cbCharacterData = cb
    return self
  }
  
  public func onError(cb: ErrorHandler) -> Self {
    cbError = cb
    return self
  }
}


public extension Expat { // Namespaces
  
  public typealias StartElementNSHandler =
                     ( String, String, [String : String] ) -> Void
  public typealias EndElementNSHandler = ( String, String ) -> Void
  
  public func onStartElementNS(cb: StartElementNSHandler) -> Self {
    let sep = self.nsSeparator // so that we don't capture 'self' (necessary?)
    return onStartElement {
      let comps = split($0.characters, maxSplit: 1, allowEmptySlices: false) {
                    $0 == sep
                  }.map { String($0) }
      cb(comps[0], comps[1], $1)
    }
  }
  
  public func onEndElementNS(cb: EndElementNSHandler) -> Self {
    let sep = self.nsSeparator // so that we don't capture 'self' (necessary?)
    return onEndElement {
      let comps = split($0.characters, maxSplit: 1, allowEmptySlices: false) {
                    $0 == sep
                  }.map { String($0) }
      cb(comps[0], comps[1])
    }
  }
  
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
  return isByteEqual(lhs, rhs: rhs)
}
public func ==(lhs: XML_Status, rhs: XML_Status) -> Bool {
  return isByteEqual(lhs, rhs: rhs)
}


extension XML_Error : CustomStringConvertible {
  
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

public enum ExpatResult : CustomStringConvertible, BooleanType {
  
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
  
  public var boolValue : Bool {
    switch self {
      case .OK: return true
      default:  return false
    }
  }
}


/* debug */

func dumpCharBuf(buf: UnsafePointer<CChar>, len : Int) {
  print("*-- buffer (len=\(len))")
  for var i = 0; i < len; i++ {
    let cp = Int(buf[i])
    let c  = Character(UnicodeScalar(cp))
    print("  [\(i)]: \(cp) \(c)")
  }
  print("---")
}

func makeAttributesDictionary
  (attrs : UnsafeMutablePointer<UnsafePointer<XML_Char>>)
  -> [ String : String ]
{
  var sAttrs = [ String : String ]()
  if attrs != nil {
    var i = 0
    while attrs[i] != nil {
      let name  = String.fromCString(attrs[i])
      let value = String.fromCString(attrs[i + 1])
      sAttrs[name!] = value! // force unwrap
      i += 2
    }
  }
  return sAttrs
}
