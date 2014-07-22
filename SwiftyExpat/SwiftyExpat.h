//
//  SwiftyExpat.h
//  SwiftyExpat
//
//  Created by Helge Heß on 7/12/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//! Project version number for SwiftyExpat.
FOUNDATION_EXPORT double SwiftyExpatVersionNumber;

//! Project version string for SwiftyExpat.
FOUNDATION_EXPORT const unsigned char SwiftyExpatVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SwiftyExpat/PublicHeader.h>

// No more bridging header in v0.0.4, need to make all C stuff public
#import <SwiftyExpat/expat.h>
