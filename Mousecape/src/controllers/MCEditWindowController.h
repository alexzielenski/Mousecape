//
//  MCEditWindowController.h
//  Mousecape
//
//  Created by Alex Zielenski on 6/25/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCEditListViewController.h"
#import "MCEditCapeViewController.h"
#import "MCEditCursorViewController.h"

@interface MCEditWindowController : NSWindowController <NSWindowDelegate>
@property (weak) NSWindow *parentWindow;
@property (weak) IBOutlet NSSplitView *splitView;
@property (weak) IBOutlet MCEditListViewController *listViewController;
@property (weak) IBOutlet MCEditCapeViewController *capeViewController;
@property (weak) IBOutlet MCEditCursorViewController *cursorViewController;
@end
