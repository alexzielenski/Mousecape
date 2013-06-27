//
//  NSImage+BestRep.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "NSImage+BestRep.h"

static CGFloat distance(CGFloat dX, CGFloat dY) {
    return sqrt(pow(dX, 2) + pow(dY, 2));
}

@implementation NSImage (BestRep)

- (NSImageRep *)bestRepresentationForContentsScale:(CGFloat)scale {
    NSSize scaledSize = NSMakeSize(self.size.width * scale, self.size.height * scale);
    
    NSImageRep *closestMatch = nil;
    CGFloat closestDistance = 0;
    
    for (NSImageRep *rep in self.representations) {
        if ([rep isKindOfClass:[NSPDFImageRep class]])
            return rep;
        
        CGFloat deltaW = rep.pixelsWide - scaledSize.width;
        CGFloat deltaH = rep.pixelsHigh - scaledSize.height;
        
        
        // exact match
        if (deltaW == 0 && deltaH == 0) {
            return rep;
        }
        
        CGFloat dist = distance(deltaW, deltaH);
        
        // start up
        if (!closestMatch || dist < closestDistance) {
            closestMatch = rep;
            closestDistance = dist;
            continue;
        }
    }
    
    return closestMatch;
}

@end
