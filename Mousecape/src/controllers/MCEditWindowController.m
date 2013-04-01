//
//  MCEditWindowController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCEditWindowController.h"

@interface MCEditWindowController ()
@property (weak) NSViewController *currentEditViewController;
- (void)_changeEditViewsForSelection;
- (void)_replaceViewController:(NSViewController *)original withViewController:(NSViewController *)replacement;
@end

@implementation MCEditWindowController
@dynamic currentLibrary;

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];

    self.currentEditViewController = self.capeViewController;
    
    [RACAble(self.listViewController.selectedObject) subscribeNext:^(id x) {
        [self _changeEditViewsForSelection];
    }];
}

- (void)_changeEditViewsForSelection {
    BOOL capeEditor = [self.listViewController.selectedObject isKindOfClass:[MCCursorLibrary class]];
    if (capeEditor) {
        
        if (self.currentEditViewController != self.capeViewController) {
            // put on the cape view controllers
            [self _replaceViewController:self.cursorViewController withViewController:self.capeViewController];
        }
        
        self.capeViewController.cursorLibrary = self.listViewController.selectedObject;
        
    } else {
        
        if (self.currentEditViewController != self.cursorViewController) {
            [self _replaceViewController:self.capeViewController withViewController:self.cursorViewController];
        }
        
        
        self.cursorViewController.cursor = self.listViewController.selectedObject;        
    }
}

- (void)_replaceViewController:(NSViewController *)original withViewController:(NSViewController *)replacement {
    if (!original.view.superview)
        return;
    
    NSRect frame = original.view.frame;
    replacement.view.frame = frame;
    
    NSView *soup = original.view.superview;
    [original.view removeFromSuperview];
    [soup addSubview:replacement.view];
    
    self.currentEditViewController = replacement;
}

#pragma mark - Accessors
- (MCCursorLibrary *)currentLibrary {
    return self.listViewController.cursorLibrary;
}

- (void)setCurrentLibrary:(MCCursorLibrary *)currentLibrary {
    [self willChangeValueForKey:@"currentLibrary"];
    self.listViewController.cursorLibrary = currentLibrary;
    [self didChangeValueForKey:@"currentLibrary"];
}

#pragma mark - NSSplitViewDelegate
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
    if (offset == 0)
        return proposedMin + 180.0;
    return proposedMin + 440.0;
}

//!TODO: Fix the constraint breakage here
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
    if (offset == 0)
        return 180;
    return proposedMax - 180;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return subview == self.listViewController.view;
}

@end
