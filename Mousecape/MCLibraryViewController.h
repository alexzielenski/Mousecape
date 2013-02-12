//
//  MCLibraryViewController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MCCursorLibrary;
@interface MCLibraryViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) MCCursorLibrary *selectedLibrary;

- (void)loadLibraryAtPath:(NSString *)path;

- (NSError *)addToLibrary:(NSString *)path;

- (void)addLibrary:(MCCursorLibrary *)library;
- (void)insertLibrary:(MCCursorLibrary *)library atIndex:(NSUInteger)index;
- (void)removeLibrary:(MCCursorLibrary *)library;
- (void)removeLibraryAtIndex:(NSUInteger)index;

@end

@interface MCLibraryViewController (Properties)
@property (readonly, strong) NSArray *libraries;
@end

