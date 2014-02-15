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
@property (weak) MCCursorLibrary *editingCape;
@property (weak) MCCursorLibrary *selectedCape;
@property (weak) MCCursorLibrary *clickedCape;

- (void)editCape:(MCCursorLibrary *)library;
@end

@interface MCLibraryController (Properties)
@property (readonly, strong) NSOrderedSet *capes;
@end
