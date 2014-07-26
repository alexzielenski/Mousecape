//
//  MCCapeCellView.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCCapeCellView.h"
#import "MCCapePreviewItem.h"

@interface MCCapeCellView ()
@end

@interface MCSortValueTransformer : NSValueTransformer
@end

@implementation MCCapeCellView

- (void)viewDidMoveToWindow {
    self.collectionView.itemPrototype = [MCCapePreviewItem new];
    [self.collectionView bind:NSContentBinding toObject:self withKeyPath:@"objectValue.cursors" options:@{ NSValueTransformerBindingOption: [MCSortValueTransformer new] }];
    
    self.collectionView.minItemSize = self.collectionView.itemPrototype.view.frame.size;
    self.collectionView.maxItemSize = self.collectionView.minItemSize;
}

- (void)dealloc {
    [self.collectionView unbind:NSContentBinding];
}

@end

@implementation MCSortValueTransformer

+ (Class)transformedValueClass {
    return [NSSet class];
}

- (NSArray *)transformedValue:(NSSet *)value {
    return [value sortedArrayUsingDescriptors: @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)] ]];
}

@end

@implementation MCHDValueTransformer

+ (Class)transformedValueClass {
    return [NSImage class];
}

- (NSImage *)transformedValue:(NSNumber *)value {
    BOOL isHiDPI = value.boolValue;
    
    NSImage *image = isHiDPI ? [NSImage imageNamed:@"HDTemplate"] : [NSImage imageNamed:@"SDTemplate"];
    image.template = YES;
    
    return image;
}

@end