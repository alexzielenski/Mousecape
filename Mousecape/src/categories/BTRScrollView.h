//
//  BTRScrollView.h
//  Originally from Rebel
//
//  Created by Jonathan Willing on 12/4/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// A NSScrollView subclass which uses an instance of BTRClipView
// as the clip view instead of NSClipView.
//
// Layer-backed by default.
@interface BTRScrollView : NSScrollView

// Overridden by subviews to change the class of the clip view
+ (Class)clipViewClass;

@end
