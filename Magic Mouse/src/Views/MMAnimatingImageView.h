//
//  MMAnimatingImageView.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*! Protocol for giving the delegate control over drops. */
@class MMAnimatingImageView; // Define the calss for our protocol
@protocol MMAnimatingImageViewDelegate <NSObject>
@required

- (NSDragOperation)imageView:(MMAnimatingImageView *)imageView draggingEntered:(id <NSDraggingInfo>)drop;
- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPrepareForDragOperation:(id <NSDraggingInfo>)drop;
- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPerformDragOperation:(id <NSDraggingInfo>)drop;
- (void)imageView:(MMAnimatingImageView *)imageView didAcceptDroppedImages:(NSArray *)images; // I'm making this an array because in the future we mighty allow users
																							  // to drag multiple frames for a cursor instead of manually stacking them.

@end

//!****************************************************************************************************************************************//
//!** This is a specialized view class for animating the cursors used in magic mouse. These animated cursors have a height that is their **//
//!** frame count multiplied by the normal image height so every time the timer fires, it moves the y offset displayed by the image.     **//
//!****************************************************************************************************************************************//
@interface MMAnimatingImageView : NSView {
	// Image to animate
	NSBitmapImageRep   *_image;
	// Time in seconds of each frame
	CGFloat            _frameDuration;
	// Amount of frames
	NSInteger          _frameCount;
	
@private
	// Timer fires for every frame
	NSTimer            *frameTimer;
	// Cursor size, not image size. Size the cursor gets displayed by
	NSSize             imageSize;
	// Current rectangle to take out of the cursor image for display
	NSRect             currentImageFrame;
	// Current frame we are on during animation
	NSInteger          currentFrame;
}
@property (nonatomic, retain) NSBitmapImageRep                           *image;
@property (nonatomic, assign) CGFloat                                    frameDuration;
@property (nonatomic, assign) NSInteger                                  frameCount;
@property (nonatomic, assign) IBOutlet id <MMAnimatingImageViewDelegate> delegate;

// Resets the timer and current frame for the animation. Should be used when new parameters are specified.
// The reason this isn't called automatically when each new parameter is set because that would waste resources.
- (void)resetAnimation;

// Don't call this. Registers the valid drag types. Probably should be a private category–but we're all developers here...
- (void)registerTypes;
@end
