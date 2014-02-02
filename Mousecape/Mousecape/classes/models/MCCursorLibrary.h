//
//  MCCursorLibrary.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCursor.h"

@interface MCCursorLibrary : NSObject
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, copy)   NSString *author;
@property (nonatomic, copy)   NSString *identifier;
@property (nonatomic, copy)   NSNumber *version;
@property (nonatomic, copy)   NSURL    *fileURL;
@property (nonatomic, assign, getter = isInCloud) BOOL inCloud;
@property (nonatomic, assign, getter = isHiDPI)   BOOL hiDPI;

+ (MCCursorLibrary *)cursorLibraryWithContentsOfFile:(NSString *)path;
+ (MCCursorLibrary *)cursorLibraryWithContentsOfURL:(NSURL *)URL;
+ (MCCursorLibrary *)cursorLibraryWithDictionary:(NSDictionary *)dictionary;
+ (MCCursorLibrary *)cursorLibraryWithCursors:(NSDictionary *)cursors;

- (instancetype)initWithContentsOfFile:(NSString *)path;
- (instancetype)initWithContentsOfURL:(NSURL *)URL;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithCursors:(NSDictionary *)cursors;

- (MCCursor *)cursorWithIdentifier:(NSString *)identifier;
- (void)setCursor:(MCCursor *)cursor forIdentifier:(NSString *)identifier;
- (void)removeCursorForIdentififer:(NSString *)identifier;
- (void)moveCursorAtIdentifier:(NSString *)from toIdentifier:(NSString *)to;

- (NSDictionary *)dictionaryRepresentation;
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)atomically;

@end

@interface MCCursorLibrary (Properties)
@property (nonatomic, readonly, strong) NSDictionary *cursors;
@end