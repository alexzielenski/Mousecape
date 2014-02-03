//
//  MCLbraryWindowController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCLibraryViewController.h"

@interface MCLibraryWindowController : NSWindowController
@property (assign) IBOutlet MCLibraryViewController *libraryViewController;
@property (assign) IBOutlet NSView *appliedAccessory;
@end

@interface MCAppliedCapeValueTransformer : NSValueTransformer
@end