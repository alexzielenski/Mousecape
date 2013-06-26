//
//  MCFormatters.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/24/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCFormatters.h"

@implementation MCPointFormatter

- (NSString *)stringForObjectValue:(NSValue *)anObject {
    
    if (![anObject isKindOfClass:[NSValue class]]) {
        return nil;
    }
    return NSStringFromPoint(anObject.pointValue);
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
    *anObject = [NSValue valueWithPoint:NSPointFromString(string)];
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error {
    NSArray *components = [partialString componentsSeparatedByString:@","];
    if (components.count == 1) {
        return YES;
    } else if (components.count == 2) {
        NSString *perfect = NSStringFromPoint(NSPointFromString(partialString));
        *newString = perfect;
        return YES;
    }
    
    *error = [NSError errorWithDomain:@"com.alexzielenski.mcformatter.errordoman" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid format. Must follow \"{0.0, 0.0}\"." , @"Invalid format error in edit window")}];
    return NO;
}

@end

@implementation MCSizeFormatter

@end

