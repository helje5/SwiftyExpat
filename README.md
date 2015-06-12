SwiftyExpat
===========

Simple wrapper for the Expat XML parser.

###Targets

Updated to use Swift v2.0p1 (aka Xcode 7b).

Note: The SwiftyExpat version for Swift 1.x was using a modified Expat which used
blocks instead of C function pointer callbacks. Swift 2 now supports C function
pointer calls and hence this project got rewritten for this.

The project includes two targets:
- SwiftyExpat
- SwiftyExpatTests

I suggest you start by looking at the SwiftyExpatTests.

####SwiftyExpat

This is a tiny framework wth a small Swift class to make the API nicer.
Though this is not really necessary - Expat is reasonably easy to use from 
Swift as-is.

```Swift
let p = Expat()
  .onStartElement   { name, attrs in println("<\(name) \(attrs)")       }
  .onEndElement     { name        in println(">\(name)")                }
  .onStartNamespace { prefix, uri in println("+NS[\(prefix)] = \(uri)") }
  .onEndNamespace   { prefix      in println("-NS[\(prefix)]")          }
  .onError          { error       in println("ERROR: \(error)")         }
p.write("<hello>world</hello>")
p.close()
```

The raw Expat API works like this:
```Swift
let p = XML_ParserCreate("UTF-8")
XML_SetStartElementHandler(p) { _, name, attrs in println("start tag \(name)") }
XML_SetEndElementHandler  (p) { _, name        in println("end tag \(name)") }

XML_Parse(parser, "<hello/>", 8, 0)
XML_Parse(parser, "", 0, 1)

XML_ParserFree(p); p = nil
```
You get the idea ...

Note: The closures in the raw API cannot capture variables. If you need to pass
around context (very likely ...), you need to fill the regular Expat 'user data' 
field (which the wrapper does, if you need an example).

####SwiftyExpatTests

Just a tiny demo on how to invoke the parser.

###Contact

[@helje5](http://twitter.com/helje5) | helge@alwaysrightinstitute.com
