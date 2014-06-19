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
    
    *error = [[NSError errorWithDomain:MCErrorDomain code:MCErrorInvalidFormatCode userInfo:@{
                                                                                             NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid format", @"Invalid format error description in edit window"),
                                                                                             NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Must follow format of: \"{0.0, 0.0}\"." , @"Invalid format error reason in edit window")}] localizedDescription];
    return NO;
}

@end

@implementation MCSizeFormatter

- (NSString *)stringForObjectValue:(NSValue *)anObject {
    
    if (![anObject isKindOfClass:[NSValue class]]) {
        return nil;
    }
    return NSStringFromSize(anObject.sizeValue);
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error {
    *anObject = [NSValue valueWithSize:NSSizeFromString(string)];
    return YES;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error {
    NSArray *components = [partialString componentsSeparatedByString:@","];
    if (components.count == 1) {
        return YES;
    } else if (components.count == 2) {
        NSString *perfect = NSStringFromSize(NSSizeFromString(partialString));
        *newString = perfect;
        return YES;
    }
    
    *error = [[NSError errorWithDomain:MCErrorDomain code:MCErrorInvalidFormatCode userInfo:@{
                                                                                             NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid format", @"Invalid format error description in edit window"),
                                                                                             NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Must follow format of: \"{0.0, 0.0}\"." , @"Invalid format error reason in edit window")}] localizedDescription];
    return NO;
}


@end

