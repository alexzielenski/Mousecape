//
//  MCCursorDocument.h
//  Mousecape
//
//  Created by Alex Zielenski on 6/25/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MCCursorLibrary.h"

@interface MCCursorDocument : NSDocument
@property (strong) MCCursorLibrary *library;
@property (strong) NSWindowController *editWindowController;
@property (assign) BOOL shouldVaryCursorSize;

- (IBAction)apply:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)edit:(id)sender;

@end
