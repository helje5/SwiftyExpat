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

extension String {
  
  static func fromCString(cs: CString, length: Int?) -> String? {
    if length == .None { // no length given, use \0 standard variant
      return String.fromCString(cs)
    }
    
    // hh: this is really lame, there must be a better way :-)
    // Also: it could be a constant string! So we probably need to copy ...
    if let buf = cs.persist() {
      return buf.withUnsafePointerToElements {
        (p: UnsafePointer<CChar>) in
        let old = p[length!]
        p[length!] = 0
        let s = String.fromCString(CString(p))
        p[length!] = old
        return s
      }
    }
    return nil
  }

}
