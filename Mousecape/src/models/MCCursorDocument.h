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
@property (nonatomic, strong) MCCursorLibrary *library;
@property (nonatomic, strong) NSWindowController *editWindowController;
@property (nonatomic, assign) BOOL shouldVaryCursorSize;

- (IBAction)apply:(id)sender;
- (IBAction)remove:(id)sender;
- (IBAction)edit:(id)sender;

@end
