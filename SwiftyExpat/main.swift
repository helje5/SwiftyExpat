//
//  main.swift
//  SwiftyExpat
//
//  Created by Helge Heß on 7/12/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

import Foundation

func testit() {
  println("testing it ...")
  
  XML_ParserCreateNS(CString("UTF-8"), 58 /* ':' */)
}
