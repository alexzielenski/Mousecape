//
//  MCSpriteLayer.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/10/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

// derived from http://mysterycoconut.com/blog/2011/01/cag1/
@interface MCSpriteLayer : CALayer
@property (assign) NSUInteger sampleIndex;
@property (strong) NSImage *image;
@property (assign) NSSize sampleSize;

+ (MCSpriteLayer *)layerWithImage:(NSImage *)image sampleSize:(CGSize)size;
- (id)initWithImage:(NSImage *)image sampleSize:(CGSize)size;

- (NSUInteger)currentSampleIndex;

@end
