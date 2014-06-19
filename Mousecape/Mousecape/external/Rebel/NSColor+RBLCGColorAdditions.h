//
//  NSColor+RBLCGColorAdditions.h
//  Rebel
//
//  Created by Justin Spahr-Summers on 01.12.11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//
//  Portions copyright (c) 2011 Bitswift. All rights reserved.
//  See the LICENSE file for more information.
//

#import <AppKit/AppKit.h>

// Extensions to NSColor for interoperability with CGColor.
@interface NSColor (RBLCGColorAdditions)

// The CGColor corresponding to the receiver.
@property (nonatomic, readonly) CGColorRef rbl_CGColor;

// Returns an NSColor corresponding to the given CGColor.
//
// This currently does not handle pattern colors.
+ (NSColor *)rbl_colorWithCGColor:(CGColorRef)color;

@end
