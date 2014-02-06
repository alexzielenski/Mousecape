//
//  MCEditWindowController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCEditDetailController.h"
#import "MCEditListController.h"
#import "MCEditCapeController.h"
#import "MCCursorLibrary.h"

@interface MCEditWindowController : NSWindowController <NSWindowDelegate, NSSplitViewDelegate>
@property (assign) IBOutlet MCEditListController *editListController;     // List of cursors in the library
@property (assign) IBOutlet MCEditDetailController *editDetailController; // Detail view of the selected cursor
@property (assign) IBOutlet MCEditCapeController *editCapeController;     // Detail view of the entire library
@property (assign) IBOutlet NSView *detailView;
@property (assign) MCCursorLibrary *cursorLibrary;
@end
