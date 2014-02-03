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
    
//    [self registerTypes];
    
    self.layer = [CALayer layer];
    self.wantsLayer = YES;
    self.layer.contentsGravity = kCAGravityCenter;
    self.layer.bounds = self.bounds;
    self.layer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable | kCALayerMinXMargin | kCALayerMinYMargin;
    self.layer.delegate = self;
    
    MCSpriteLayer *spriteLayer = [MCSpriteLayer layerWithImage:nil sampleSize:CGSizeZero];
    spriteLayer.autoresizingMask = kCALayerNotSizable;
    spriteLayer.position = CGPointZero;//CGPointMake(CGRectGetMidX(self.layer.bounds), CGRectGetMidY(self.layer.bounds));
    spriteLayer.contentsGravity = kCAGravityResize;
    
    NSMutableDictionary *newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                       [NSNull null], @"contents",
                                       nil];
    spriteLayer.actions = newActions;
    
    [self.layer addSublayer:spriteLayer];
    self.spriteLayer = spriteLayer;
    self.spriteLayer.maximumSize = self.frame.size;

    self.frameCount    = 1;
    self.frameDuration = 1;
    
    @weakify(self);
    
    [self.spriteLayer rac_bind:@"image" toObject:self withKeyPath:@"image"];
    
    [self rac_addDeallocDisposable:[[[RACSignal combineLatest:@[ RACAble(self.frameCount), RACAble(self.frameDuration) ]] distinctUntilChanged]
     subscribeNext:^(id x) {
         @strongify(self);
         [self _invalidateFrame];
         [self _invalidateAnimation];
     }]];
    
    [self rac_addDeallocDisposable:[[RACAble(self.shouldAnimate) distinctUntilChanged]
     subscribeNext:^(NSNumber *x) {
         @strongify(self);
         if (!x.boolValue) {
             self.spriteLayer.sampleIndex = self.frameCount + 1;
             [self.spriteLayer removeAllAnimations];
             [self.spriteLayer setNeedsDisplay];
         } else {
             [self _invalidateAnimation];
         }
     }]];
    
}

- (void)viewDidChangeBackingProperties {
    [super viewDidChangeBackingProperties];
    
    self.layer.contentsScale       = self.window.backingScaleFactor;
    self.spriteLayer.contentsScale = self.window.backingScaleFactor;
    
    // When you set this, the next time the layer displayes it will choose the best representation for the job
    self.spriteLayer.image = (__bridge id)[(NSBitmapImageRep *)[self.image bestRepresentationForContentsScale:self.spriteLayer.contentsScale] CGImage];
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
    
    [self.spriteLayer removeAllAnimations];
    
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

- (id <CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {
    return (id <CAAction>)[NSNull null];
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
