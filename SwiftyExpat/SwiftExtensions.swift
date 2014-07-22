//
//  SwiftExtensions.swift
//  SwiftyExpat
//
//  Created by Helge Heß on 6/18/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

// Those are mostly dirty hacks to get what I need :-)
// I would be very interested in better way to do those things, W/O using
// Foundation.

// Hack to compare values if we don't have access to the members of the struct,
// eg XML_Error in v0.0.4
public func isByteEqual<T>(var lhs: T, var rhs: T) -> Bool {
  return memcmp(&lhs, &rhs, UInt(sizeof(T))) == 0
}

extension String {
  
  static func fromCString
    (cs: ConstUnsafePointer<CChar>, length: Int!) -> String?
  {
    if length == .None { // no length given, use \0 standard variant
      return String.fromCString(cs)
    }
    
    // hh: this is really lame, there must be a better way :-)
    // Also: it could be a constant string! So we really need to copy ...
    // NOTE: this is really really wrong, don't use it in actual projects! :-)
    let unconst = UnsafePointer<CChar>(cs)
    let old = cs[length]
    unconst[length] = 0
    let s   = String.fromCString(cs)
    unconst[length] = old
    
    return nil
  }

}
