//
//  BTRClipView.h
//  Butter
//
//  Created by Justin Spahr-Summers on 2012-09-14.
//  Copyright (c) 2012 GitHub. All rights reserved.
//  Update with smooth scrolling by Jonathan Willing, with logic from TwUI.
//

#import "BTRClipView.h"

// The deceleration constant used for the ease-out curve in the animation.
static const CGFloat BTRClipViewDecelerationRate = 0.78;

@interface BTRClipView ()
// Used to drive the animation through repeated callbacks.
// A display link is used instead of a timer so that we don't get dropped frames and tearing.
// Lazily created when needed, released in dealloc. Stopped automatically when scrolling is not occurring.
@property (nonatomic, assign) CVDisplayLinkRef displayLink;

// Used to determine whether to animate in `scrollToPoint:`.
@property (nonatomic, assign) BOOL shouldAnimateOriginChange;

// Used when animating with the display link as the final origin for the animation.
@property (nonatomic, assign) CGPoint destinationOrigin;

// Return value is whether the display link is currently animating a scroll.
@property (nonatomic, readonly) BOOL animatingScroll;
@end

@implementation BTRClipView

#pragma mark Properties

- (NSColor *)backgroundColor {
	return self.layer.backgroundColor ? [NSColor colorWithCGColor:self.layer.backgroundColor] : nil;
}

- (void)setBackgroundColor:(NSColor *)color {
	self.layer.backgroundColor = color.CGColor;
}

- (BOOL)isOpaque {
	return self.layer.opaque;
}

- (void)setOpaque:(BOOL)opaque {
	self.layer.opaque = opaque;
}

#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self == nil) return nil;
	
	self.wantsLayer = YES;
	
	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
	
	// Matches default NSClipView settings.
	self.backgroundColor = NSColor.clearColor;
	self.opaque = NO;
	
	self.decelerationRate = BTRClipViewDecelerationRate;
	
	return self;
}

- (void)dealloc {
	CVDisplayLinkRelease(_displayLink);
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark View Heirarchy

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	if (self.window != nil) {
		[NSNotificationCenter.defaultCenter removeObserver:self name:NSWindowDidChangeScreenNotification object:self.window];
	}
	
	[super viewWillMoveToWindow:newWindow];
	
	if (newWindow != nil) {
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateCVDisplay:) name:NSWindowDidChangeScreenNotification object:newWindow];
	}
}

#pragma mark Display link

static CVReturn BTRScrollingCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
	@autoreleasepool {
		BTRClipView *clipView = (__bridge id)displayLinkContext;
		dispatch_async(dispatch_get_main_queue(), ^{
			[clipView updateOrigin];
		});
	}
	
	return kCVReturnSuccess;
}

- (CVDisplayLinkRef)displayLink {
	if (_displayLink == NULL) {
		CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
		CVDisplayLinkSetOutputCallback(_displayLink, &BTRScrollingCallback, (__bridge void *)self);
		[self updateCVDisplay:nil];
	}
	
	return _displayLink;
}

- (void)updateCVDisplay:(NSNotification *)note {
	NSScreen *screen = self.window.screen;
	if (screen == nil) {
		NSDictionary *screenDictionary = NSScreen.mainScreen.deviceDescription;
		NSNumber *screenID = screenDictionary[@"NSScreenNumber"];
		CGDirectDisplayID displayID = screenID.unsignedIntValue;
		CVDisplayLinkSetCurrentCGDisplay(_displayLink, displayID);
	} else {
		CVDisplayLinkSetCurrentCGDisplay(_displayLink, kCGDirectMainDisplay);
	}
}

#pragma mark Scrolling

- (void)scrollToPoint:(NSPoint)newOrigin {
	NSEventType type = self.window.currentEvent.type;
	
	if (self.shouldAnimateOriginChange && type != NSScrollWheel) {
		// Occurs when `-scrollRectToVisible:animated:` has been called with an animated flag.
		self.destinationOrigin = newOrigin;
		[self beginScrolling];
	} else if (type == NSKeyDown || type == NSKeyUp || type == NSFlagsChanged) {
		// Occurs if a keyboard press has triggered a origin change. In this case we
		// want to explicitly enable and begin the animation.
		self.destinationOrigin = newOrigin;
		[self beginScrolling];
	} else {
		// For all other cases, we do not animate. We call `endScrolling` in case a previous animation
		// is still in progress, in which case we want to stop the display link from making further
		// callbacks, which would interfere with normal scrolling.
		[self endScrolling];
		[super scrollToPoint:newOrigin];
	}
}

- (void)setDestinationOrigin:(CGPoint)origin {
	// We want to round up to the nearest integral point, since some classes
	// seem to provide non-integral point values.
	_destinationOrigin = (CGPoint){ .x = round(origin.x), .y = round(origin.y) };
}

- (BOOL)scrollRectToVisible:(NSRect)aRect animated:(BOOL)animated {
	self.shouldAnimateOriginChange = animated;
	return [super scrollRectToVisible:aRect];
}

- (void)beginScrolling {
	if (self.animatingScroll) {
		return;
	}
	
	CVDisplayLinkStart(self.displayLink);
}

- (void)endScrolling {
	if (!self.animatingScroll) {
		return;
	}
	
	CVDisplayLinkStop(self.displayLink);
	self.shouldAnimateOriginChange = NO;
}

- (BOOL)animatingScroll {
	return CVDisplayLinkIsRunning(self.displayLink);
}

// Sanitize the deceleration rate to [0, 1] so nothing unexpected happens.
- (void)setDecelerationRate:(CGFloat)decelerationRate {
	if (decelerationRate > 1)
		decelerationRate = 1;
	else if (decelerationRate < 0)
		decelerationRate = 0;
	_decelerationRate = decelerationRate;
}

- (void)updateOrigin {
	if (self.window == nil) {
		[self endScrolling];
		return;
	}
	
	CGPoint o = self.bounds.origin;
	CGPoint lastOrigin = o;
	
	// Calculate the next origin on a basic ease-out curve.
	o.x = o.x * self.decelerationRate + self.destinationOrigin.x * (1 - self.decelerationRate);
	o.y = o.y * self.decelerationRate + self.destinationOrigin.y * (1 - self.decelerationRate);
	
	self.boundsOrigin = o;
	
	if (fabs(o.x - lastOrigin.x) < 0.1 && fabs(o.y - lastOrigin.y) < 0.1) {
		[self endScrolling];
		self.boundsOrigin = self.destinationOrigin;
		[self.enclosingScrollView flashScrollers];
	}
}

@end
