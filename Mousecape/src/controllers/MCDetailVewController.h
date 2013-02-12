//
//  MCDetailVewController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/11/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursorLibrary.h"

@interface MCDetailVewController : NSViewController
@property (assign) IBOutlet NSTextField *titleLabel;
@property (assign) IBOutlet NSTextField *authorLabel;
@property (assign) IBOutlet NSTextField *versionLabel;
@property (assign) IBOutlet NSButton *applyButton;
@property (assign) IBOutlet NSButton *updateButton;
@property (strong) MCCursorLibrary *currentLibrary;

- (IBAction)apply:(NSButton *)sender;
- (IBAction)update:(NSButton *)sender;

@end
