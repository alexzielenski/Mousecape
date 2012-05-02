//
//  MMAdvancedEditWindowController.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 5/2/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMCursorAggregate.h"

@interface MMAdvancedEditWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, retain) MMCursorAggregate *cursor;
@property (nonatomic, assign) NSWindow *parentWindow;

- (void)displayForWindow:(NSWindow *)window cursor:(MMCursorAggregate *)cursor;;

@end
