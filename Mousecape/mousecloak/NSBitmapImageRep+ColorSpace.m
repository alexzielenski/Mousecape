//
//  NSBitmapImageRep+ColorSpace.m
//  mousecloak
//
//  Created by Alexander Zielenski on 12/30/18.
//  Copyright © 2018 Alex Zielenski. All rights reserved.
//

#import "NSBitmapImageRep+ColorSpace.h"

@implementation NSBitmapImageRep (ColorSpace)

// Must be careful with this because the PNGFileType representationForType of NSBitmapImageRep
//  does not encode the colorspace :(
- (NSBitmapImageRep *)ensuredSRGBSpace {
    NSColorSpace *targetSpace = [NSColorSpace sRGBColorSpace];
    if (self.colorSpace != NULL) {
        if (self.colorSpace.numberOfColorComponents == 1) {
            targetSpace = [NSColorSpace genericGamma22GrayColorSpace];
        }
    }
    return [self bitmapImageRepByConvertingToColorSpace:targetSpace
                                        renderingIntent:NSColorRenderingIntentDefault];
}

- (NSBitmapImageRep *)retaggedSRGBSpace {
    NSColorSpace *targetSpace = [NSColorSpace sRGBColorSpace];
    if (self.colorSpace != NULL) {
        if (self.colorSpace.numberOfColorComponents == 1) {
            targetSpace = [NSColorSpace genericGamma22GrayColorSpace];
        }
    }
    return [self bitmapImageRepByRetaggingWithColorSpace:targetSpace];
}

@end
