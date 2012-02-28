//
//  MMCursorAggregate.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMCursor : NSObject
@property (nonatomic, retain) NSBitmapImageRep  *image;
@property (nonatomic, assign) CGFloat           frameDuration;
@property (nonatomic, assign) NSInteger         frameCount;
@property (nonatomic, assign) NSSize            size;
@property (nonatomic, assign) NSPoint           hotSpot;

@property (nonatomic, retain) NSString          *tableIdentifier;
@property (nonatomic, retain) NSString          *defaultKey;
@property (nonatomic, retain) NSString          *customKey;
@property (nonatomic, retain) NSString          *name;
@property (nonatomic, retain) NSString          *cursorIdentifier;

// creating a cursor from a dictionary
+ (MMCursor *)cursorWithDictionary:(NSDictionary *)dict;
- (id)initWithCursorDictionary:(NSDictionary *)dict;

// Creating a dictionary from the cursor
- (NSDictionary *)cursorDictionary;
- (NSDictionary *)infoDictionary;

@end


@interface MMCursorAggregate : NSObject {
@private
	NSMutableDictionary *_cursors;
}
@property (nonatomic, retain) NSDictionary *cursors;
@property (nonatomic, retain) NSString *minimumVersion;
@property (nonatomic, retain) NSString *creatorVersion;

+ (MMCursorAggregate *)aggregateWithDictionary:(NSDictionary *)dict;
- (id)initWithAggregateDictionary:(NSDictionary *)dict;

// A domain would be the internal reverse-dns identifier used to tag cursors like com.apple.coregraphics.Arrow
- (void)setCursor:(MMCursor *)cursor forDomain:(NSString *)domain;
- (void)removeCursorForDomain:(NSString *)domain;

// Retrieves (if it exists) a cursor in the _cursors ivar with the specified table identifier
- (MMCursor *)cursorForTableIdentifier:(NSString *)identifier;

- (NSDictionary *)dictionaryRepresentation;

@end