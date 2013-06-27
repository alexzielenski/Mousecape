//
//  MCCursorLibrary.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCursor.h"

@interface MCCursorLibrary : NSObject <NSCopying>
@property (copy)   NSString *name;
@property (copy)   NSString *author;
@property (copy)   NSString *identifier;
@property (copy)   NSNumber *version;
@property (assign, getter = isInCloud) BOOL inCloud;
@property (assign, getter = isHiDPI)   BOOL hiDPI;

+ (MCCursorLibrary *)cursorLibraryWithContentsOfFile:(NSString *)path;
+ (MCCursorLibrary *)cursorLibraryWithContentsOfURL:(NSURL *)URL;
+ (MCCursorLibrary *)cursorLibraryWithDictionary:(NSDictionary *)dictionary;
+ (MCCursorLibrary *)cursorLibraryWithCursors:(NSSet *)cursors;

- (instancetype)initWithContentsOfFile:(NSString *)path;
- (instancetype)initWithContentsOfURL:(NSURL *)URL;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithCursors:(NSSet *)cursors;

- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)atomically;

- (void)addCursor:(MCCursor *)cursor;
- (void)removeCursor:(MCCursor *)cursor;

- (MCCursor *)cursorWithIdentifier:(NSString *)identifier;

+ (NSDictionary *)cursorMap;
- (NSDictionary *)dictionaryRepresentation;

@end

@interface MCCursorLibrary (Properties)
@property (nonatomic, readonly, strong) NSSet *cursors;
@end
