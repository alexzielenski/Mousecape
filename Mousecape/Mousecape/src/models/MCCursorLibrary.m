//
//  MCCursorLibrary.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCCursorLibrary.h"

NSString *const MCLibraryWillSaveNotificationName = @"MCLibraryWillSave";
NSString *const MCLibraryDidSaveNotificationName = @"MCLibraryDidSave";

@interface MCCursorLibrary ()
@property (nonatomic, strong) NSUndoManager *undoManager;
@property (nonatomic, readwrite, strong) NSMutableSet *cursors;
@property (nonatomic, assign) NSUInteger changeCount;
@property (nonatomic, assign) NSUInteger lastChangeCount;
@property (nonatomic, strong) NSArray *observers;
@property (nonatomic, copy) NSString *oldIdentifier;

- (BOOL)_readFromDictionary:(NSDictionary *)dictionary;
- (void)addCursorsFromDictionary:(NSDictionary *)cursorDicts ofVersion:(CGFloat)doubleVersion;

- (void)startObservingProperties;
- (void)stopObservingProperties;

- (void)startObservingCursor:(MCCursor *)cursor;
- (void)stopObservingCursor:(MCCursor *)cursor;

+ (NSArray *)cursorUndoProperties;
+ (NSArray *)undoProperties;
@end

@implementation MCCursorLibrary
@dynamic dirty;

+ (NSArray *)undoProperties {
    return @[ @"identifier", @"name", @"author", @"hiDPI", @"version", @"inCloud" ];
}

+ (NSArray *)cursorUndoProperties {
    return @[ @"identifier", @"frameDuration", @"frameCount", @"size", @"hotSpot", @"cursorRep100", @"cursorRep200", @"cursorRep500", @"cursorRep1000" ];
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
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        __weak typeof(self) weakSelf = self;
        id ob1 = [center addObserverForName:NSUndoManagerDidCloseUndoGroupNotification object:self.undoManager queue:nil usingBlock:^(NSNotification *note) {
            [weakSelf updateChangeCount:NSChangeDone];
        }];
        
        id ob2 = [center addObserverForName:NSUndoManagerDidUndoChangeNotification object:self.undoManager queue:nil usingBlock:^(NSNotification *note) {
            [weakSelf updateChangeCount:NSChangeUndone];
        }];
        
        id ob3 = [center addObserverForName:NSUndoManagerDidRedoChangeNotification object:self.undoManager queue:nil usingBlock:^(NSNotification *note) {
            [weakSelf updateChangeCount:NSChangeRedone];
        }];
        
        self.observers = @[ob1, ob2, ob3];
        
        self.name = @"Unnamed";
        self.author = NSUserName();
        self.hiDPI = NO;
        self.inCloud = NO;
        self.identifier = [NSString stringWithFormat:@"local.%@.Unnamed.%f", self.author, [NSDate timeIntervalSinceReferenceDate]];
        self.version = @1.0;
        self.cursors = [NSMutableSet set];
        self.changeCount = 0;
        self.lastChangeCount = 0;
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

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"dirty"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray: @[@"changeCount", @"lastChangeCount"]];
    }
    return keyPaths;
}

