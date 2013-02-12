//
//  MMAnimatingImageView.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMAnimatingImageView.h"
#import "MCSpriteLayer.h"

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
    self.layer.contentsGravity = kCAGravityResize;
    self.layer.bounds = self.bounds;
    self.layer.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable | kCALayerMinXMargin | kCALayerMinYMargin;
    
    MCSpriteLayer *spriteLayer = [MCSpriteLayer layerWithImage:nil sampleSize:CGSizeZero];
    spriteLayer.position = CGPointMake(0.0, 0.0);
    spriteLayer.bounds = self.layer.bounds;
    spriteLayer.autoresizingMask = kCALayerNotSizable;
    spriteLayer.position = CGPointMake(CGRectGetMidX(self.layer.bounds), CGRectGetMidY(self.layer.bounds));
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
    
    NSUInteger scaleFactor = (NSUInteger)self.window.backingScaleFactor;
    while (self.image.representations.count < scaleFactor) {
        scaleFactor--;
    }
    self.spriteLayer.contents = (id)[[self.image.representations objectAtIndex:scaleFactor- 1] CGImage];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"image"]) {
        self.spriteLayer.image = self.image;
        self.spriteLayer.sampleSize = NSMakeSize(self.image.size.width, self.image.size.height / self.frameCount);
        self.spriteLayer.position = CGPointMake(CGRectGetMidX(self.layer.bounds), CGRectGetMidY(self.layer.bounds));
        self.frameDuration = self.frameDuration;

    } else if ([keyPath isEqualToString:@"frameCount"]) {
        self.spriteLayer.sampleSize = NSMakeSize(self.image.size.width, self.image.size.height / self.frameCount);
        self.spriteLayer.position = CGPointMake(CGRectGetMidX(self.layer.bounds), CGRectGetMidY(self.layer.bounds));
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
