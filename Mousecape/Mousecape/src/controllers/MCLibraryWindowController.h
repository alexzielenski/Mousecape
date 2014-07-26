//
//  MCLbraryWindowController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCLibraryViewController.h"

@interface MCLibraryWindowController : NSWindowController <NSWindowDelegate>
@property (weak) IBOutlet MCLibraryViewController *libraryViewController;
@property (weak) IBOutlet NSView *appliedAccessory;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *progressField;
@end

@interface MCAppliedCapeValueTransformer : NSValueTransformer
@end