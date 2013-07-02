//
//  MCAppDelegate.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCLibraryWindowController.h"

@interface MCAppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSWindow *window;
@property (strong) NSWindowController *preferencesWindowController;
@property (strong) MCLibraryWindowController *libraryWindowController;
@property (assign) IBOutlet NSMenu *fileMenu;

- (void)setUpEnvironment;
- (IBAction)showPreferences:(NSMenuItem *)sender;

@end
