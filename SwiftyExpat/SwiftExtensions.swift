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
  return memcmp(&lhs, &rhs, sizeof(T)) == 0
}

extension String {
  
  static func fromCString
    (cs: UnsafePointer<CChar>, length: Int!) -> String?
  {
    if length == .None { // no length given, use \0 standard variant
      return String.fromCString(cs)
    }
    
    let buflen = length + 1
    let buf    = UnsafeMutablePointer<CChar>.alloc(buflen)
    memcpy(buf, cs, length)
    buf[length] = 0 // zero terminate
    let s = String.fromCString(buf)
    buf.dealloc(buflen)
    return s
  }

}
