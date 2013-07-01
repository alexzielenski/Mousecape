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
@property (nonatomic, assign) CGFloat           frameDuration;
@property (nonatomic, assign) NSUInteger        frameCount;
@property (nonatomic, assign) NSSize            size;
@property (nonatomic, assign) NSPoint           hotSpot; 
@property (nonatomic, copy)   NSString          *identifier;
@property (nonatomic, weak)   MCCursorLibrary   *parentLibrary;
//@property (assign) NSUInteger        repeatCount; // v2.01

// creating a cursor from a dictionary
+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;
- (id)initWithCursorDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;

- (void)addRepresentation:(NSImageRep *)imageRep;
- (void)removeRepresentation:(NSImageRep *)imageRep;


- (NSImageRep *)representationWithScale:(CGFloat)scale;
- (NSImageRep *)smallestRepresentationWithScale:(CGFloat *)scale;

- (NSDictionary *)dictionaryRepresentation;

// Derived Properties
- (NSArray *)keyReps;
- (NSString *)prettyName;
- (NSImage *)imageWithAllReps;
- (NSImage *)imageWithKeyReps;

@end

@interface MCCursor (Properties)
@property (nonatomic, readonly, strong) NSOrderedSet *representations;
@end
