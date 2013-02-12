//
//  MCCursorLibrary.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCursor.h"

@interface MCCursorLibrary : NSObject
@property (copy)   NSString *name;
@property (copy)   NSString *author;
@property (copy)   NSString *identifier;
@property (copy)   NSNumber *version;
@property (assign, getter = isInCloud) BOOL inCloud;
@property (assign, getter = isHiDPI)   BOOL hiDPI;

+ (MCCursorLibrary *)cursorLibraryWithContentsOfFile:(NSString *)path;
+ (MCCursorLibrary *)cursorLibraryWithContentsOfURL:(NSURL *)URL;
+ (MCCursorLibrary *)cursorLibraryWithDictionary:(NSDictionary *)dictionary;

- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfURL:(NSURL *)URL;
- (id)initWithDictionary:(NSDictionary *)dictionary;

- (void)addCursor:(MCCursor *)cursor forIdentifier:(NSString *)identifier;
- (void)removeCursor:(MCCursor *)cursor;
- (void)removeCursorForIdentifier:(NSString *)identifier;

+ (NSDictionary *)cursorMap;

@end

@interface MCCursorLibrary (Properties)
@property (readonly, strong) NSDictionary *cursors;
@end