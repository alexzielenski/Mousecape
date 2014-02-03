//
//  MCCapeCellView.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCCapeCellView.h"

@implementation MCCapeCellView

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    [super setBackgroundStyle:backgroundStyle];
    
    // 
}

@end

@implementation MCHDValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

- (NSString *)transformedValue:(NSNumber *)value {
    BOOL isHiDPI = value.boolValue;
    return isHiDPI ? [NSImage imageNamed:@"HDTemplate"] : [NSImage imageNamed:@"SDTemplate"];
}


@end