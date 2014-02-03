//
//  MCLibraryController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCursorLibrary.h"

@class MCLibraryController;
@protocol MCLibraryDelegate <NSObject>

@optional
- (BOOL)libraryController:(MCLibraryController *)controller shouldAddCape:(MCCursorLibrary *)library;
- (BOOL)libraryController:(MCLibraryController *)controller shouldRemoveCape:(MCCursorLibrary *)library;

- (void)libraryController:(MCLibraryController *)controller didAddCape:(MCCursorLibrary *)library;
- (void)libraryController:(MCLibraryController *)controller didRemoveCape:(MCCursorLibrary *)library;

@end

@interface MCLibraryController : NSObject
@property (readonly, weak) MCCursorLibrary *appliedCape;
@property (weak) id <MCLibraryDelegate> delegate;
@property (readonly, copy) NSURL *libraryURL;

- (instancetype)initWithURL:(NSURL *)url;

- (void)importCapeAtURL:(NSURL *)url;
- (void)importCape:(MCCursorLibrary *)cape;

- (void)addCape:(MCCursorLibrary *)cape;
- (void)removeCape:(MCCursorLibrary *)cape;

- (void)applyCape:(MCCursorLibrary *)cape;
- (void)restoreCape;

- (NSURL *)URLForCape:(MCCursorLibrary *)cape;

@end

@interface MCLibraryController (Capes)
@property (nonatomic, readonly) NSOrderedSet *capes;
@end