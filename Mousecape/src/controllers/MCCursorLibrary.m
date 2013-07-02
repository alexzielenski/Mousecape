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
@property (nonatomic, readwrite, strong) NSMutableSet *cursors;
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary;
- (void)addCursorsFromDictionary:(NSDictionary *)cursorDicts ofVersion:(CGFloat)doubleVersion;
@end

@implementation MCCursorLibrary
@dynamic hiDPI;

+ (NSDictionary *)cursorMap {
    static NSDictionary *map = nil;
    
    if (!map) {
        map = [NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"CursorMap" ofType:@"plist"]];
    }
    
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

+ (MCCursorLibrary *)cursorLibraryWithCursors:(NSSet *)set {
    return [[MCCursorLibrary alloc] initWithCursors:set];
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
        self.cursors = [NSMutableSet set];
        if (![self _readFromDictionary:dictionary]) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithCursors:(NSSet *)cursors {
    if ((self = [self init])) {
        self.cursors = cursors.mutableCopy;
    }
    
    return self;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.name = @"Unnamed";
        self.author = NSUserName();
//        self.hiDPI = NO;
        self.inCloud = NO;
        self.identifier = [NSString stringWithFormat:@"local.%@.Unnamed.%f", self.author, [NSDate timeIntervalSinceReferenceDate]];
        self.version = @1.0;
        self.cursors = [NSMutableSet set];
    }
    
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    MCCursorLibrary *lib = [[MCCursorLibrary allocWithZone:zone] init];
    
    for (MCCursor *c in self.cursors) {
        [lib addCursor:c.copy];
    }
    
    lib.name             = self.name;
    lib.author           = self.author;
//    lib.hiDPI            = self.hiDPI;
    lib.inCloud          = self.inCloud;
    lib.version          = self.version;
    lib.identifier       = self.identifier;

    return lib;
}

static id <MCCursorLibraryValidator> _validator;
+ (id <MCCursorLibraryValidator>)validator {
    return _validator;
}

+ (void)setValidator:(id <MCCursorLibraryValidator>)validator {
    _validator = validator;
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
//    NSNumber *hiDPI           = dictionary[MCCursorDictionaryHiDPIKey];
    NSString *identifier      = dictionary[MCCursorDictionaryIdentifierKey];
    NSString *capeName        = dictionary[MCCursorDictionaryCapeNameKey];
    NSNumber *capeVersion     = dictionary[MCCursorDictionaryCapeVersionKey];
    
    self.name       = capeName;
    self.version    = capeVersion;
    self.author     = author;
    self.identifier = identifier;
//    self.hiDPI      = hiDPI.boolValue;
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
        cursor.identifier = key;
        [self addCursor:cursor];
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
    for (MCCursor *cursor in self.cursors) {
        cursors[cursor.identifier] = [cursor dictionaryRepresentation];
    }
    
    drep[MCCursorDictionaryCursorsKey] = cursors;
    
    return drep;
}

- (void)addCursor:(MCCursor *)cursor {
    if (!cursor)
        return;
    if ([self.cursors containsObject:cursor])
        return;
    
    NSSet *mutation = [NSSet setWithObject:cursor];

    [self willChangeValueForKey:@"cursors" withSetMutation:NSKeyValueUnionSetMutation usingObjects:mutation];

    cursor.parentLibrary = self;
    [self.cursors addObject:cursor];
    
    [self didChangeValueForKey:@"cursors" withSetMutation:NSKeyValueUnionSetMutation usingObjects:mutation];
}

- (void)removeCursor:(MCCursor *)cursor {
    if (![self.cursors containsObject:cursor])
        return;
    
    NSSet *change = [NSSet setWithObject:cursor];
    [self willChangeValueForKey:@"cursors" withSetMutation:NSKeyValueMinusSetMutation usingObjects:change];
    
    cursor.parentLibrary = nil;
    [self.cursors removeObject:cursor];
    
    [self didChangeValueForKey:@"cursors" withSetMutation:NSKeyValueMinusSetMutation usingObjects:change];
}

- (MCCursor *)cursorWithIdentifier:(NSString *)identifier {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSSet *filtered = [self.cursors filteredSetUsingPredicate:predicate];
    if (filtered.count)
        return filtered.anyObject;
    return nil;
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
            [object.cursors isEqualToSet:self.cursors]);
}

- (BOOL)validateIdentifier:(id *)ioValue error:(__autoreleasing NSError **)outError {
    if (self.class.validator && [self.class.validator respondsToSelector:@selector(cursorLibrary:validateIdentifier:error:)]) {
        return [self.class.validator cursorLibrary:self validateIdentifier:ioValue error:outError];
    }
    
    return YES;
}

#pragma mark - Properties

- (BOOL)isHiDPI {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"isHiDPI == YES"];
    NSSet *hi = [self.cursors filteredSetUsingPredicate:pred];
    return hi.count == self.cursors.count && hi.count != 0;
}

@end
