//
//  MCCursor.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCCursorLibrary;
@interface MCCursor : NSObject <NSCopying>

@property (assign) CGFloat           frameDuration;
@property (assign) NSUInteger        frameCount;
@property (assign) NSSize            size;
@property (assign) NSPoint           hotSpot; 
@property (copy)   NSString          *identifier;
@property (weak)   MCCursorLibrary   *parentLibrary;
//@property (assign) NSUInteger        repeatCount; // v2.01

// creating a cursor from a dictionary
+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;
- (id)initWithCursorDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;

- (void)addRepresentation:(NSImageRep *)imageRep;
- (void)removeRepresentation:(NSImageRep *)imageRep;

- (NSArray *)keyReps;

- (NSImage *)imageWithAllReps;
- (NSImage *)imageWithKeyReps;
- (NSDictionary *)dictionaryRepresentation;

- (NSString *)prettyName;
- (NSImageRep *)representationWithScale:(CGFloat)scale;
- (NSImageRep *)smallestRepresentationWithScale:(CGFloat *)scale;

@end

@interface MCCursor (Properties)
@property (readonly, strong) NSOrderedSet *representations;
@end