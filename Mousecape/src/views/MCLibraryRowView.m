//
//  MCLibraryRowView.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCLibraryRowView.h"

static NSGradient *backgroundGradient;
static NSColor *separatorColor;

@implementation MCLibraryRowView

+ (void)initialize {
    backgroundGradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.90f green:0.90f blue:0.93f alpha:1.0f]
                                                       endingColor:[NSColor colorWithCalibratedRed:0.85f green:0.87f blue:0.90f alpha:1.0f]];
    separatorColor = [NSColor colorWithCalibratedRed:0.74f green:0.75f blue:0.74f alpha:1.0f];
}

- (NSTableViewSelectionHighlightStyle)selectionHighlightStyle {
    return NSTableViewSelectionHighlightStyleSourceList;
}

- (void)drawBackgroundInRect:(NSRect)dirtyRect {
    [backgroundGradient drawInRect:self.bounds angle:90];
    [self drawSeparatorInRect:dirtyRect];
}

- (void)drawSeparatorInRect:(NSRect)dirtyRect {
    [separatorColor set];
    NSRectFill(NSMakeRect(0, self.bounds.size.height - 1.0, self.bounds.size.width, 1.0));
    
    if (self.groupRowStyle)
        NSRectFill(NSMakeRect(0, 0.0, self.bounds.size.width, 1.0));

}

@end
