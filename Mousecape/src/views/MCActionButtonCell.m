//
//  MCActionButtonCell.m
//  Mousecape
//
//  Created by Alex Zielenski on 6/25/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCActionButtonCell.h"

@implementation MCActionButton

+ (Class)cellClass {
    return [MCActionButtonCell class];
}

- (void)viewDidMoveToWindow {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
    [center removeObserver:self name:NSWindowDidResignKeyNotification object:nil];

    
    @weakify(self);
    void (^observerBlock)(NSNotification *note) = ^(NSNotification *note) {
        @strongify(self);
        [self setNeedsDisplay:YES];
    };
    [center addObserverForName:NSWindowDidBecomeKeyNotification object:self.window queue:nil usingBlock:observerBlock];
    [center addObserverForName:NSWindowDidResignKeyNotification object:self.window queue:nil usingBlock:observerBlock];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
}

@end

@implementation MCActionButtonCell

- (void)drawBezelWithFrame:(NSRect)frame inView:(NSView *)controlView {
    [super drawBezelWithFrame:frame inView:controlView];
    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    [ctx saveGraphicsState];
    
    // Gradient
    
    static NSGradient *gradient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:(238. / 255.) alpha:1.0]
                                                 endingColor:[NSColor colorWithCalibratedWhite:(222. / 255.) alpha:1.0]];
    });
    
    [gradient drawInRect:frame angle:self.isHighlighted ? -90 : 90];
    
    // Top
    [[NSColor whiteColor] set];
    NSRectFill(NSMakeRect(0, 0, frame.size.width, 1.0));
    NSRectFill(NSMakeRect(0, 2, frame.size.width, 1.0));
    
    [[NSColor colorWithCalibratedWhite:0.6 alpha:1.0] set];
    NSRectFill(NSMakeRect(0, 1, frame.size.width, 1.0));
    
    if (!controlView.window.isKeyWindow || !self.isEnabled) {
        [[[NSColor whiteColor] colorWithAlphaComponent: !self.isEnabled ? 0.6 : 0.4] set];
        NSRectFillUsingOperation(NSMakeRect(0, 3, frame.size.width, frame.size.height - 3.0), NSCompositeSourceOver);
        
    }
        
    
    [ctx restoreGraphicsState];
}

@end
