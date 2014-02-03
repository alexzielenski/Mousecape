//
//  MCAppDelegate.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCLibraryWindowController.h"
@interface MCAppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSMenuItem *toggleHelperItem;
@property (strong) MCLibraryWindowController *libraryWindowController;
- (IBAction)toggleInstall:(NSMenuItem *)sender;

- (IBAction)applyCape:(id)sender;
- (IBAction)editCape:(id)sender;
- (IBAction)removeCape:(id)sender;
- (IBAction)checkCape:(id)sender;
- (IBAction)restoreCape:(id)sender;
- (IBAction)convertCape:(id)sender;

- (IBAction)newCape:(id)sender;
- (IBAction)importCape:(id)sender;
- (IBAction)duplicateCape:(id)sender;

@end
