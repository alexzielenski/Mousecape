//
//  MCEditWindowController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCEditWindowController.h"

@interface MCEditWindowController ()

@end

@implementation MCEditWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    
    [self.window makeKeyAndOrderFront:self];
}

#pragma mark - NSSplitViewDelegate
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
    if (offset == 0)
        return proposedMin + 60.0;
    return proposedMin + 420.0;
}

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
    if (offset == 0)
        return proposedMax - 480.0;
    return proposedMax;
}
- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return YES;
}
@end
