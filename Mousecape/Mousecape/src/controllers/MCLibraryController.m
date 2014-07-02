//
//  MCLibraryController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCLibraryController.h"
#import "NSOrderedSet+AZSortedInsert.h"
#import "apply.h"
#import "restore.h"

const char MCLibraryIdentifierContext;

@interface MCLibraryController ()
@property (nonatomic, readwrite, strong) NSUndoManager *undoManager;
@property (nonatomic, retain) NSMutableSet *capes;
@property (readwrite, copy) NSURL *libraryURL;
@property (readwrite, weak) MCCursorLibrary *appliedCape;
- (void)loadLibrary;
@end

@implementation MCLibraryController

- (NSURL *)URLForCape:(MCCursorLibrary *)cape {
    return [NSURL fileURLWithPathComponents:@[ self.libraryURL.path, [cape.identifier stringByAppendingPathExtension:@"cape"] ]];
}

- (instancetype)initWithURL:(NSURL *)url {
    if ((self = [self init])) {
        self.libraryURL = url;
        self.undoManager = [[NSUndoManager alloc] init];
        [self loadLibrary];
    }
    
    return self;
}

- (void)loadLibrary {
    [self.undoManager disableUndoRegistration];
    
    self.capes = [NSMutableSet set];
    NSString *capesPath = self.libraryURL.path;
    NSArray  *contents  = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:capesPath error:NULL];
    NSString *applied   = [NSUserDefaults.standardUserDefaults stringForKey:MCPreferencesAppliedCursorKey];

    for (NSString *filename in contents) {
        // Ignore hidden files like .DS_Store
        if ([filename hasPrefix:@"."])
            continue;

        NSURL *fileURL = [NSURL fileURLWithPathComponents:@[ capesPath, filename ]];
        MCCursorLibrary *library = [MCCursorLibrary cursorLibraryWithContentsOfURL:fileURL];
        
        if ([library.identifier isEqualToString:applied]) {
            self.appliedCape = library;
        }
        
        [self addCape:library];
    }
    
    [self.undoManager enableUndoRegistration];
}

- (void)importCapeAtURL:(NSURL *)url {
    MCCursorLibrary *lib = [MCCursorLibrary cursorLibraryWithContentsOfURL:url];
    NSURL *destinationURL = [self URLForCape:lib];
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtURL:lib.fileURL toURL:destinationURL error:&error];
    if (!error) {
        lib.fileURL = destinationURL;
        [self addCape:lib];
    }    
}

- (void)importCape:(MCCursorLibrary *)lib {
    lib.fileURL = [self URLForCape:lib];
    [lib writeToFile:lib.fileURL.path atomically:NO];
    
    [self addCape:lib];
}


- (void)addCape:(MCCursorLibrary *)cape {
    if ([self.capes containsObject:cape]) {
        NSLog(@"Not adding %@ to the library because an object with that identifier already exists", cape.identifier);
        return;
    }
        
    if (!cape) {
        NSLog(@"Cannot add nil cape");
        return;
    }

    NSSet *change = [NSSet setWithObject:cape];
    [self willChangeValueForKey:@"capes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:change];
    
    [cape addObserver:self forKeyPath:@"identifier" options:NSKeyValueObservingOptionOld context:(void *)&MCLibraryIdentifierContext];
    
    cape.library = self;
    [self.capes addObject:cape];
    
    [[self.undoManager prepareWithInvocationTarget:self] removeCape:cape];
    if (!self.undoManager.isUndoing) {
        [self.undoManager setActionName:[@"Add " stringByAppendingString:cape.name]];
    }
    
    [self didChangeValueForKey:@"capes" withSetMutation:NSKeyValueUnionSetMutation usingObjects:change];
}


- (void)removeCape:(MCCursorLibrary *)cape {
    NSSet *change = [NSSet setWithObject:cape];
    
    [self willChangeValueForKey:@"capes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:change];
    if (cape == self.appliedCape)
        [self restoreCape];
    
    [cape removeObserver:self forKeyPath:@"identifier" context:(void *)&MCLibraryIdentifierContext];
    
    if (cape.library == self)
        cape.library = nil;
    
    [self.capes removeObject:cape];
    
    // Move the file to the trash
    NSFileManager *manager = [NSFileManager defaultManager];
    NSURL *destinationURL = [NSURL fileURLWithPath:[[@"~/.Trash" stringByExpandingTildeInPath] stringByAppendingPathComponent:cape.fileURL.lastPathComponent] isDirectory:NO];
    
    [manager removeItemAtURL:destinationURL error:NULL];
    [manager moveItemAtURL:cape.fileURL toURL:destinationURL error:NULL];

    [[self.undoManager prepareWithInvocationTarget:self] importCapeAtURL:destinationURL];
    if (!self.undoManager.isUndoing) {
        [self.undoManager setActionName:[@"Remove " stringByAppendingString:cape.name]];
    }
    
    [self didChangeValueForKey:@"capes" withSetMutation:NSKeyValueMinusSetMutation usingObjects:change];
}

- (void)applyCape:(MCCursorLibrary *)cape {
    if (applyCapeAtPath(cape.fileURL.path)) {
        self.appliedCape = cape;
    }
}

- (void)restoreCape {
    resetAllCursors();
    self.appliedCape = nil;
}

- (NSSet *)capesWithIdentifier:(NSString *)identifier {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    return [self.capes filteredSetUsingPredicate:pred];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &MCLibraryIdentifierContext) {
        // change the file url to reflect the new identifier
        MCCursorLibrary *cape = object;
        NSURL *oldURL = cape.fileURL;
        [cape setFileURL:[self URLForCape:cape]];
        
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtURL:oldURL toURL:cape.fileURL error:&error];
        if (error) {
            NSLog(@"Failed to rename the identifier of the cape %@. Reverting to %@...", cape.identifier, change[NSKeyValueChangeOldKey]);
            cape.identifier = change[NSKeyValueChangeOldKey];
            cape.fileURL = [self URLForCape:cape];
        }
    }
}

@end
