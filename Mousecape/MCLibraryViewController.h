//
//  MCLibraryViewController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursorDocument.h"
#import "MCLibraryViewController.h"
#import "MCDetailVewController.h"

@class MCLibraryWindowController;
@interface MCLibraryViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) MCLibraryWindowController *windowController;

// accessory
@property (weak) IBOutlet NSTextField *appliedCursorField;

- (void)loadLibraryAtPath:(NSString *)path;

- (NSError *)addToLibrary:(NSString *)path;
- (NSError *)removeFromLibrary:(MCCursorDocument *)library;

- (void)addLibrary:(MCCursorDocument *)library;
- (void)removeLibrary:(MCCursorDocument *)library;

- (MCCursorDocument *)libraryWithIdentifier:(NSString *)identifier;

- (IBAction)createSidekick:(id)sender;
- (IBAction)removeCape:(id)sender;
- (IBAction)importMightyMouse:(id)sender;
- (IBAction)importCape:(id)sender;
- (IBAction)doubleClick:(id)sender;

@end
