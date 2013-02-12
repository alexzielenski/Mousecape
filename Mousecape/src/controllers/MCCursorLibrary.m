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
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary;

// KVO Backing
- (void)setCursor:(MCCursor *)cursor forKey:(NSString *)key;

@end

@implementation MCCursorLibrary

+ (MCCursorLibrary *)cursorLibraryWithContentsOfFile:(NSString *)path {
    return [[MCCursorLibrary alloc] initWithContentsOfFile:path];
}
+ (MCCursorLibrary *)cursorLibraryWithContentsOfURL:(NSURL *)URL {
    return [[MCCursorLibrary alloc] initWithContentsOfURL:URL];
}
+ (MCCursorLibrary *)cursorLibraryWithDictionary:(NSDictionary *)dictionary {
    return [[MCCursorLibrary alloc] initWithDictionary:dictionary];
}
- (id)initWithContentsOfFile:(NSString *)path {
    return [self initWithContentsOfURL:[NSURL fileURLWithPath:path]];
}
- (id)initWithContentsOfURL:(NSURL *)URL {
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
+ (NSDictionary *)cursorMap {
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"CursorMap" ofType:@"plist"]];
    });
    
    return map;
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
    
    CGFloat doubleVersion = version.doubleValue;
    
    if (minimumVersion.doubleValue > MCCursorParserVersion)
        return NO;
    
    [self.cursors removeAllObjects];
    for (NSString *key in cursorDicts.allKeys) {
        NSDictionary *cursorDictionary = [cursorDicts objectForKey:key];
        MCCursor *cursor = [MCCursor cursorWithDictionary:cursorDictionary ofVersion:doubleVersion];

        NSString *name = [MCCursorLibrary.cursorMap objectForKey:key];
        if (name)
            cursor.name = name;
        
        [self addCursor:cursor forIdentifier:key];
    }
    
    if (self.cursors.count == 0)
        return NO;
    
    return YES;
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
- (void)setCursor:(MCCursor *)cursor forKey:(NSString *)key {
    [self willChangeValueForKey:@"cursors"];
    if (!cursor)
        [self.cursors removeObjectForKey:key];
    else
        [self.cursors setObject:cursor forKey:key];
    [self didChangeValueForKey:@"cursors"];
}
@end
