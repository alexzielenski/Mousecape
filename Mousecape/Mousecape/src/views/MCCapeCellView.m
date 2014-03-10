//
//  MCCapeCellView.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCCapeCellView.h"
#import "MCCapePreviewItem.h"

@implementation MCCapeCellView

- (void)viewDidMoveToWindow {
    self.collectionView.itemPrototype = [MCCapePreviewItem new];
    [self.collectionView bind:NSContentBinding toObject:self withKeyPath:@"objectValue.cursors" options:nil];

    self.collectionView.minItemSize = self.collectionView.itemPrototype.view.frame.size;
    self.collectionView.maxItemSize = self.collectionView.minItemSize;
}

- (void)dealloc {
    [self.collectionView unbind:NSContentBinding];
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