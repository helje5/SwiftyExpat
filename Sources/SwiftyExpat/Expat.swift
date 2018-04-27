//
//  Expat.swift
//  SwiftyExpat
//
//  Created by Helge Heß on 7/15/14.
//  Copyright (c) 2014-2018 Always Right Institute. All rights reserved.
//

#if Xcode // wasn't there an SPM flag?
#else
  import Expat
#endif

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
public final class Expat {
  
  public let nsSeparator : Character
  
  var parser   : XML_Parser! = nil
  var isClosed = false
  
  public init(encoding: String = "UTF-8", nsSeparator: Character = "<") {
    self.nsSeparator = nsSeparator
    let sepUTF8   = ("" + String(self.nsSeparator)).utf8
    let separator = sepUTF8[sepUTF8.startIndex]
    
    let parser = encoding.withCString { cs in
      // if I use parser, swiftc crashes (if Expat is a class)
      // FIXME: use String for separator, and codepoints to get the Int?
      XML_ParserCreateNS(cs, XML_Char(separator))
    }
    assert(parser != nil)
    self.parser = parser

    // TBD: what is the better way to do this?
    #if swift(>=4.0)
      let ud = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
    #else
      let ud = unsafeBitCast(self, UnsafeMutablePointer<Void>.self)
    #endif
    XML_SetUserData(parser, ud)
    
    registerCallbacks()
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
    (_ cs: UnsafePointer<CChar>, final: Bool = false) -> ExpatResult
  {
    // v4: for some reason this accepts a 'String', but for such it doesn't
    //     actually work
    #if swift(>=4.0)
      let cslen = strlen(cs) // cs? checks for a NULL C string
    #else
      let cslen = cs != nil ? strlen(cs) : 0 // cs? checks for a NULL C string
    #endif
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
  public func feed(_ s: String, final: Bool = false) -> ExpatResult {
    return s.withCString { cs -> ExpatResult in
      return self.feedRaw(cs, final: final)
    }
  }
  
  public func write(_ s: String) {
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
  
  func registerCallbacks() {
    XML_SetStartElementHandler(parser) { ud, name, attrs in
      #if swift(>=4.0)
        let me = unsafeBitCast(ud, to: Expat.self)
        guard let cb = me.cbStartElement else { return }
        let sName = name != nil ? String(cString: name!) : ""
      #else
        let me = unsafeBitCast(ud, Expat.self)
        guard let cb = me.cbStartElement else { return }
        let sName = String.fromCString(name)! // unwrap, must be set
      #endif
      
      
      // FIXME: we should not copy stuff, but have a wrapper which works on the
      //        attrs structure 'on demand'
      let sAttrs = makeAttributesDictionary(attrs)
      cb(sName, sAttrs)
    }
    
    XML_SetEndElementHandler(parser) { ud, name in
      #if swift(>=4.0)
        let me = unsafeBitCast(ud, to: Expat.self)
        guard let cb = me.cbEndElement else { return }
        let sName = String(cString: name!)    // force unwrap, must be set
        cb(sName)
      #else
        let me = unsafeBitCast(ud, Expat.self)
        guard let cb = me.cbEndElement else { return }
        let sName = String.fromCString(name)! // force unwrap, must be set
        cb(sName)
      #endif
    }
    
    XML_SetStartNamespaceDeclHandler(parser) { ud, prefix, uri in
      #if swift(>=4.0)
        let me = unsafeBitCast(ud, to: Expat.self)
        guard let cb = me.cbStartNS else { return }
        let sPrefix = prefix != nil ? String(cString: prefix!) : nil
        let sURI    = String(cString: uri!)
        cb(sPrefix, sURI)
      #else
        let me = unsafeBitCast(ud, Expat.self)
        guard let cb = me.cbStartNS else { return }
        let sPrefix = String.fromCString(prefix)
        let sURI    = String.fromCString(uri)!
        cb(sPrefix, sURI)
      #endif
    }
    XML_SetEndNamespaceDeclHandler(parser) { ud, prefix in
      #if swift(>=4.0)
        let me = unsafeBitCast(ud, to: Expat.self)
        guard let cb = me.cbEndNS else { return }
        let sPrefix = prefix != nil ? String(cString: prefix!) : nil
        cb(sPrefix)
      #else
        let me = unsafeBitCast(ud, Expat.self)
        guard let cb = me.cbEndNS else { return }
        let sPrefix = String.fromCString(prefix)
        cb(sPrefix)
      #endif
    }
    
    XML_SetCharacterDataHandler(parser) { ud, cs, cslen in
      assert(cslen > 0)
      assert(cs    != nil)
      // println("CS: \(cs[0]) len \(cslen)")
      guard cslen > 0 else { return }

      #if swift(>=4.0)
        let me = unsafeBitCast(ud, to: Expat.self)
        guard let cb = me.cbCharacterData else { return }

        let cs2 = UnsafeRawPointer(cs!).assumingMemoryBound(to: UInt8.self)
        let bp  = UnsafeBufferPointer(start: cs2, count: Int(cslen))
        let s   = String(decoding: bp, as: UTF8.self)
        cb(s)
      #else
        let me = unsafeBitCast(ud, Expat.self)
        guard let cb = me.cbCharacterData else { return }

        guard let s = String.fromCString(cs, length: Int(cslen)) else {
          print("ERROR: could not convert CString to String?! (len=\(cslen))")
          dumpCharBuf(cs, len: Int(cslen))
          return
        }
        
        cb(s)
      #endif
    }
  }
  
  func resetCallbacks() {
    // reset callbacks to fixup any potential cycles
    cbStartElement  = nil
    cbEndElement    = nil
    cbStartNS       = nil
    cbEndNS         = nil
    cbCharacterData = nil
    cbError         = nil
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
  
  #if swift(>=3.0)
    public func onStartElement(cb: @escaping StartElementHandler)-> Self {
      cbStartElement = cb
      return self
    }
    public func onEndElement(cb: @escaping EndElementHandler) -> Self {
      cbEndElement = cb
      return self
    }
  
    public func onStartNamespace(cb: @escaping StartNamespaceHandler) -> Self {
      cbStartNS = cb
      return self
    }
    public func onEndNamespace(cb: @escaping EndNamespaceHandler) -> Self {
      cbEndNS = cb
      return self
    }
  
    public func onCharacterData(cb: @escaping CDataHandler) -> Self {
      cbCharacterData = cb
      return self
    }
  
    public func onError(cb: @escaping ErrorHandler) -> Self {
      cbError = cb
      return self
    }
  #else
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
  #endif
}


public extension Expat { // Namespaces
  
  public typealias StartElementNSHandler =
                     ( String, String, [String : String] ) -> Void
  public typealias EndElementNSHandler = ( String, String ) -> Void
  
  #if swift(>=3.2)
    public func onStartElementNS(cb: @escaping StartElementNSHandler) -> Self {
      let sep = self.nsSeparator // so that we don't capture 'self' (necessary?)
      return onStartElement {
        // split(separator:maxSplits:omittingEmptySubsequences:)
        let comps = $0.split(separator: sep, maxSplits: 1,
                             omittingEmptySubsequences: true)
        cb(String(comps[0]), String(comps[1]), $1)
      }
    }
  
    public func onEndElementNS(cb: @escaping EndElementNSHandler) -> Self {
      let sep = self.nsSeparator // so that we don't capture 'self' (necessary?)
      return onEndElement {
        let comps = $0.split(separator: sep, maxSplits: 1,
                             omittingEmptySubsequences: true)
        cb(String(comps[0]), String(comps[1]))
      }
    }
  #else
    public func onStartElementNS(cb: StartElementNSHandler) -> Self {
      let sep = self.nsSeparator // so that we don't capture 'self' (necessary?)
      return onStartElement {
        let comps = $0.characters.split(sep, maxSplit: 1, allowEmptySlices: false)
                                 .map { String($0) }
        cb(comps[0], comps[1], $1)
      }
    }
  
    public func onEndElementNS(cb: EndElementNSHandler) -> Self {
      let sep = self.nsSeparator // so that we don't capture 'self' (necessary?)
      return onEndElement {
        let comps = $0.characters.split(sep, maxSplit: 1, allowEmptySlices: false)
                                 .map { String($0) }
        cb(comps[0], comps[1])
      }
    }
  #endif
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

public enum ExpatResult : CustomStringConvertible {
  
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

func dumpCharBuf(_ buf: UnsafePointer<CChar>, len : Int) {
  print("*-- buffer (len=\(len))")
  for i in 0 ..< len {
    let cp = Int(buf[i])
    #if swift(>=3.0)
      let c  = Character(UnicodeScalar(cp)!)
    #else
      let c  = Character(UnicodeScalar(cp))
    #endif
    print("  [\(i)]: \(cp) \(c)")
  }
  print("---")
}

#if swift(>=3.0)

func makeAttributesDictionary
  (_ attrs : UnsafeMutablePointer<UnsafePointer<XML_Char>?>?)
  -> [ String : String ]
{
  var sAttrs = [ String : String ]()
  guard let attrs = attrs else { return sAttrs }
  var i = 0
  while attrs[i] != nil {
    let name  = String(cString: attrs[i]!)
    let value = attrs[i + 1] != nil ? String(cString: attrs[i + 1]!) : ""
    sAttrs[name] = value
    i += 2
  }
  return sAttrs
}
#else

func makeAttributesDictionary
  (_ attrs : UnsafeMutablePointer<UnsafePointer<XML_Char>>)
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

#endif
