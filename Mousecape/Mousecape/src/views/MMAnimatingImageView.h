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
- (void)imageView:(MMAnimatingImageView *)imageView didDragOutImage:(NSImage *)image;

@end

//!****************************************************************************************************************************************//
//!** This is a specialized view class for animating the cursors used in magic mouse. These animated cursors have a height that is their **//
//!** frame count multiplied by the normal image height so every time the timer fires, it moves the y offset displayed by the image.     **//
//!****************************************************************************************************************************************//
@interface MMAnimatingImageView : NSView <NSDraggingDestination, NSDraggingSource, NSPasteboardItemDataProvider>
@property (strong) NSImage                                    *image;
@property (strong) NSImage                                    *placeholderImage;
@property (assign) CGFloat                                    frameDuration;
@property (assign) NSInteger                                  frameCount;
@property (assign) CGFloat                                    scale; // set to 0.0 if you want to inherit window scale
@property (assign) NSPoint                                    hotSpot;
@property (assign) BOOL                                       shouldFlipHorizontally;
@property (weak)   IBOutlet id <MMAnimatingImageViewDelegate> delegate;
@property (assign) BOOL shouldAnimate;
@property (assign) BOOL shouldShowHotSpot;
@property (assign) BOOL shouldAllowDragging;
@end
