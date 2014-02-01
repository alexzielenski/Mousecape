//
//  BTRClipView.h
//  Butter
//
//  Created by Justin Spahr-Summers on 2012-09-14.
//  Copyright (c) 2012 GitHub. All rights reserved.
//  Update with smooth scrolling by Jonathan Willing, with logic from TwUI.
//

#import <QuartzCore/QuartzCore.h>

// A NSClipView with better animations.
//
// This view should be set as the scroll view's contentView as soon as possible
// after the scroll view is initialized. For some reason, scroll bars will
// disappear on 10.7 (but not 10.8) unless hasHorizontalScroller and
// hasVerticalScroller are set _after_ the contentView.
//
// BTRClipView performs an ease-out animation with any changes to the origin
// of the clip view when it originates from a keyboard event. It will also animate with the same
// deceleration if -scrollRectToVisible:animated: is called with `animation` set to YES.
// Any other events causing a bounds change will not be animated.
//
// An example of when this would fire by default is a key press that triggers an offscreen
// cell to come into view in a NSTableView.
@interface BTRClipView : NSClipView

// Whether the content in this view is opaque.
//
// Defaults to NO.
@property (nonatomic, getter = isOpaque) BOOL opaque;

// Calls -scrollRectToVisible:, optionally animated.
- (BOOL)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated;

// Any time the origin changes with an animation as discussed above, the deceleration
// rate will be used to create an ease-out animation.
//
// Values should range from [0, 1]. Smaller deceleration rates will provide
// generally fast animations, whereas larger rates will create lengthy animations.
//
// Defaults to 0.78.
@property (nonatomic, assign) CGFloat decelerationRate;

@end
