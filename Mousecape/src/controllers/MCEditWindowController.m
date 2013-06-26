//
//  MCEditWindowController.m
//  Mousecape
//
//  Created by Alex Zielenski on 6/25/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCEditWindowController.h"
#import "MCCursorDocument.h"

@interface MCEditWindowController ()
@property (weak) NSViewController *currentEditViewController;
- (void)_changeEditViewsForSelection;
- (void)_replaceViewController:(NSViewController *)original withViewController:(NSViewController *)replacement;
- (MCCursorDocument *)document;
@end

@implementation MCEditWindowController

- (NSString *)windowNibName {
    return @"EditWindow";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.currentEditViewController = self.capeViewController;
    
    RAC(self.listViewController.cursorLibrary) = RACAbleWithStart(self.document.library);
    [RACAble(self.listViewController.selectedObject) subscribeNext:^(id x) {
        [self _changeEditViewsForSelection];
    }];
}

- (MCCursorDocument *)document {
    return (MCCursorDocument *)[super document];
}

- (void)saveDocument:(id)sender {
    [self.document saveDocument:self];
}

#pragma mark - View Changing

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

#pragma mark - NSWindowDelegate

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return self.document.undoManager;
}

@end
