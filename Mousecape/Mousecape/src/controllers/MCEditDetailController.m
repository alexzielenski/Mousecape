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
    [self.typePopUpButton addItemsWithTitles:[cursorMap().allValues sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]];
    
    NSImage *dropzone = [NSImage imageNamed:@"dropzone"];
    self.rep100View.placeholderImage = dropzone;
    self.rep200View.placeholderImage = dropzone;
    self.rep500View.placeholderImage = dropzone;
    self.rep1000View.placeholderImage = dropzone;
    
    self.rep100View.scale  = 1.0;
    self.rep200View.scale  = 2.0;
    self.rep500View.scale  = 5.0;
    self.rep1000View.scale = 10.0;
    
    [self.rep100View bind:@"image" toObject:self withKeyPath:@"cursor.cursorImage100" options:nil];
    [self.rep100View bind:@"frameCount" toObject:self withKeyPath:@"cursor.frameCount" options:nil];
    [self.rep100View bind:@"frameDuration" toObject:self withKeyPath:@"cursor.frameDuration" options:nil];
    [self.rep100View bind:@"hotSpot" toObject:self withKeyPath:@"cursor.hotSpot" options:nil];
    
    [self.rep200View bind:@"image" toObject:self withKeyPath:@"cursor.cursorImage200" options:nil];
    [self.rep200View bind:@"frameCount" toObject:self withKeyPath:@"cursor.frameCount" options:nil];
    [self.rep200View bind:@"frameDuration" toObject:self withKeyPath:@"cursor.frameDuration" options:nil];
    [self.rep200View bind:@"hotSpot" toObject:self withKeyPath:@"cursor.hotSpot" options:nil];
    
    [self.rep500View bind:@"image" toObject:self withKeyPath:@"cursor.cursorImage500" options:nil];
    [self.rep500View bind:@"frameCount" toObject:self withKeyPath:@"cursor.frameCount" options:nil];
    [self.rep500View bind:@"frameDuration" toObject:self withKeyPath:@"cursor.frameDuration" options:nil];
    [self.rep500View bind:@"hotSpot" toObject:self withKeyPath:@"cursor.hotSpot" options:nil];
    
    [self.rep1000View bind:@"image" toObject:self withKeyPath:@"cursor.cursorImage1000" options:nil];
    [self.rep1000View bind:@"frameCount" toObject:self withKeyPath:@"cursor.frameCount" options:nil];
    [self.rep1000View bind:@"frameDuration" toObject:self withKeyPath:@"cursor.frameDuration" options:nil];
    [self.rep1000View bind:@"hotSpot" toObject:self withKeyPath:@"cursor.hotSpot" options:nil];
}

#pragma mark - MMAnimatingImageView

- (NSDragOperation)imageView:(MMAnimatingImageView *)imageView draggingEntered:(id <NSDraggingInfo>)drop {
    return NSDragOperationCopy;
}

- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPrepareForDragOperation:(id <NSDraggingInfo>)drop {
    return YES;
}

- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPerformDragOperation:(id <NSDraggingInfo>)drop {
    return YES;
}

- (void)imageView:(MMAnimatingImageView *)imageView didAcceptDroppedImages:(NSArray *)images {
    MCCursorScale scale = cursorScaleForScale(imageView.scale);
    
    if (NSEvent.modifierFlags == NSAlternateKeyMask) {
        [self.cursor addFrame:[MCCursor composeRepresentationWithFrames:images] forScale:scale];
    } else {
        [self.cursor setRepresentation:[MCCursor composeRepresentationWithFrames:images] forScale:scale];
        self.cursor.frameCount = images.count;
    }
}

- (void)imageView:(MMAnimatingImageView *)imageView didDragOutImage:(NSImage *)image {
    CGFloat scale = imageView.scale;
    [self.cursor setRepresentation:nil forScale:cursorScaleForScale(scale)];
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

