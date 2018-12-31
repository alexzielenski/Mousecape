//
//  NSBitmapImageRep+ColorSpace.h
//  mousecloak
//
//  Created by Alexander Zielenski on 12/30/18.
//  Copyright © 2018 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBitmapImageRep (ColorSpace)

- (NSBitmapImageRep *)ensuredSRGBSpace;
- (CGImageRef)copyEnsuredCGImage;
@end

NS_ASSUME_NONNULL_END
