//
//  MCCursorLibrary.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCCursorLibrary.h"

@interface MCCursorLibrary ()
@property (nonatomic, strong) NSUndoManager *undoManager;
@property (nonatomic, readwrite, strong) NSMutableSet *cursors;
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary;
- (void)addCursorsFromDictionary:(NSDictionary *)cursorDicts ofVersion:(CGFloat)doubleVersion;

- (void)startObservingProperties;
- (void)stopObservingProperties;
+ (NSArray *)undoProperties;
@end

@implementation MCCursorLibrary

+ (NSArray *)undoProperties {
    return @[ @"identifier", @"name", @"author", @"hiDPI", @"version", @"inCloud" ];
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

+ (MCCursorLibrary *)cursorLibraryWithCursors:(NSSet *)cursors {
    return [[MCCursorLibrary alloc] initWithCursors:cursors];
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    return [self initWithContentsOfURL:[NSURL fileURLWithPath:path]];
}

- (instancetype)initWithContentsOfURL:(NSURL *)URL {
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfURL:URL];
    if ((self = [self initWithDictionary:dictionary]))
        self.fileURL = URL;
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if ((self = [self init])) {
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
        self.undoManager = [[NSUndoManager alloc] init];
        self.name = @"Unnamed";
        self.author = NSUserName();
        self.hiDPI = NO;
        self.inCloud = NO;
        self.identifier = [NSString stringWithFormat:@"local.%@.Unnamed.%f", self.author, [NSDate timeIntervalSinceReferenceDate]];
        self.version = @1.0;
        self.cursors = [NSMutableSet set];
        
        [self startObservingProperties];
    }
    
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    MCCursorLibrary *lib = [[MCCursorLibrary allocWithZone:zone] initWithCursors:self.cursors];
    
    [lib.undoManager disableUndoRegistration];
    lib.name             = self.name;
    lib.author           = self.author;
    lib.hiDPI            = self.hiDPI;
    lib.inCloud          = self.inCloud;
    lib.version          = self.version;
    lib.identifier       = [self.identifier stringByAppendingFormat:@".%f", [NSDate timeIntervalSinceReferenceDate]];
    [lib.undoManager enableUndoRegistration];
    
    return lib;
}

- (BOOL)_readFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary || !dictionary.count) {
        NSLog(@"cannot make library from empty dicitonary");
        return NO;
    }
    
    [self.undoManager disableUndoRegistration];
    
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
        [self.undoManager enableUndoRegistration];

        NSLog(@"cannot make library from dictionary with no identifier");
        return NO;
    }
    
    CGFloat doubleVersion = version.doubleValue;
    
    if (minimumVersion.doubleValue > MCCursorParserVersion) {
        [self.undoManager enableUndoRegistration];
        return NO;
    }
    
    [self.cursors removeAllObjects];
    [self addCursorsFromDictionary:cursorDicts ofVersion:doubleVersion];
    
    [self.undoManager enableUndoRegistration];
    return YES;
}

- (void)dealloc {
    [self stopObservingProperties];
}

const char MCCursorLibraryPropertiesContext;
- (void)startObservingProperties {
    for (NSString *key in self.class.undoProperties) {
        [self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionOld context:(void*)&MCCursorLibraryPropertiesContext];
    }
}

- (void)stopObservingProperties {
    for (NSString *key in self.class.undoProperties) {
        [self removeObserver:self forKeyPath:key context:(void *)&MCCursorLibraryPropertiesContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &MCCursorLibraryPropertiesContext) {
        [self.undoManager setActionName:[[@"Change " stringByAppendingString:keyPath] capitalizedString]];
        
        id oldValue = change[NSKeyValueChangeOldKey];
        [[self.undoManager prepareWithInvocationTarget:self] setValue:oldValue forKeyPath:keyPath];
    }
}

- (void)addCursorsFromDictionary:(NSDictionary *)cursorDicts ofVersion:(CGFloat)doubleVersion {
    for (NSString *key in cursorDicts.allKeys) {
        NSDictionary *cursorDictionary = [cursorDicts objectForKey:key];
        MCCursor *cursor = [MCCursor cursorWithDictionary:cursorDictionary ofVersion:doubleVersion];
        cursor.identifier = key;
        [self addCursor: cursor];
    }
}


- (NSSet *)cursorsWithIdentifier:(NSString *)identifier {
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"identififer == %@", identifier];
    return [self.cursors filteredSetUsingPredicate:filter];
}

- (void)addCursor:(MCCursor *)cursor {
    NSSet *change = [NSSet setWithObject:cursor];
    [self willChangeValueForKey:@"cursor" withSetMutation:NSKeyValueUnionSetMutation usingObjects:change];
    [self.cursors addObject:cursor];
    [self didChangeValueForKey:@"cursor" withSetMutation:NSKeyValueUnionSetMutation usingObjects:change];
}

- (void)removeCursor:(MCCursor *)cursor {
    NSSet *change = [NSSet setWithObject:cursor];
    [self willChangeValueForKey:@"cursor" withSetMutation:NSKeyValueMinusSetMutation usingObjects:change];
    [self.cursors removeObject:cursor];
    [self didChangeValueForKey:@"cursor" withSetMutation:NSKeyValueMinusSetMutation usingObjects:change];
}

- (void)removeCursorsWithIdentifier:(NSString *)identifier {
  for (MCCursor *cursor in [self cursorsWithIdentifier:identifier])
      [self removeCursor: cursor];
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

- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)atomically {
    return [self.dictionaryRepresentation writeToFile:file atomically:atomically];
}

- (BOOL)save {
    return [self writeToFile:self.fileURL.path atomically:NO];
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

- (BOOL)isEqual:(id)object {
    return [self isEqualTo:object];
}

@end
