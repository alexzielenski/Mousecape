//
//  MCTableCellView.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/10/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursorLine.h"

@interface MCTableCellView : NSTableCellView <MCCursorLineDataSource>
@property (strong) IBOutlet MCCursorLine *cursorLine;
@property (strong) IBOutlet NSImageView *appliedView;
@property (assign, getter = isApplied) BOOL applied;
@end
