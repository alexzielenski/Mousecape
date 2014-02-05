//
//  MCSpriteLayer.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/10/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCSpriteLayer.h"

@interface MCSpriteLayer ()
- (NSUInteger)currentSampleIndex;
@end

@implementation MCSpriteLayer

- (id)init {
    if ((self = [super init])) {
        self.sampleIndex = 1;
        self.frameCount  = 1;
        self.anchorPoint = CGPointZero;
    }
    
    return self;
}

#pragma mark -
#pragma mark Frame by frame animation

+ (BOOL)needsDisplayForKey:(NSString *)key {
    return [key isEqualToString:@"sampleIndex"] || [key isEqualToString:@"frameCount"];
}

+ (id < CAAction >)defaultActionForKey:(NSString *)aKey; {
    return (id < CAAction >)[NSNull null];
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
    if (!currentSampleIndex) {
        return;
    }
    
    CGSize sampleSize = NSMakeSize(1.0, 1.0 / (self.frameCount ? self.frameCount : 1.0));
    self.contentsRect = CGRectMake(0, (currentSampleIndex - 1) * sampleSize.height, sampleSize.width, sampleSize.height);
}


@end
