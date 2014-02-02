//
//  MCCursorLibrary.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCCursorLibrary.h"

@interface MCCursorLibrary ()
@property (nonatomic, readwrite, strong) NSMutableDictionary *cursors;
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary;
- (void)addCursorsFromDictionary:(NSDictionary *)cursorDicts ofVersion:(CGFloat)doubleVersion;
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

+ (MCCursorLibrary *)cursorLibraryWithCursors:(NSDictionary *)cursors {
    return [[MCCursorLibrary alloc] initWithCursors:cursors];
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
        self.cursors = [NSMutableDictionary dictionary];
    }
    
    return self;
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
        [self setCursor:cursor forIdentifier:key];
    }
}


- (MCCursor *)cursorWithIdentifier:(NSString *)identifier {
    return self.cursors[identifier];
}

- (void)setCursor:(MCCursor *)cursor forIdentifier:(NSString *)identifier {
    NSAssert(identifier != nil, @"Cannot set %@ for a NULL identifier", cursor);
    [self willChangeValueForKey:@"cursors"];
    MCCursor *original = [self cursorWithIdentifier:identifier];
    if (original)
        original.name = @"";
    
    if (cursor) {
        self.cursors[identifier] = cursor;
        cursor.name = nameForCursorIdentifier(identifier);
    } else
        [self.cursors removeObjectForKey:identifier];
    
    [self didChangeValueForKey:@"cursors"];
}

- (void)removeCursorForIdentififer:(NSString *)identifier {
    [self setCursor:nil forIdentifier:identifier];
}

- (void)moveCursorAtIdentifier:(NSString *)from toIdentifier:(NSString *)to {
    __strong MCCursor *cursor = [self cursorWithIdentifier:from];
    if (!cursor)
        return;
    [self removeCursorForIdentififer:from];
    [self setCursor:cursor forIdentifier:to];
    cursor = nil;
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
    for (NSString *identifier in self.cursors) {
        MCCursor *cursor = self.cursors[identifier];
        cursors[identifier] = [cursor dictionaryRepresentation];
    }
    
    drep[MCCursorDictionaryCursorsKey] = cursors;
    
    return drep;
}

- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)atomically {
    return [self.dictionaryRepresentation writeToFile:file atomically:atomically];
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

- (BOOL)isEqual:(id)object {
    return [self isEqualTo:object];
}

@end
