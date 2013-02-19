//
//  MCEditWindowController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MCEditWindowController : NSWindowController <NSSplitViewDelegate>
@property (assign) IBOutlet NSSplitView *splitView;
@end
