//
//  MCEditDetailController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursor.h"

@interface MCEditDetailController : NSViewController
@property (strong) MCCursor *cursor;
@property (assign) IBOutlet NSPopUpButton *typePopUpButton;
@end

@interface MCCursorTypeValueTransformer : NSValueTransformer
@end