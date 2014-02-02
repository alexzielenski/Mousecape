//
//  MCLibraryViewController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCLibraryController.h"

@interface MCLibraryViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
@property (assign) IBOutlet NSTableView *tableView;
@end
