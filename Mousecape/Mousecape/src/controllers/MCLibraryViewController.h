//
//  MCLibraryViewController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCLibraryController.h"

@interface MCLibraryViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
@property (assign) IBOutlet NSMenu *contextMenu;
@property (assign) IBOutlet NSTableView *tableView;
@property (strong, readonly) MCLibraryController *libraryController;

- (MCCursorLibrary *)selectedCape;
- (MCCursorLibrary *)clickedCape;

- (void)editCape:(MCCursorLibrary *)library;

- (IBAction)applyAction:(NSMenuItem *)sender;
- (IBAction)editAction:(NSMenuItem *)sender;
- (IBAction)duplicateAction:(NSMenuItem *)sender;
- (IBAction)removeAction:(NSMenuItem *)sender;
@end

@interface MCLibraryController (Properties)
@property (readonly, strong) NSOrderedSet *capes;
@end
