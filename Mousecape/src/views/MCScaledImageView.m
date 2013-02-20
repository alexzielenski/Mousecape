//
//  MCScaledImageView.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCScaledImageView.h"

@interface MCScaledImageView ()
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
        
    }
    
    if (!self.image) return;
    
    NSSize sizeToDraw = NSMakeSize(self.image.size.width * self.scale, self.image.size.height * self.scale);
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
    rect.origin = NSMakePoint(NSMidX(self.bounds) + anchorPoint.x, NSMidY(self.bounds) + anchorPoint.y);
    rect.size   = sizeToDraw;
    [self.image drawInRect:rect
                  fromRect:NSZeroRect
                 operation:NSCompositeSourceOver
                  fraction:1.0];
    
}

@end
