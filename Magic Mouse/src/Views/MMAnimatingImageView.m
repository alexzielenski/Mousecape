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
@synthesize image         = _image;
@synthesize frameCount    = _frameCount;
@synthesize frameDuration = _frameDuration;
@synthesize delegate      = _delegate;
- (id)init {
	if ((self = [super init])) {
		// We cannot have a frame count of 0.
		_frameCount    = 1;
		_frameDuration = 1;
		
		[self registerTypes];
	}
	return self;
}

// Assorted init methods
- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		_frameCount    = 1;
		_frameDuration = 1;
		
		[self registerTypes];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		_frameCount    = 1;
		_frameDuration = 1;
		
		[self registerTypes];
	}
	return self;
}

// I guess we can safely reset the animation when the view is moved to a new superview
- (void)viewDidMoveToSuperview {
	[self resetAnimation];
}

- (void)dealloc {
	if (frameTimer)
		[frameTimer invalidate];
	frameTimer = nil;
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
	
	size_t imageWidth   = self.image.pixelsWide;
	size_t imageHeight  = self.image.pixelsHigh/self.frameCount;
	
	// Read from bottom to top
	currentFrame = self.frameCount-1;
	imageSize    = NSMakeSize(imageWidth, imageHeight);

	[self timerAction:nil];
	
	if (self.frameCount>1) {
		frameTimer = [NSTimer timerWithTimeInterval:self.frameDuration 
											 target:self 
										   selector:@selector(timerAction:) 
										   userInfo:nil 
											repeats:YES];
		
		// Keep the images animating even during runloop blocking events.
		[[NSRunLoop mainRunLoop] addTimer:frameTimer forMode:NSRunLoopCommonModes];
	}
}

- (void)timerAction:(NSTimer *)timer {		
	if (currentFrame < 0)
		currentFrame = self.frameCount-1;
	
	currentImageFrame = NSMakeRect(0, 
								   imageSize.height * currentFrame--, 
								   imageSize.width, 
								   imageSize.height);

	
	[self setNeedsDisplay:YES];
}

// Tell OSX that our view can accept images to be dragged in
- (void)registerTypes {
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeTIFF, NSPasteboardTypePNG, NSFilenamesPboardType, nil]];
}

#pragma mark - NSDragDestination
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
	// Only thing we have to do here is confirm that the dragged file is an image. We use NSImage's +canInitWithPasteboard: and we also check to see there is only one item being dragged
	if ([self.delegate conformsToProtocol:@protocol(MMAnimatingImageViewDelegate)] &&  // No point in accepting the drop if the delegate doesn't support it/exist
		[NSImage canInitWithPasteboard:sender.draggingPasteboard] &&                   // Only Accept Images
		sender.draggingPasteboard.pasteboardItems.count == 1) {                        // Only accept one item
		return [self.delegate imageView:self draggingEntered:sender];
	}
	return NSDragOperationNone;
}

// Give the delegate some more control
- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
	if ([self.delegate conformsToProtocol:@protocol(MMAnimatingImageViewDelegate)]) {
		return [self.delegate imageView:self shouldPerformDragOperation:sender];
	}
	return NO;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
	if ([self.delegate conformsToProtocol:@protocol(MMAnimatingImageViewDelegate)] &&  // Only do the operation if a delegate exists to actually set the image.
		[self.delegate imageView:self shouldPerformDragOperation:sender]) {            // Only do the operation if a delegate wants us to do the operation.
		
		// Get the image from the pasteboard
		NSImage *im = [[NSImage alloc] initWithPasteboard:sender.draggingPasteboard];
		
		// Make an array of the valid drops (NSBitmapImageRep)
		NSMutableArray *acceptedDrops = [[NSMutableArray alloc] initWithCapacity:im.representations.count];
		for (NSImageRep *rep in im.representations) {
			if (![rep isKindOfClass:[NSBitmapImageRep class]]) // We don't want PDFs
				continue;
			
			[acceptedDrops addObject:rep];
			
		}
		
		if (acceptedDrops.count > 0) {
			// We already confirmed that the delegate conforms to the protocol above. Now we can let the delegate
			// decide what to do with the dropped images.
			[self.delegate imageView:self didAcceptDroppedImages:acceptedDrops];
		}
		
		[acceptedDrops release];
		[im release];
		return YES;
	}
	
	return NO;
}

@end
