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

@class MCLibraryWindowController;
@interface MCLibraryViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSTableView *tableView;
@property (weak) MCLibraryWindowController *windowController;

- (IBAction)doubleClick:(id)sender;
- (IBAction)contextMenu:(NSMenuItem *)sender;

@end
