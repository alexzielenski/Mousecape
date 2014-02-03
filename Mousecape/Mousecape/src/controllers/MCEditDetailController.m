//
//  MCEditDetailController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCEditDetailController.h"

@interface MCEditDetailController ()

@end

@implementation MCEditDetailController

- (void)awakeFromNib {
    [self.typePopUpButton addItemWithTitle:@"Unknown"];
    [[self.typePopUpButton itemAtIndex:0] setTag:-1];
    [self.typePopUpButton addItemsWithTitles:[cursorMap().allValues sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
}


@end

@implementation MCCursorTypeValueTransformer

+ (Class)transformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    return nameForCursorIdentifier(value);
}

- (id)reverseTransformedValue:(id)value {
    return cursorIdentifierForName(value);
}

@end
