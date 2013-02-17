//
//  MMAnimatingImageView.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMAnimatingImageView.h"
#import "MCSpriteLayer.h"

@interface NSImage (BestRep)
- (NSImageRep *)bestRepresentationForContentsScale:(CGFloat)scale;
@end

@implementation NSImage (BestRep)

- (NSImageRep *)bestRepresentationForContentsScale:(CGFloat)scale {
    NSSize scaledSize = NSMakeSize(self.size.width * scale, self.size.height * scale);
    
    NSImageRep *closestMatch = nil;
    CGFloat closestDeltaW = 0;
    CGFloat closestDeltaH = 0;
    
    for (NSImageRep *rep in self.representations) {
        if ([rep isKindOfClass:[NSPDFImageRep class]])
            return rep;
        
        CGFloat deltaW = rep.pixelsWide - scaledSize.width;
        CGFloat deltaH = rep.pixelsHigh - scaledSize.height;
        
        
        // exact match
        if (deltaW == 0 && deltaH == 0) {
            return rep;
        }
        
        // start up
        if (!closestMatch) {
            closestMatch = rep;
            closestDeltaW = deltaW;
            closestDeltaH = deltaH;
            
            continue;
        }

        // Always prefer the larger image
        if ((closestDeltaW < 0 && deltaW >= 0) || (closestDeltaH < 0 && deltaH >= 0)) {
            closestMatch = rep;
            closestDeltaW = closestDeltaW;
            closestDeltaH = closestDeltaH;
            continue;
        }
        
        if (abs(deltaW) < abs(closestDeltaW) || abs(deltaH) < closestDeltaH) {
            closestMatch = rep;
            closestDeltaW = closestDeltaW;
            closestDeltaH = closestDeltaH;
            continue;
        }
        
        
    }

    return closestMatch;
}

@end

static NSRect centerSizeInRect(NSSize size, NSRect rect) {
    return NSIntegralRect(NSMakeRect(NSMidX(rect) - size.width / 2, NSMidY(rect) - size.height / 2, size.width, size.height));
}

@interface MMAnimatingImageView ()
@property (weak) MCSpriteLayer *spriteLayer;
- (void)_initialize;
@end

@implementation MMAnimatingImageView
- (id)init {
	if ((self = [super init])) {
		[self _initialize];
	}
	return self;
}

// Assorted init methods
- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		[self _initialize];

	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		[self _initialize];
	}
	return self;
}

- (void)_initialize {
    [self addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"frameDuration" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"frameCount" options:NSKeyValueObservingOptionNew context:nil];
    
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

    self.frameCount    = 1;
    self.frameDuration = 1;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"image"];
    [self removeObserver:self forKeyPath:@"frameDuration"];
    [self removeObserver:self forKeyPath:@"frameCount"];
}

- (void)viewDidChangeBackingProperties {
    [super viewDidChangeBackingProperties];
    self.layer.contentsScale       = self.window.backingScaleFactor;
    self.spriteLayer.contentsScale = self.window.backingScaleFactor;
    
//    NSUInteger scaleFactor = (NSUInteger)self.window.backingScaleFactor;
//    while (self.image.representations.count - 1 < scaleFactor) {
//        scaleFactor--;
//    }
//    
    // When you set this, the next time the layer displayes it will choose the best representation for the job
    self.spriteLayer.contents = (__bridge id)[(NSBitmapImageRep *)[self.image bestRepresentationForContentsScale:self.spriteLayer.contentsScale] CGImage];
//    self.spriteLayer.contents = (__bridge id)[[self.image.representations objectAtIndex:MIN(self.image.representations.count - 1, scaleFactor)] CGImage];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"image"]) {
        self.spriteLayer.image = self.image;
//        self.spriteLayer.contents = (__bridge id)[(NSBitmapImageRep *)[self.image bestRepresentationForContentsScale:self.spriteLayer.contentsScale] CGImage];
        self.spriteLayer.sampleSize = NSMakeSize(self.image.size.width, self.image.size.height / self.frameCount);
        self.spriteLayer.position = centerSizeInRect(self.spriteLayer.bounds.size, self.layer.bounds).origin;
        self.frameDuration = self.frameDuration;
        
    } else if ([keyPath isEqualToString:@"frameCount"]) {
        self.spriteLayer.sampleSize = NSMakeSize(self.image.size.width, self.image.size.height / self.frameCount);
        self.spriteLayer.position = centerSizeInRect(self.spriteLayer.bounds.size, self.layer.bounds).origin;
        self.frameDuration = self.frameDuration;
        
    } else if ([keyPath isEqualToString:@"frameDuration"]) {
        if (self.frameCount == 1) {
            self.spriteLayer.sampleIndex = 1;
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
