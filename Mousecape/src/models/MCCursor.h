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
@property (copy)   NSString          *name;
@property (weak)   NSString          *identifier;
@property (weak)   MCCursorLibrary   *parentLibrary;
//@property (assign) NSUInteger        repeatCount; // v2.01

// creating a cursor from a dictionary
+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;
- (id)initWithCursorDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;

- (void)addRepresentation:(NSBitmapImageRep *)imageRep;
- (void)removeRepresentation:(NSBitmapImageRep *)imageRep;

- (NSImage *)imageWithAllReps;
- (NSDictionary *)dictionaryRepresentation;

- (NSString *)prettyName;

@end

@interface MCCursor (Properties)
@property (readonly, strong) NSArray *representations;
@end