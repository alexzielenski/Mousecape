//
//  MMAnimatingImageView.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMAnimatingImageView.h"
#import "MCSpriteLayer.h"
#import "NSImage+BestRep.h"

static NSRect centerSizeInRect(NSSize size, NSRect rect) {
    return NSIntegralRect(NSMakeRect(NSMidX(rect) - size.width / 2, NSMidY(rect) - size.height / 2, size.width, size.height));
}

@interface MMAnimatingImageView ()
@property (weak) MCSpriteLayer *spriteLayer;
- (void)_initialize;
- (void)_invalidateFrame;
- (void)_invalidateAnimation;
@end

@implementation MMAnimatingImageView
- (id)init {
	if ((self = [super init])) {
		[self _initialize];
	}
	return self;
}

- (void)_initialize {
    self.shouldAnimate = YES;
    
    [self registerTypes];
    
    self.layer = [CALayer layer];
    self.wantsLayer = YES;
    self.layer.contentsGravity = kCAGravityCenter;
    self.layer.bounds = self.bounds;
    self.layer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable | kCALayerMinXMargin | kCALayerMinYMargin;
    
    MCSpriteLayer *spriteLayer = [MCSpriteLayer layerWithImage:nil sampleSize:CGSizeZero];
    spriteLayer.autoresizingMask = kCALayerNotSizable;
    spriteLayer.position = CGPointZero;//CGPointMake(CGRectGetMidX(self.layer.bounds), CGRectGetMidY(self.layer.bounds));
    spriteLayer.contentsGravity = kCAGravityResize;
    
    [self.layer addSublayer:spriteLayer];
    self.spriteLayer = spriteLayer;
    self.spriteLayer.maximumSize = self.frame.size;
    
    self.frameCount    = 1;
    self.frameDuration = 1;
    
    
    // Some of this stuff seems to be minorly expensive. Put it off the main thread
    __weak MMAnimatingImageView *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [[[RACAble(self.image) distinctUntilChanged] deliverOn:RACScheduler.mainThreadScheduler]
         subscribeNext:^(id x) {
             weakSelf.spriteLayer.image = x;
             [weakSelf _invalidateFrame];
             [weakSelf _invalidateAnimation];
         }];
        
        [[[[RACSignal combineLatest:@[ RACAble(self.frameCount), RACAble(self.frameDuration) ]] deliverOn:RACScheduler.mainThreadScheduler] distinctUntilChanged]
         subscribeNext:^(id x) {
             [weakSelf _invalidateFrame];
             [weakSelf _invalidateAnimation];
         }];
        
        [[[RACAble(self.shouldAnimate) deliverOn:RACScheduler.mainThreadScheduler] distinctUntilChanged]
         subscribeNext:^(NSNumber *x) {
             if (!x.boolValue) {
                 weakSelf.spriteLayer.sampleIndex = self.frameCount + 1;
                 [weakSelf.spriteLayer removeAllAnimations];
                 [weakSelf.spriteLayer setNeedsDisplay];
             } else {
                 [weakSelf _invalidateAnimation];
             }
         }];
    });
    
}

- (void)viewDidChangeBackingProperties {
    [super viewDidChangeBackingProperties];
    
    //!TODO: see if this can be done with RAC
    self.layer.contentsScale       = self.window.backingScaleFactor;
    self.spriteLayer.contentsScale = self.window.backingScaleFactor;
    
    // When you set this, the next time the layer displayes it will choose the best representation for the job
    self.spriteLayer.contents = (__bridge id)[(NSBitmapImageRep *)[self.image bestRepresentationForContentsScale:self.spriteLayer.contentsScale] CGImage];
}

// Tell OSX that our view can accept images to be dragged in
- (void)registerTypes {
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeTIFF, NSPasteboardTypePNG, NSFilenamesPboardType, nil]];
}

- (void)viewDidMoveToWindow {
    [self _invalidateFrame];
}

#pragma mark - Invalidators

- (void)_invalidateFrame {
    self.spriteLayer.maximumSize = self.frame.size;
    
    self.spriteLayer.sampleSize = NSMakeSize(self.image.size.width, self.image.size.height / self.frameCount);
    self.spriteLayer.position = centerSizeInRect(self.spriteLayer.bounds.size, self.layer.bounds).origin;
}

- (void)_invalidateAnimation {
    if (self.frameCount == 1 || !self.shouldAnimate) {
        self.spriteLayer.sampleIndex = self.frameCount + 1;
        [self.spriteLayer removeAllAnimations];
        return;
    }
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"sampleIndex"];
    
    anim.fromValue    = @(self.frameCount + 1);
    anim.toValue      = @(1);
    anim.byValue      = @(-1);
    anim.duration     = self.frameDuration * self.frameCount;
    anim.repeatCount  = HUGE_VALF; // just keep repeating it
    anim.autoreverses = NO; // do 1, 2, 3, 4, 5, 1, 2, 3, 4, 5
    anim.removedOnCompletion = NO;
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    
    [self.spriteLayer addAnimation:anim forKey:@"sampleIndex"]; // start
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
		NSMutableArray *acceptedDrops = [NSMutableArray arrayWithCapacity:im.representations.count];
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
		
		return YES;
	}
	
	return NO;
}

@end
