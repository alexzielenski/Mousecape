//
//  MCCursor.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCCursor : NSObject

@property (strong) NSArray           *representations;
@property (assign) CGFloat           frameDuration;
@property (assign) NSUInteger        frameCount;
@property (assign) NSSize            size;
@property (assign) NSPoint           hotSpot; 
@property (copy)   NSString          *name;

// creating a cursor from a dictionary
+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;
- (id)initWithCursorDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version;

- (NSImage *)imageWithAllReps;

@end
