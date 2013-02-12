//
//  MCAppDelegate.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCLibraryViewController.h"
#import "MCDetailVewController.h"

@interface MCAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet MCLibraryViewController *libraryController;
@property (assign) IBOutlet MCDetailVewController *detailController;
@property (assign) IBOutlet NSWindow *window;

@end
