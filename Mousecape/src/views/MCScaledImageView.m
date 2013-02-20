//
//  MCScaledImageView.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCScaledImageView.h"
#import "NSImage+BestRep.h"

#define gColorNormal [NSColor colorWithCalibratedWhite:0.961 alpha:1.000]
#define gColorDragging [NSColor colorWithCalibratedWhite:0.359 alpha:0.2500]

#define gOuterStrokeDragging [NSColor colorWithCalibratedWhite:0.631 alpha:1.000]
#define gInnerStrokeDragging [NSColor colorWithCalibratedWhite:0.898 alpha:1.000]
#define gOuterStroke [NSColor colorWithCalibratedWhite:0.667 alpha:1.000]
#define gInnerStroke [NSColor colorWithCalibratedWhite:1.0 alpha:1.000]

@interface MCScaledImageView ()
@property (readwrite, weak) NSBitmapImageRep *lastRepresentation;
- (void)_commonInit;
@end

@implementation MCScaledImageView
- (id)init {
    if ((self = [super init])) {
        [self _commonInit];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)dec {
    if ((self = [super initWithCoder:dec])) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    self.scale = 1.0;
    self.shouldDrawBezel = YES;
    [self addObserver:self forKeyPath:@"scale" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"shouldDrawBezel" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"scale"];
    [self removeObserver:self forKeyPath:@"image"];
    [self removeObserver:self forKeyPath:@"shouldDrawBezel"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    if (self.shouldDrawBezel) {
        [gColorNormal set];
        NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
        
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
        
        
        
        [gInnerStroke set];
        [path setLineWidth:4.0f];
        [path stroke];
        
        [gOuterStroke set];
        [path setLineWidth:2.0f];
        [path stroke];
        
        [path setClip];
    }
    
    if (!self.image) return;
    
    NSSize sampleSize = self.sampleSize;
    if (NSEqualSizes(self.sampleSize, NSZeroSize))
        sampleSize = self.image.size;
    
    NSSize sizeToDraw = NSMakeSize(sampleSize.width * self.scale, sampleSize.height * self.scale);
    NSPoint anchorPoint = NSZeroPoint;
    
    // Proportionally scale down
    if (sizeToDraw.width > self.bounds.size.width || sizeToDraw.height > self.bounds.size.height) {

        CGFloat scaleFactor  = 1.0;
        CGFloat widthFactor  = self.bounds.size.width / sizeToDraw.width;
        CGFloat heightFactor = self.bounds.size.height / sizeToDraw.height;
        
        if ( widthFactor < heightFactor )
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        CGFloat scaledWidth  = sizeToDraw.width * scaleFactor;
        CGFloat scaledHeight = sizeToDraw.height * scaleFactor;
        
        if ( widthFactor < heightFactor )
            anchorPoint.y = (self.bounds.size.height - scaledHeight) * 0.5;
        
        else if ( widthFactor > heightFactor )
            anchorPoint.x = (self.bounds.size.width - scaledWidth) * 0.5;
        
        sizeToDraw.width = scaledWidth;
        sizeToDraw.height = scaledHeight;
    }
    
    NSRect rect;
    rect.origin = NSMakePoint(NSMidX(self.bounds) + anchorPoint.x - sizeToDraw.width / 2, NSMidY(self.bounds) + anchorPoint.y - sizeToDraw.height / 2);
    rect.size   = sizeToDraw;
    
    self.lastRepresentation = (NSBitmapImageRep *)[self.image bestRepresentationForContentsScale:self.scale];
    [self.lastRepresentation drawInRect:NSIntegralRect(rect)
                               fromRect:NSMakeRect(0, 0, sampleSize.width, sampleSize.height)
                              operation:NSCompositeSourceOver
                               fraction:1.0
                         respectFlipped:NO
                                  hints:nil];
    
}

@end
