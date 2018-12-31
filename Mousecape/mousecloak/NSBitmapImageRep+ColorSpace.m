//
//  NSBitmapImageRep+ColorSpace.m
//  mousecloak
//
//  Created by Alexander Zielenski on 12/30/18.
//  Copyright © 2018 Alex Zielenski. All rights reserved.
//

#import "NSBitmapImageRep+ColorSpace.h"

@implementation NSBitmapImageRep (ColorSpace)
- (NSBitmapImageRep *)ensuredSRGBSpace {
    NSColorSpace *targetSpace = [NSColorSpace sRGBColorSpace];
    if (self.colorSpace != NULL) {
        if (self.colorSpace.numberOfColorComponents == 1) {
            targetSpace = [NSColorSpace genericGamma22GrayColorSpace];
        }
    }
    return [self bitmapImageRepByRetaggingWithColorSpace:targetSpace];
}
- (CGImageRef)copyEnsuredCGImage {
    CGImageRef ref = self.ensuredSRGBSpace.CGImage;
    CGColorSpaceRef space = CGImageGetColorSpace(ref);
    NSColorSpace *targetSpace = [NSColorSpace sRGBColorSpace];
    if (space != NULL) {
        if (CGColorSpaceGetNumberOfComponents(space) == 1) {
            targetSpace = [NSColorSpace genericGamma22GrayColorSpace];
        }
    }
    
    return CGImageCreateCopyWithColorSpace(ref, space);
}
@end
