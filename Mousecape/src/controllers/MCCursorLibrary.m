//
//  MCCursorLibrary.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCCursorLibrary.h"

static const CGFloat   MCCursorParserVersion = 2.0;
static const NSString *MCCursorDictionaryMinimumVersionKey = @"MinimumVersion";
static const NSString *MCCursorDictionaryVersionKey        = @"Version";
static const NSString *MCCursorDictionaryCursorsKey        = @"Cursors";
static const NSString *MCCursorDictionaryAuthorKey         = @"Author";
static const NSString *MCCursorDictionaryCloudKey          = @"Cloud";
static const NSString *MCCursorDictionaryHiDPIKey          = @"HiDPI";
static const NSString *MCCursorDictionaryIdentifierKey     = @"Identifier";
static const NSString *MCCursorDictionaryCapeNameKey       = @"CapeName";
static const NSString *MCCursorDictionaryCapeVersionKey    = @"CapeVersion";

@interface MCCursorLibrary ()
@property (readwrite, strong) NSMutableDictionary *cursors;
@property (readwrite, copy) NSURL *originalURL;
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary;
- (void)addCursorsFromDictionary:(NSDictionary *)cursorDicts ofVersion:(CGFloat)doubleVersion;

// KVO Backing
- (void)setCursor:(MCCursor *)cursor forKey:(NSString *)key;

@end

@implementation MCCursorLibrary
+ (NSDictionary *)cursorMap {
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"CursorMap" ofType:@"plist"]];
    });
    
    return map;
}
+ (MCCursorLibrary *)cursorLibraryWithContentsOfFile:(NSString *)path {
    return [[MCCursorLibrary alloc] initWithContentsOfFile:path];
}
+ (MCCursorLibrary *)cursorLibraryWithContentsOfURL:(NSURL *)URL {
    return [[MCCursorLibrary alloc] initWithContentsOfURL:URL];
}
+ (MCCursorLibrary *)cursorLibraryWithDictionary:(NSDictionary *)dictionary {
    return [[MCCursorLibrary alloc] initWithDictionary:dictionary];
}
+ (MCCursorLibrary *)cursorLibraryWithCursors:(NSDictionary *)dictionary {
    return [[MCCursorLibrary alloc] initWithCursors:dictionary];
}
- (id)initWithContentsOfFile:(NSString *)path {
    return [self initWithContentsOfURL:[NSURL fileURLWithPath:path]];
}
- (id)initWithContentsOfURL:(NSURL *)URL {
    self.originalURL = URL;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:URL];
    return [self initWithDictionary:dictionary];
}
- (id)initWithDictionary:(NSDictionary *)dictionary {
    if ((self = [super init])) {
        self.cursors = [NSMutableDictionary dictionary];
        if (![self _readFromDictionary:dictionary]) {
            return nil;
        }
    }
    return self;
}
- (id)initWithCursors:(NSDictionary *)cursors {
    if ((self = [super init])) {
        self.cursors = cursors.mutableCopy;
    }
    
    return self;
}
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)atomically {
    return [self.dictionaryRepresentation writeToFile:file atomically:atomically];
}

- (BOOL)_readFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary)
        return NO;
    
    NSNumber *minimumVersion  = dictionary[MCCursorDictionaryMinimumVersionKey];
    NSNumber *version         = dictionary[MCCursorDictionaryVersionKey];
    NSDictionary *cursorDicts = dictionary[MCCursorDictionaryCursorsKey];
    NSNumber *cloud           = dictionary[MCCursorDictionaryCloudKey];
    NSString *author          = dictionary[MCCursorDictionaryAuthorKey];
    NSNumber *hiDPI           = dictionary[MCCursorDictionaryHiDPIKey];
    NSString *identifier      = dictionary[MCCursorDictionaryIdentifierKey];
    NSString *capeName        = dictionary[MCCursorDictionaryCapeNameKey];
    NSNumber *capeVersion     = dictionary[MCCursorDictionaryCapeVersionKey];
    
    self.name       = capeName;
    self.version    = capeVersion;
    self.author     = author;
    self.identifier = identifier;
    self.hiDPI      = hiDPI.boolValue;
    self.inCloud    = cloud.boolValue;
    
    if (!self.identifier)
        return NO;
    
    CGFloat doubleVersion = version.doubleValue;
    
    if (minimumVersion.doubleValue > MCCursorParserVersion)
        return NO;
    
    [self.cursors removeAllObjects];
    [self addCursorsFromDictionary:cursorDicts ofVersion:doubleVersion];
    
    if (self.cursors.count == 0)
        return NO;
    
    return YES;
}
- (void)addCursorsFromDictionary:(NSDictionary *)cursorDicts ofVersion:(CGFloat)doubleVersion {
    for (NSString *key in cursorDicts.allKeys) {
        NSDictionary *cursorDictionary = [cursorDicts objectForKey:key];
        MCCursor *cursor = [MCCursor cursorWithDictionary:cursorDictionary ofVersion:doubleVersion];
        
        NSString *name = [MCCursorLibrary.cursorMap objectForKey:key];
        if (name)
            cursor.name = name;
        
        [self addCursor:cursor forIdentifier:key];
    }
}
- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *drep = [NSMutableDictionary dictionary];
    
    drep[MCCursorDictionaryMinimumVersionKey] = @(2.0);
    drep[MCCursorDictionaryVersionKey]        = @(2.0);
    drep[MCCursorDictionaryCapeNameKey]       = self.name;
    drep[MCCursorDictionaryCapeVersionKey]    = self.version;
    drep[MCCursorDictionaryCloudKey]          = @(self.inCloud);
    drep[MCCursorDictionaryAuthorKey]         = self.author;
    drep[MCCursorDictionaryHiDPIKey]          = @(self.isHiDPI);
    drep[MCCursorDictionaryIdentifierKey]     = self.identifier;
    
    NSMutableDictionary *cursors = [NSMutableDictionary dictionary];
    for (NSString *key in self.cursors) {
        cursors[key] = [[self.cursors objectForKey:key] dictionaryRepresentation];
    }
    
    drep[MCCursorDictionaryCursorsKey] = cursors;
    
    return drep;
}
- (void)addCursor:(MCCursor *)cursor forIdentifier:(NSString *)identifier {
    if (cursor) {
        [self setCursor:cursor forKey:identifier];
    }
}
- (void)removeCursor:(MCCursor *)cursor {
    NSArray *keys = [self.cursors allKeysForObject:cursor];
    for (NSString *key in keys)
        [self setCursor:nil forKey:key];
}
- (void)removeCursorForIdentifier:(NSString *)identifier {
    if ([self.cursors objectForKey:identifier] != nil)
        [self setCursor:nil forKey:identifier];
}

- (void)moveCursor:(MCCursor *)cursor toIdentifier:(NSString *)identifier {
    if (!identifier)
        return;
    
    NSString *ident = [self identifierForCursor:cursor];
    if (ident)
        [self setCursor:nil forKey:ident];
    [self setCursor:cursor forKey:identifier];
}

- (NSString *)identifierForCursor:(MCCursor *)cursor {
    NSArray *allKeys = [self.cursors allKeysForObject:cursor];
    if (allKeys.count > 0)
        return allKeys[0];
    return nil;
}
- (void)setCursor:(MCCursor *)cursor forKey:(NSString *)key {
    [self willChangeValueForKey:@"cursors"];
    if (!cursor)
        [self.cursors removeObjectForKey:key];
    else
        [self.cursors setObject:cursor forKey:key];
    [self didChangeValueForKey:@"cursors"];
}
@end
