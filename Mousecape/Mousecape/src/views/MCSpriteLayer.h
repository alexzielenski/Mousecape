//
//  MCSpriteLayer.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/10/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface MCSpriteLayer : CALayer
@property (assign) NSUInteger frameCount;
@property (assign) NSUInteger sampleIndex;
@end
