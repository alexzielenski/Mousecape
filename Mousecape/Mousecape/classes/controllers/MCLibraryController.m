//
//  MCLibraryController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCLibraryController.h"
#import "NSFileManager+DirectoryLocations.h"
#import "MCCursorLibrary.h"
#import "NSOrderedSet+AZSortedInsert.h"
#import "apply.h"
#import "restore.h"

@interface MCLibraryController ()
@property (nonatomic, retain) NSMutableOrderedSet *capes;
+ (NSString *)capesPath;
+ (NSArray *)sortDescriptors;
- (void)loadLibrary;
@end

@implementation MCLibraryController

+ (NSArray *)sortDescriptors {
    static NSArray *descriptors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        descriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)],
                         [NSSortDescriptor sortDescriptorWithKey:@"author" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] ];
    });
    
    return descriptors;
}

+ (NSString *)capesPath {
    return [[NSFileManager defaultManager] findOrCreateDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appendPathComponent:@"Mousecape/capes" error:NULL];
}

+ (instancetype)sharedLibraryController {
    static MCLibraryController *lb = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lb = [[self alloc] init];
    });
    
    return lb;
}

- (id)init {
    if ((self = [super init])) {
        self.capes = [NSMutableOrderedSet orderedSet];
        [self loadLibrary];
    }
    return self;
}

- (void)loadLibrary {
    NSString *capesPath = self.class.capesPath;
    NSArray  *contents  = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:capesPath error:NULL];
    NSString *applied   = [NSUserDefaults.standardUserDefaults stringForKey:MCPreferencesAppliedCursorKey];
    
    for (NSString *filename in contents) {
        NSURL *fileURL = [NSURL fileURLWithPathComponents:@[ capesPath, filename ]];
        MCCursorLibrary *library = [MCCursorLibrary cursorLibraryWithContentsOfURL:fileURL];
        
        if ([library.identifier isEqualToString:applied]) {
            self.appliedCape = library;
        }
        
        [self addCape:library];
    }
}

- (void)importCapeAtURL:(NSURL *)url {
    MCCursorLibrary *lib = [MCCursorLibrary cursorLibraryWithContentsOfURL:url];
    [self importCape:lib];
}

- (void)importCape:(MCCursorLibrary *)lib {
    lib.fileURL = [NSURL fileURLWithPathComponents:@[ self.class.capesPath, [lib.identifier stringByAppendingPathExtension:@"cape"] ]];
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
    
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:self.capes.count] forKey:@"capes"];
    [self.capes insertObject:cape sortedUsingDescriptors:self.class.sortDescriptors];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:self.capes.count] forKey:@"capes"];
}


- (void)removeCape:(MCCursorLibrary *)cape {
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:self.capes.count - 1] forKey:@"capes"];
    if (cape == self.appliedCape)
        [self restoreCape];
    [self.capes removeObject:cape];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:self.capes.count - 1] forKey:@"capes"];
}

- (void)applyCape:(MCCursorLibrary *)cape {
    if (applyCapeAtPath(cape.fileURL.path))
        self.appliedCape = cape;
}

- (void)restoreCape {
    resetAllCursors();
    self.appliedCape = nil;
}

@end
