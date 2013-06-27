//
//  MCTableCellView.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/10/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursorLine.h"
#import "MCCursorDocument.h"

@interface MCTableCellView : NSTableCellView <MCCursorLineDataSource>
@property (strong) IBOutlet MCCursorLine *cursorLine;
@property (strong) IBOutlet NSImageView *appliedView;
@property (strong) IBOutlet NSImageView *hdView;
@property (assign, getter = isApplied) BOOL applied;
@property (weak) RACDisposable *appliedDisposable;

- (MCCursorDocument *)objectValue;

@end
