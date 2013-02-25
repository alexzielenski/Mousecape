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
@property (assign) NSRect lastFrame;
@property (assign) CGFloat lastScaleFactor;
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
    self.shouldChooseHotSpot = YES;
    self.shouldDrawBezel = YES;
    self.shouldDragToRemove = YES;
    
    [self addObserver:self forKeyPath:@"scale" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"sampleSize" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"hotSpot" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"shouldDrawBezel" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"sampleSize"];
    [self removeObserver:self forKeyPath:@"hotSpot"];
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
    
    //!TODO If the cursor stops scaling up, halt the crosshair moving. Maybe the issue is with the anchor point?
    self.lastScaleFactor = self.scale;
    
    // Proportionally scale down
    if (sizeToDraw.width > self.bounds.size.width || sizeToDraw.height > self.bounds.size.height) {

        CGFloat scaleFactor  = 1.0;
        CGFloat widthFactor  = self.bounds.size.width / sizeToDraw.width;
        CGFloat heightFactor = self.bounds.size.height / sizeToDraw.height;
        
        if ( widthFactor < heightFactor )
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        self.lastScaleFactor = scaleFactor;
        
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
    
    self.lastFrame = NSIntegralRect(rect);
    
    self.lastRepresentation = (NSBitmapImageRep *)[self.image bestRepresentationForContentsScale:self.scale];
    [self.lastRepresentation drawInRect:self.lastFrame
                               fromRect:NSMakeRect(0, 0, sampleSize.width, sampleSize.height)
                              operation:NSCompositeSourceOver
                               fraction:1.0
                         respectFlipped:NO
                                  hints:nil];
    
    if (self.shouldChooseHotSpot) {
#define kHotSpotSize 1.0
        
        NSColor *hotSpotColor = [NSColor redColor];
        [hotSpotColor set];
        
        CGFloat scaledSize = kHotSpotSize * self.scale;
        
        NSPoint scaledPoint   = NSMakePoint(self.hotSpot.x * self.lastScaleFactor + self.lastFrame.origin.x, (self.lastFrame.origin.y + self.lastFrame.size.height) - self.hotSpot.y * self.lastScaleFactor);
        NSRect verticalLine   = NSIntegralRect(NSMakeRect(scaledPoint.x, scaledPoint.y - scaledSize * 2, scaledSize, scaledSize * 2));
        NSRect horizontalLine = NSIntegralRect(NSMakeRect(scaledPoint.x - scaledSize * 2, scaledPoint.y, scaledSize * 2, scaledSize));
        
        
        NSRectFill(verticalLine);
        NSRectFill(horizontalLine);
        
        verticalLine   = NSIntegralRect(NSMakeRect(scaledPoint.x, scaledPoint.y + scaledSize, scaledSize, scaledSize * 2));
        horizontalLine = NSIntegralRect(NSMakeRect(scaledPoint.x + scaledSize, scaledPoint.y, scaledSize * 2, scaledSize));
        
        NSRectFill(verticalLine);
        NSRectFill(horizontalLine);
    }
    
}

- (void)keyDown:(NSEvent *)theEvent {
    // Backspace without any modifiers
    if (theEvent.keyCode == 51 && theEvent.modifierFlags == 0) {
        //!TODO: Remove image current
        return;
    }
    
    [super keyDown:theEvent];
}

- (void)mouseDown:(NSEvent *)event {
    if (self.shouldChooseHotSpot) {
        NSPoint clickPoint = [self convertPoint:event.locationInWindow fromView: nil];

        clickPoint.x -= self.lastFrame.origin.x;
        clickPoint.y = (self.lastFrame.origin.y + self.lastFrame.size.height) - clickPoint.y;
        
        // hotSpot.x = (clickPoint.x - self.lastFrame.origin.x) / scale
        // hotSpot.y = ((self.lastFrame.origin.y + self.lastFrame.size.height) - clickPoint.y) / scale
        // clickPoint.y = hotSpot.y * scale - 
        
        // scale down magnitude
        self.hotSpot = NSMakePoint(clickPoint.x / self.lastScaleFactor, clickPoint.y / self.lastScaleFactor);
        [self setNeedsDisplay:YES];
    }
    
    [super mouseDown:event];
}
//https://bitbucket.org/alunbestor/boxer/src/347a0bfa5b04/Boxer/BXDriveList.m use that for poof code
- (void)mouseDragged:(NSEvent *)event {
    if (self.shouldDragToRemove) {
        
    }
    
    [super mouseDragged:event];
}

@end
