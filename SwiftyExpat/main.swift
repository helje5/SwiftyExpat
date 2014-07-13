//
//  main.swift
//  SwiftyExpat
//
//  Created by Helge Heß on 7/12/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

import Foundation

/*
typedef void (XMLCALL *XML_StartElementHandler) (void *userData,
  const XML_Char *name,
  const XML_Char **atts);
*/
func startCB(ud: COpaquePointer, name: CString, attrs: UnsafePointer<CString>) {
  
}

/*
typedef void (XMLCALL *XML_EndElementHandler) (void *userData,
const XML_Char *name);
*/
func endCB(ud: COpaquePointer, name: CString) {
  
}

func testit() {
  println("testing it ...")
  
  var p : XML_Parser = nil
  
  "UTF-8".withCString { cs in
    p = XML_ParserCreateNS(cs, 58 /* ':' */)
  }
  
  // XML_SetElementHandler(p, startCB, endCB)
}
