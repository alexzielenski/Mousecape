//
//  NSImage+BestRep.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "NSImage+BestRep.h"

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
