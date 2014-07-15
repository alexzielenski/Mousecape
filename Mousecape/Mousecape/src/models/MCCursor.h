//
//  MCCursor.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MCCursorScale) {
    MCCursorScaleNone = 000,
    MCCursorScale100  = 100,
    MCCursorScale200  = 200,
    MCCursorScale500  = 500,
    MCCursorScale1000 = 1000
};

extern MCCursorScale cursorScaleForScale(CGFloat scale);

@interface MCCursor : NSObject <NSCopying>
@property (nonatomic, copy)     NSString          *identifier;
@property (nonatomic, readonly) NSString          *name;
@property (nonatomic, assign)   CGFloat           frameDuration;
@property (nonatomic, assign)   NSUInteger        frameCount;
@property (nonatomic, assign)   NSSize            size;
@property (nonatomic, assign)   NSPoint           hotSpot;
//@property (assign) NSUInteger        repeatCount; // v2.01

// creating a cursor from a dictionary
+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;
- (id)initWithCursorDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;

- (void)setRepresentation:(NSImageRep *)imageRep forScale:(MCCursorScale)scale;
- (void)removeRepresentationForScale:(MCCursorScale)scale;
- (void)addFrame:(NSImageRep *)frame forScale:(MCCursorScale)scale;

- (NSImageRep *)representationForScale:(MCCursorScale)scale;
- (NSImageRep *)representationWithScale:(CGFloat)scale;

- (NSDictionary *)dictionaryRepresentation;
+ (NSImageRep *)composeRepresentationWithFrames:(NSArray *)frames;

// Derived Properties
- (NSImage *)imageWithAllReps;
@end

@interface MCCursor (Properties)
@property (nonatomic, readonly, strong) NSDictionary *representations;
@end