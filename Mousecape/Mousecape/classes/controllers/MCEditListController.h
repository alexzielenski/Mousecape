//
//  MCEditListController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursorLibrary.h"
@interface MCEditListController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
@property (strong) MCCursorLibrary *cursorLibrary;
@property (weak) id selectedObject;
@end
