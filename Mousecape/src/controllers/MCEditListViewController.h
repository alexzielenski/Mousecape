//
//  MCEditListViewController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursorLibrary.h"

@interface MCEditListViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
@property (strong) IBOutlet NSTableView *tableView;
@property (copy) MCCursorLibrary *cursorLibrary;
@property (weak) id selectedObject;

- (IBAction)addCursor:(id)sender;
- (IBAction)removeCursor:(id)sender;
- (void)reloadCursor:(MCCursor *)cursor;

- (NSUndoManager *)undoManager;

@end
