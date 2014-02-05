//
//  MCEditWindowController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCEditWindowController.h"

@interface MCEditWindowController ()
- (void)_setCurrentViewController:(NSViewController *)vc;
@end

@implementation MCEditWindowController

- (id)initWithWindow:(NSWindow *)window {
    if ((self = [super initWithWindow:window])) {
        // Initialization code here.
    }
    return self;
}


- (void)loadWindow {
    [super loadWindow];
    [self windowDidLoad];
}

- (void)windowDidLoad {
    [super windowDidLoad];    
    [self.editListController addObserver:self forKeyPath:@"selectedObject" options:0 context:nil];
    [self _setCurrentViewController:self.editCapeController];
}

- (void)dealloc {
    [self.editListController removeObserver:self forKeyPath:@"selectedObject"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectedObject"]) {
        [self _changeEditViewsForSelection];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    //!TODO: Do saving properly
    [self.editListController.cursorLibrary save];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return self.editListController.cursorLibrary.undoManager;
}

#pragma mark - View Changing

- (void)_changeEditViewsForSelection {
    BOOL capeEditor = [self.editListController.selectedObject isKindOfClass:[MCCursorLibrary class]];
    if (capeEditor) {
        [self _setCurrentViewController:self.editCapeController];
        self.editCapeController.cursorLibrary = self.editListController.selectedObject;
    } else {
        [self _setCurrentViewController:self.editDetailController];
        self.editDetailController.cursor = self.editListController.selectedObject;
    }
}

- (void)_setCurrentViewController:(NSViewController *)vc {
    if ([self.detailView.subviews containsObject:vc.view])
        return;
    
    [self.detailView setSubviews:@[]];
    [self.detailView removeConstraints:self.detailView.constraints];
    
    NSRect frame  = self.detailView.bounds;
    vc.view.frame = frame;
    
    // Fill superview with subview
    [vc.view setTranslatesAutoresizingMaskIntoConstraints:YES];
    [vc.view setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable | NSViewMinYMargin | NSViewMinXMargin];
    
    [self.detailView addSubview:vc.view];
}

#pragma mark - NSSplitViewDelegate

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview {
    return NO;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    if (dividerIndex == 0) {
        return 120.0f;
    }
    
    return proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
    if (dividerIndex == 0) {
        return splitView.frame.size.width - 380.0;
    }
    return proposedMax;
}

@end