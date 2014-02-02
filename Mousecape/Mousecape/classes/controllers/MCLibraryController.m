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
#import "apply.h"

@interface MCLibraryController ()
@property (nonatomic, retain) NSMutableOrderedSet *capes;
+ (NSString *)capesPath;
- (void)loadLibrary;
@end

@implementation MCLibraryController

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

- (void)importCursorLibraryAtURL:(NSURL *)url {
    MCCursorLibrary *lib = [MCCursorLibrary cursorLibraryWithContentsOfURL:url];
    lib.fileURL = [NSURL fileURLWithPathComponents:@[ self.class.capesPath, [lib.identifier stringByAppendingPathExtension:@"cape"] ]];
    [lib writeToFile:lib.fileURL.path atomically:NO];
    
    [self addCape:lib];
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

- (void)applyCape:(MCCursorLibrary *)cape {
    if (applyCapeAtPath(cape.fileURL.path))
        self.appliedCape = cape;
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
        
    [self willChangeValueForKey:@"capes"];
    [self.capes addObject:cape];
    [self didChangeValueForKey:@"capes"];
}


- (void)removeCape:(MCCursorLibrary *)cape {
    [self willChangeValueForKey:@"capes"];
    [self.capes removeObject:cape];
    [self didChangeValueForKey:@"capes"];
}


@end
