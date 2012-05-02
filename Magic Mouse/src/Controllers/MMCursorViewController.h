//
//  MMCursorViewController.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 5/1/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMAnimatingImageTableCellView.h"
#import "MMCursorAggregate.h"

@interface MMCursorViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource, MMAnimatingImageViewDelegate>

@property (nonatomic, retain) MMCursorAggregate *cursor;
@property (nonatomic, assign) IBOutlet NSTableView *tableView;
@property (nonatomic, assign, getter = isEnabled) BOOL enabled;

@end
