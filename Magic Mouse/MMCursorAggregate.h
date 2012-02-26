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

+ (MMCursor *)cursorWithDictionary:(NSDictionary *)dict;
- (id)initWithCursorDictionary:(NSDictionary *)dict;
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

- (void)setCursor:(MMCursor *)cursor forDomain:(NSString *)domain;
- (void)removeCursorForDomain:(NSString *)domain;
- (MMCursor *)cursorForTableIdentifier:(NSString *)identifier;

- (NSDictionary *)dictionaryRepresentation;
@end