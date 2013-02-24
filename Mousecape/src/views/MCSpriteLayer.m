//
//  MCSpriteLayer.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/10/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCSpriteLayer.h"

@interface MCSpriteLayer ()
- (NSSize)_size;
@end

@implementation MCSpriteLayer
@dynamic image, sampleSize;

+ (MCSpriteLayer *)layerWithImage:(NSImage *)image sampleSize:(CGSize)size {
    return [[MCSpriteLayer alloc] initWithImage:image sampleSize:size];
}
- (id)initWithImage:(NSImage *)image sampleSize:(CGSize)size {
    if ((self = [self init])) {
        _sampleIndex = 1;
        self.contents    = image;
        self.image       = image;
        self.sampleSize  = size;
        self.anchorPoint = CGPointZero;
    }
    
    return self;
}

#pragma mark - Accessors

- (NSImage *)image {
    return self.contents;
}

- (void)setImage:(NSImage *)image {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    [self willChangeValueForKey:@"image"];
    self.contents = image;
    [self didChangeValueForKey:@"image"];
    [CATransaction commit];
}

- (NSSize)sampleSize {
    return NSMakeSize(self.contentsRect.size.width * self._size.width, self.contentsRect.size.height * self._size.height);
}

- (void)setSampleSize:(NSSize)size {
    [self willChangeValueForKey:@"sampleSize"];
    CGSize sampleSizeNormalized = CGSizeMake(size.width / self._size.width, size.height / self._size.height);
    
    NSSize maxSize = self.maximumSize;
    if (NSEqualSizes(maxSize, NSZeroSize))
        maxSize = size;
    
    self.bounds = CGRectIntegral(CGRectMake(0, 0, MIN(size.width, maxSize.width), MIN(size.height, maxSize.height)));
    self.contentsRect = CGRectMake(0, 0, sampleSizeNormalized.width, sampleSizeNormalized.height);
    [self didChangeValueForKey:@"sampleSize"];
}

- (NSSize)_size {
    if ([self.image isKindOfClass:[NSImage class]]) {
        return self.image.size;
    }
    
    return NSMakeSize(CGImageGetWidth((__bridge CGImageRef)(self.contents)), CGImageGetHeight((__bridge CGImageRef)(self.contents)));
}

#pragma mark -
#pragma mark Frame by frame animation

+ (BOOL)needsDisplayForKey:(NSString *)key {
    return [key isEqualToString:@"sampleIndex"];
}

// contentsRect or bounds changes are not animated
+ (id < CAAction >)defaultActionForKey:(NSString *)aKey {
    if ([aKey isEqualToString:@"contentsRect"] || [aKey isEqualToString:@"bounds"] || [aKey isEqualToString:@"contents"])
        return (id < CAAction >)[NSNull null];
    
    return [super defaultActionForKey:aKey];
}


- (NSUInteger)currentSampleIndex {
    return ((MCSpriteLayer *)[self presentationLayer]).sampleIndex;
}


// Implement displayLayer: on the delegate to override how sample rectangles are calculated; remember to use currentSampleIndex, ignore sampleIndex == 0, and set the layer's bounds
- (void)display {
    if ([self.delegate respondsToSelector:@selector(displayLayer:)]) {
        [self.delegate displayLayer:self];
        
        return;
    }
    
    NSUInteger currentSampleIndex = [self currentSampleIndex];
    if (!currentSampleIndex)
        return;

    CGSize sampleSize = self.contentsRect.size;
    self.contentsRect = CGRectMake(
                                   ((currentSampleIndex - 1) % (int)(1/sampleSize.width)) * sampleSize.width,
                                   ((currentSampleIndex - 1) / (int)(1/sampleSize.width)) * sampleSize.height,
                                   sampleSize.width, sampleSize.height
                                   );
}


@end
