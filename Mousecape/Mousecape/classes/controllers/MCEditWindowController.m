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
    NSLog(@"window did load");
    
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
    NSRect frame  = self.detailView.frame;
    vc.view.frame = frame;
    [self.detailView addSubview:vc.view];
}

@end
