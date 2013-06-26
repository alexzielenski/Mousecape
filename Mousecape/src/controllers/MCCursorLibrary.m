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

- (instancetype)initWithContentsOfFile:(NSString *)path {
    return [self initWithContentsOfURL:[NSURL fileURLWithPath:path]];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:URL];
    return [self initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if ((self = [self init])) {
        self.cursors = [NSMutableDictionary dictionary];
        if (![self _readFromDictionary:dictionary]) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithCursors:(NSDictionary *)cursors {
    if ((self = [self init])) {
        self.cursors = cursors.mutableCopy;
    }
    
    return self;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.name = @"Unnamed";
        self.author = NSUserName();
        self.hiDPI = NO;
        self.inCloud = NO;
        self.identifier = [NSString stringWithFormat:@"local.%@.Unnamed.%f", self.author, [NSDate timeIntervalSinceReferenceDate]];
        self.version = @1.0;
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MCCursorLibrary *lib = [[MCCursorLibrary allocWithZone:zone] init];
    
    lib.cursors = [[NSMutableDictionary alloc] initWithDictionary:self.cursors copyItems:YES];
    [lib.cursors.allValues makeObjectsPerformSelector:@selector(setParentLibrary:) withObject:lib];
    
    lib.name             = self.name;
    lib.author           = self.author;
    lib.hiDPI            = self.hiDPI;
    lib.inCloud          = self.inCloud;
    lib.version          = self.version;
    lib.identifier       = self.identifier;

    return lib;
}

- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)atomically {
    return [self.dictionaryRepresentation writeToFile:file atomically:atomically];
}

- (BOOL)_readFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary || !dictionary.count) {
        NSLog(@"cannot make library from empty dicitonary");
        return NO;
    }
    
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
    
    if (!self.identifier) {
        NSLog(@"cannot make library from dictionary with no identifier");
        return NO;
    }
    
    CGFloat doubleVersion = version.doubleValue;
    
    if (minimumVersion.doubleValue > MCCursorParserVersion)
        return NO;
    
    [self.cursors removeAllObjects];
    [self addCursorsFromDictionary:cursorDicts ofVersion:doubleVersion];
    
    return YES;
}

- (void)addCursorsFromDictionary:(NSDictionary *)cursorDicts ofVersion:(CGFloat)doubleVersion {
    for (NSString *key in cursorDicts.allKeys) {
        NSDictionary *cursorDictionary = [cursorDicts objectForKey:key];
        MCCursor *cursor = [MCCursor cursorWithDictionary:cursorDictionary ofVersion:doubleVersion];
        
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
    if ([self.cursors objectForKey:identifier] != nil) {
        [self setCursor:nil forKey:identifier];
    }
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
    //!TODO: Provide KVO changes elsewhere
    
    if (!cursor) {
        MCCursor *c = self.cursors[key];
        [c willChangeValueForKey:@"prettyName"];
        [c willChangeValueForKey:@"identifier"];
        [c setParentLibrary:nil];
        [self.cursors removeObjectForKey:key];
        [c didChangeValueForKey:@"identifier"];
        [c didChangeValueForKey:@"prettyName"];
        
    } else {
        MCCursor *c = self.cursors[key];
        if (c) {
            [c willChangeValueForKey:@"prettyName"];
            [c willChangeValueForKey:@"identifier"];
            //! TODO: Provide nice way of handling naming conflicts
            [c didChangeValueForKey:@"identifier"];
            [c didChangeValueForKey:@"prettyName"];
        }
        
        [cursor willChangeValueForKey:@"prettyName"];
        [cursor willChangeValueForKey:@"identifier"];
        cursor.parentLibrary = self;
        [self.cursors setObject:cursor forKey:key];
        [cursor didChangeValueForKey:@"identifier"];
        [cursor didChangeValueForKey:@"prettyName"];
    }
    [self didChangeValueForKey:@"cursors"];
}

- (BOOL)isEqualTo:(MCCursorLibrary *)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    return ([object.name isEqualToString:self.name] &&
            [object.author isEqualToString:self.author] &&
            [object.identifier isEqualToString:self.identifier] &&
            [object.version isEqualToNumber:self.version] &&
            object.inCloud == self.inCloud &&
            object.isHiDPI == self.isHiDPI &&
            [object.cursors isEqualToDictionary:self.cursors]);
}
@end