- (BOOL)_readFromDictionary:(NSDictionary *)dictionary {
    if (!dictionary || !dictionary.count) {
        NSLog(@"cannot make library from empty dicitonary");
        return NO;
    }
    for (MCCursor *cursor in self.cursors) {
        [self stopObservingCursor:cursor];
    }
    
    self.cursors = [NSMutableSet set];
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
    for (MCCursor *cursor in self.cursors) {
        [self stopObservingCursor:cursor];
    }
    
    for (id observer in self.observers) {
        [NSNotificationCenter.defaultCenter removeObserver:observer];
    }
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

const char MCCursorPropertiesContext;
- (void)startObservingCursor:(MCCursor *)cursor {
    for (NSString *key in self.class.cursorUndoProperties) {
        [cursor addObserver:self forKeyPath:key options:NSKeyValueObservingOptionOld context:(void *)&MCCursorPropertiesContext];
    }
}

- (void)stopObservingCursor:(MCCursor *)cursor {
    for (NSString *key in self.class.cursorUndoProperties) {
        [cursor removeObserver:self forKeyPath:key context:(void *)&MCCursorPropertiesContext];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &MCCursorLibraryPropertiesContext || context == &MCCursorPropertiesContext) {
        NSString *decamelized = [keyPath stringByReplacingOccurrencesOfString:@"([a-z])([A-Z])"
                                                                   withString:@"$1 $2"
                                                                      options:NSRegularExpressionSearch
                                                                        range:NSMakeRange(0, keyPath.length)];
        
        id oldValue = change[NSKeyValueChangeOldKey];
        if ([oldValue isKindOfClass:[NSNull class]])
            oldValue = nil;
        
        [[self.undoManager prepareWithInvocationTarget: object] setValue:oldValue forKeyPath:keyPath];
        
        if (!self.undoManager.isUndoing) {
            [self.undoManager setActionName:[[@"Change " stringByAppendingString:decamelized] capitalizedString]];
        }

        if ([keyPath isEqualToString:@"identifier"]) {
            self.oldIdentifier = oldValue;
        }
    }
}

- (void)addCursorsFromDictionary:(NSDictionary *)cursorDicts ofVersion:(CGFloat)doubleVersion {
    for (NSString *key in cursorDicts.allKeys) {
        NSDictionary *cursorDictionary = [cursorDicts objectForKey:key];
        MCCursor *cursor = [MCCursor cursorWithDictionary:cursorDictionary ofVersion:doubleVersion];
        if (!cursor)
            continue;
        cursor.identifier = key;
        [self addCursor: cursor];
    }
}

- (NSSet *)cursorsWithIdentifier:(NSString *)identifier {
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    return [self.cursors filteredSetUsingPredicate:filter];
}

- (void)addCursor:(MCCursor *)cursor {
    if ([self.cursors containsObject:cursor]) {
        // Don't unnecessarily add a cursor/register observers with it because the
        // observation info will leak when it gets dereferenced since we don't do it here
        // since NSSet just silently skips items it already has
        return;
    }
    
    NSSet *change = [NSSet setWithObject:cursor];
    
    [[self.undoManager prepareWithInvocationTarget:self] removeCursor:cursor];
    if (!self.undoManager.isUndoing) {
        [self.undoManager setActionName:@"Add Cursor"];
    }
    
    [self willChangeValueForKey:@"cursors" withSetMutation:NSKeyValueUnionSetMutation usingObjects:change];
    [self.cursors addObject:cursor];
    [self startObservingCursor:cursor];
    [self didChangeValueForKey:@"cursors" withSetMutation:NSKeyValueUnionSetMutation usingObjects:change];
}

- (void)removeCursor:(MCCursor *)cursor {
    NSSet *change = [NSSet setWithObject:cursor];
    
    [[self.undoManager prepareWithInvocationTarget:self] addCursor:cursor];
    if (!self.undoManager.isUndoing) {
        [self.undoManager setActionName:@"Remove Cursor"];
    }
    
    [self willChangeValueForKey:@"cursors" withSetMutation:NSKeyValueMinusSetMutation usingObjects:change];
    [self.cursors removeObject:cursor];
    [self stopObservingCursor:cursor];
    [self didChangeValueForKey:@"cursors" withSetMutation:NSKeyValueMinusSetMutation usingObjects:change];
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

- (NSError *)save {
    // Check for duplicate capes
    NSCountedSet *count  = [[NSCountedSet alloc] initWithArray:[self.cursors.allObjects valueForKey:@"identifier"]];
    NSMutableSet *duplicates = [NSMutableSet set];
    
    for (NSString *identifier in count) {
        if ([duplicates containsObject:identifier])
            continue;
        
        NSUInteger amount = [count countForObject:identifier];
        if (amount > 1)
            [duplicates addObject:nameForCursorIdentifier(identifier)];
    }
        
    if (duplicates.count > 0) {
        return [NSError errorWithDomain:MCErrorDomain code:MCErrorMultipleCursorIdentifiersCode userInfo:@{
                                                                                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Save failed", nil),
                                                                                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat:NSLocalizedString(@"Multiple cursors with the name(s): %@ exist.", nil), duplicates] }];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:MCLibraryWillSaveNotificationName object:self];

    BOOL success = [self writeToFile:self.fileURL.path atomically:NO];
    if (success) {
        [self updateChangeCount:NSChangeCleared];
        [[NSNotificationCenter defaultCenter] postNotificationName:MCLibraryDidSaveNotificationName object:self];
        return nil;
    }
    return [NSError errorWithDomain:MCErrorDomain code:MCErrorWriteFailCode userInfo:@{
                                                                                       NSLocalizedDescriptionKey: NSLocalizedString(@"Save failed", nil),
                                                                                       NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Error writing cape to disk.", nil) }];
}

- (void)updateChangeCount:(NSDocumentChangeType)change {
    if (change == NSChangeDone || change == NSChangeRedone) {
        self.changeCount = self.changeCount + 1;
    } else if (change == NSChangeUndone && self.changeCount > 0) {
        self.changeCount = self.changeCount - 1;
    } else if (change == NSChangeCleared || change == NSChangeAutosaved) {
        self.lastChangeCount = self.changeCount;
    }
}

- (void)revertToSaved {
    while (self.isDirty) {
        [self.undoManager undo];
    }
    
    [self updateChangeCount:NSChangeCleared];
    [self.undoManager removeAllActions];
}

- (BOOL)isDirty {
    return (self.changeCount != self.lastChangeCount);
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
