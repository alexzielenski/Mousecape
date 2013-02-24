//
//  MCEditWindowController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCEditListViewController.h"
#import "MCEditCapeViewController.h"
#import "MCEditCursorViewController.h"

@interface MCEditWindowController : NSWindowController <NSSplitViewDelegate>
@property (assign) IBOutlet NSSplitView *splitView;
@property (strong) IBOutlet MCEditListViewController *listViewController;
@property (strong) IBOutlet MCEditCapeViewController *capeViewController;
@property (strong) IBOutlet MCEditCursorViewController *cursorViewController;
@property (copy) MCCursorLibrary *currentLibrary;
@end
