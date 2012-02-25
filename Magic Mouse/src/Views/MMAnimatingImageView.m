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

- (void)dealloc {
	if (frameTimer)
		[frameTimer invalidate];
	frameTimer = nil;
	[_image release];
	[super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
	[self.image drawInRect:NSMakeRect(0, 0, imageSize.width, imageSize.height)
				  fromRect:currentImageFrame
				 operation:NSCompositeCopy 
				  fraction:1.0
			respectFlipped:YES
					 hints:nil];
}

- (void)resetAnimation {
	if (frameTimer)
		[frameTimer invalidate];
	
	if (self.frameCount>1) {
		frameTimer = [NSTimer timerWithTimeInterval:self.frameDuration 
											 target:self 
										   selector:@selector(timerAction:) 
										   userInfo:nil 
											repeats:YES];
	}
	
	imageWidth  = self.image.size.width/self.frameCount;
	imageHeight = self.image.size.height/self.frameCount;
	
	currentFrame = 0;
	currentImageFrame = NSMakeRect(0,
								   0, 
								   imageWidth,
								   imageHeight);
	
	imageSize = NSMakeSize(imageWidth, imageHeight);

	[self setNeedsDisplay:YES];
	
	if (frameTimer)
		[frameTimer fire];
}

- (void)timerAction:(NSTimer*)timer {
	currentImageFrame = NSMakeRect(0, 
								   imageHeight * ++currentFrame, 
								   imageSize.width, 
								   imageSize.height);
	
	[self setNeedsDisplay:YES];
}

#pragma mark - Accessors
- (void)setImage:(NSImage *)image {
	[self willChangeValueForKey:@"image"];
	if (_image) {
		[_image release];
	}
	_image = [image retain];
	[self didChangeValueForKey:@"image"];
}

- (NSImage*)image {
	return _image;
}

- (void)setFrameCount:(NSInteger)frameCount {
	[self willChangeValueForKey:@"frameCount"];
	_frameCount = frameCount;
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
