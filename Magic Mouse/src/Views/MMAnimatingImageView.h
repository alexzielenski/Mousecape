//
//  MMAnimatingImageView.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@interface MMAnimatingImageView : NSView {
	NSImage   *_image;
	CGFloat   _frameDuration;
	NSInteger _frameCount;
	
@private
	NSTimer   *frameTimer;
	NSSize    imageSize;
	NSRect    currentImageFrame;
	NSInteger currentFrame;
	CGFloat   imageHeight;
	CGFloat   imageWidth;
}
@property (nonatomic, retain) NSImage   *image;
@property (nonatomic, assign) CGFloat   frameDuration;
@property (nonatomic, assign) NSInteger frameCount;
- (void)resetAnimation;
@end
