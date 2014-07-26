//
//  MCLibraryController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCursorLibrary.h"

@interface MCLibraryController : NSObject
@property (readonly, weak) MCCursorLibrary *appliedCape;
@property (nonatomic, readonly) NSUndoManager *undoManager;
@property (readonly, copy) NSURL *libraryURL;

- (instancetype)initWithURL:(NSURL *)url;

- (void)importCapeAtURL:(NSURL *)url;
- (void)importCape:(MCCursorLibrary *)cape;

- (void)addCape:(MCCursorLibrary *)cape;
- (void)removeCape:(MCCursorLibrary *)cape;

- (void)applyCape:(MCCursorLibrary *)cape;
- (void)restoreCape;

- (NSURL *)URLForCape:(MCCursorLibrary *)cape;

- (NSSet *)capesWithIdentifier:(NSString *)identifier;
- (BOOL)dumpCursorsWithProgressBlock:(BOOL (^)(NSUInteger current, NSUInteger total))block;

@end

@interface MCLibraryController (Capes)
@property (nonatomic, readonly) NSSet *capes;
@end