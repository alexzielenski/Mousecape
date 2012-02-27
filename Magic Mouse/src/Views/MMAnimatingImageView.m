//
//  MMAnimatingImageView.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMAnimatingImageView.h"

@interface MMAnimatingImageView (Private)
- (void)timerAction:(NSTimer*)timer;
@end

@implementation MMAnimatingImageView
@dynamic image;
@dynamic frameCount;
@dynamic frameDuration;

- (id)init {
	if ((self = [super init])) {
		_frameCount = 1;
		_frameDuration = 1;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		_frameCount = 1;
		_frameDuration = 1;
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_frameCount = 1;
		_frameDuration = 1;
	}
	return self;
}

- (void)viewDidMoveToSuperview {
	[self resetAnimation];
}

- (void)dealloc {
	if (frameTimer)
		[frameTimer invalidate];
	frameTimer = nil;
	[_image release];
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
	[super drawRect:dirtyRect];
	if (self.image && self.frameCount > 0) {
		[self.image drawInRect:NSMakeRect(round(NSMidX(self.bounds)-imageSize.width/2), round(NSMidY(self.bounds)-imageSize.height/2), imageSize.width, imageSize.height)
					  fromRect:currentImageFrame
					 operation:NSCompositeSourceOver
					  fraction:1.0
				respectFlipped:YES
						 hints:nil];
	}
}

- (void)resetAnimation {
	if (frameTimer)
		[frameTimer invalidate];
	
	imageWidth   = self.image.pixelsWide;
	imageHeight  = self.image.pixelsHigh/self.frameCount;
	
	// Read from bottom to top
	currentFrame = self.frameCount-1;
	imageSize    = NSMakeSize(imageWidth, imageHeight);

	[self timerAction:nil];
	
	if (self.frameCount>1) {
		frameTimer = [NSTimer scheduledTimerWithTimeInterval:self.frameDuration 
													  target:self 
													selector:@selector(timerAction:) 
													userInfo:nil 
													 repeats:YES];
	}
}

- (void)timerAction:(NSTimer *)timer {		
	if (currentFrame < 0)
		currentFrame = self.frameCount-1;
	
	currentImageFrame = NSMakeRect(0, 
								   imageHeight * currentFrame--, 
								   imageSize.width, 
								   imageSize.height);

	
	[self setNeedsDisplay:YES];
}

#pragma mark - Accessors
- (void)setImage:(NSBitmapImageRep *)image {
	[self willChangeValueForKey:@"image"];
	if (_image) {
		[_image release];
	}
	_image        = [image retain];
	[self didChangeValueForKey:@"image"];
}

- (NSBitmapImageRep *)image {
	return _image;
}

- (void)setFrameCount:(NSInteger)frameCount {
	[self willChangeValueForKey:@"frameCount"];
	_frameCount   = frameCount;
	[self didChangeValueForKey:@"frameCount"];
}

- (NSInteger)frameCount {
	return _frameCount;
}

- (void)setFrameDuration:(CGFloat)frameDuration {
	[self willChangeValueForKey:@"frameDuration"];
	_frameDuration = frameDuration;
	[self didChangeValueForKey:@"frameDuration"];
}

- (CGFloat)frameDuration {
	return _frameDuration;
}

@end
