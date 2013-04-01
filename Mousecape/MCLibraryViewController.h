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
@property (weak) MCCursorLibrary *appliedLibrary;

// accessory
@property (weak) IBOutlet NSTextField *appliedCursorField;

- (void)loadLibraryAtPath:(NSString *)path;

- (NSError *)addToLibrary:(NSString *)path;
- (NSError *)removeFromLibrary:(MCCursorLibrary *)library;

- (void)addLibrary:(MCCursorLibrary *)library;
- (void)removeLibrary:(MCCursorLibrary *)library;
- (void)removeLibraryAtIndex:(NSUInteger)index;

- (MCCursorLibrary *)libraryWithIdentifier:(NSString *)identifier;

- (IBAction)createSidekick:(id)sender;
- (IBAction)removeCape:(id)sender;
- (IBAction)importMightyMouse:(id)sender;
- (IBAction)importCape:(id)sender;

@end

@interface MCLibraryViewController (Properties)
@property (readonly, strong) NSArray *libraries;
@end

