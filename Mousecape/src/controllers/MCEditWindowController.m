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
    [self addObserver:self forKeyPath:@"cursorViewController.identifier" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"listViewController.selectedObject" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"listViewController.selectedObject"];
    [self removeObserver:self forKeyPath:@"cursorViewController.identifier"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath  isEqualToString:@"listViewController.selectedObject"]) {
        [self _changeEditViewsForSelection];
    } else if ([keyPath isEqualToString:@"cursorViewController.identifier"]) {
        [self.currentLibrary moveCursor:self.cursorViewController.cursor toIdentifier:self.cursorViewController.identifier];
    }
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
        self.cursorViewController.identifier = [self.currentLibrary identifierForCursor:self.cursorViewController.cursor];
        
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

- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
    if (offset == 0)
        return 180;
    return proposedMax - 180;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return subview == self.listViewController.view;
}

@end
