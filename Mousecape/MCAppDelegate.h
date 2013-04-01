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
#import "MCEditWindowController.h"

@interface MCAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet MCLibraryViewController *libraryController;
@property (assign) IBOutlet MCDetailVewController *detailController;
@property (strong) MCEditWindowController *editWindowController;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTextField *accessory;
@property (strong) NSWindowController *preferencesWindowController;

- (void)composeAccessory;
- (IBAction)showPreferences:(NSMenuItem *)sender;
- (IBAction)editCursor:(id)sender;
- (IBAction)doubleClick:(id)sender;

@end
