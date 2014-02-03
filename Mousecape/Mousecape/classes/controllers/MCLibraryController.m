//
//  MCLibraryController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCLibraryController.h"
#import "MCCursorLibrary.h"
#import "NSOrderedSet+AZSortedInsert.h"
#import "apply.h"
#import "restore.h"

@interface MCLibraryController ()
@property (nonatomic, retain) NSMutableOrderedSet *capes;
@property (readwrite, copy) NSURL *libraryURL;
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

- (NSURL *)URLForCape:(MCCursorLibrary *)cape {
    return [NSURL fileURLWithPathComponents:@[ self.libraryURL.path, [cape.identifier stringByAppendingPathExtension:@"cape"] ]];
}

- (instancetype)initWithURL:(NSURL *)url {
    if ((self = [self init])) {
        self.libraryURL = url;
        [self loadLibrary];
    }
    
    return self;
}

- (void)loadLibrary {
    self.capes = [NSMutableOrderedSet orderedSet];
    NSString *capesPath = self.libraryURL.path;
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
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(libraryController:shouldAddCape:)] && ![self.delegate libraryController:self shouldAddCape:cape])
        return;
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:self.capes.count] forKey:@"capes"];
    [self.capes insertObject:cape sortedUsingDescriptors:self.class.sortDescriptors];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:self.capes.count] forKey:@"capes"];
    if (self.delegate && [self.delegate respondsToSelector:@selector(libraryController:didAddCape:)])
        [self.delegate libraryController:self didAddCape:cape];
        
}


- (void)removeCape:(MCCursorLibrary *)cape {
    if (self.delegate && [self.delegate respondsToSelector:@selector(libraryController:shouldRemoveCape:)] && ![self.delegate libraryController:self shouldRemoveCape:cape])
        return;
    
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:self.capes.count - 1] forKey:@"capes"];
    if (cape == self.appliedCape)
        [self restoreCape];
    [self.capes removeObject:cape];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:self.capes.count - 1] forKey:@"capes"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(libraryController:didRemoveCape:)])
        [self.delegate libraryController:self didRemoveCape:cape];
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
