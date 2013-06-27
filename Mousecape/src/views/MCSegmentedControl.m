//
//  MCSegmentedControl.m
//  Mousecape
//
//  Created by Alex Zielenski on 6/27/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCSegmentedControl.h"
#import "NSBezierPath+PXRoundedRectangleAdditions.h"
#import "NSBezierPath+StrokeExtensions.h"

@implementation MCSegmentedControl
+ (Class)cellClass {
    return MCSegmentedCell.class;
}
@end

@implementation MCSegmentedCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    CGFloat cornerRadius = 10;
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:cellFrame cornerRadius:cornerRadius inCorners:OSTopRightCorner];

    [gColorNormal set];
    [path fill];
    
    [gInnerStroke setStroke];
    [path setLineWidth:2.0];
    [path strokeInside];
    
    [gOuterStroke setStroke];
    [path setLineWidth:1.0];
    [path strokeInside];
    
    [path setClip];
    
    CGFloat currentX = 0.0;
    for (NSUInteger x = 0; x < self.segmentCount; x++) {
        if (x > 0 && self.selectedSegment != x - 1) {
            [gOuterStroke set];
            NSRectFillUsingOperation(NSMakeRect(currentX, 0, 1.0, cellFrame.size.height), NSCompositeSourceOver);
        }
        
        NSRect segmentRect = NSMakeRect(currentX, 0, [self widthForSegment:x], cellFrame.size.height);
        
        if (x == self.selectedSegment) {
            if (x == self.segmentCount - 1)
                segmentRect.size.width += 5;
            
            [[NSColor alternateSelectedControlColor] setFill];
            segmentRect.size.width += 1;
            NSRectFillUsingOperation(segmentRect, NSCompositeSourceOver);
            segmentRect.size.width -= 1;
        }
        
        if (x == self.segmentCount - 1)
            segmentRect.size.width -= 5;
        
        [self drawSegment:x inFrame:segmentRect withView:controlView];
        currentX += segmentRect.size.width;
    }
}

- (NSBackgroundStyle)interiorBackgroundStyleForSegment:(NSInteger)segment {
    return (segment == self.selectedSegment) ? NSBackgroundStyleLowered : NSBackgroundStyleRaised;
}

@end