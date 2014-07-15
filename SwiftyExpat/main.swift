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
  
  var p = Expat()
  
  p.onStartElement { name, attrs in println("name: \(name) \(attrs)") }

  let testXML = "<hello a='5'><x>world</x></hello>"
  p.write(testXML)
  p.write("") // EOF
  
  // XML_SetElementHandler(p, startCB, endCB)
}
