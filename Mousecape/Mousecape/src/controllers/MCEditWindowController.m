//
//  MCEditWindowController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCEditWindowController.h"
#import "MCLibraryController.h"

@interface MCEditWindowController ()
- (void)_setCurrentViewController:(NSViewController *)vc;
- (BOOL)promptSaveForLibrary:(MCCursorLibrary *)nextLibrary;
@end

@implementation MCEditWindowController
@dynamic cursorLibrary;

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

+ (NSSet *)keyPathsForValuesAffectingCursorLibrary {
    return [NSSet setWithObject:@"editListController.cursorLibrary"];
}

- (MCCursorLibrary *)cursorLibrary {
    return self.editListController.cursorLibrary;
}

- (void)setCursorLibrary:(MCCursorLibrary *)cursorLibrary {
    [self promptSaveForLibrary:cursorLibrary];
}

- (BOOL)promptSaveForLibrary:(MCCursorLibrary *)nextLibrary {
    if (!self.window.isDocumentEdited) {
        self.editListController.cursorLibrary = nextLibrary;
        return NO;
    }
    
    NSBeginAlertSheet(@"Do you want to save your changes?", @"Save", @"Cancel", @"Discard Changes", self.window, self, NULL, @selector(sheetDidDismiss:returnCode:contextInfo:), (__bridge void *)nextLibrary, @"Your changes will be discarded if you don't save them.");
    return YES;
}

- (void)windowDidLoad {
    [super windowDidLoad];    
    [self.editListController addObserver:self forKeyPath:@"selectedObject" options:0 context:nil];
    [self _setCurrentViewController:self.editCapeController];
    
    [self.window bind:@"documentEdited" toObject:self withKeyPath:@"cursorLibrary.dirty" options:nil];
}

- (void)dealloc {
    [self.editListController removeObserver:self forKeyPath:@"selectedObject"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selectedObject"]) {
        [self _changeEditViewsForSelection];
    }
}

- (BOOL)windowShouldClose:(NSWindow *)window {
    return ![self promptSaveForLibrary:nil];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return self.cursorLibrary.undoManager;
}

- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(MCCursorLibrary *)contextInfo {
    if (returnCode == 0) { // cancel
       // do nothing
    } else if (returnCode == 1) { // save
        NSError *error = [self.cursorLibrary save];
        if (!error) {
            self.editListController.cursorLibrary = contextInfo;
        
            if (!contextInfo)
                [self.window close];
        } else {
            [NSApp presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:nil];
        }
    } else if (returnCode == -1) { // discard changes
        [self.cursorLibrary revertToSaved];
        self.editListController.cursorLibrary = contextInfo;
        
        if (!contextInfo)
            [self.window close];
    }
}

#pragma mark - Menu Actions

- (IBAction)applyCape:(id)sender {
    [self.cursorLibrary.library applyCape:self.cursorLibrary];
}

- (IBAction)duplicateCape:(id)sender {
    [self.cursorLibrary.library importCape:self.cursorLibrary.copy];
}

- (IBAction)checkCape:(id)sender {
    
}

- (IBAction)saveDocument:(id)sender {
    NSError *error = [self.cursorLibrary save];
    if (error)
        [self presentError:error modalForWindow:self.window delegate:nil didPresentSelector:NULL contextInfo:NULL];
}

- (IBAction)revertDocumentToSaved:(id)sender {
    [self.cursorLibrary revertToSaved];
}

- (IBAction)showCape:(id)sender {
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ self.cursorLibrary.fileURL ]];
}

- (NSError *)willPresentError:(NSError *)error {
    return [NSError errorWithDomain:error.domain code:error.code userInfo:@{
                                                                            NSLocalizedDescriptionKey: error.localizedDescription ?: @"",
                                                                            NSLocalizedRecoverySuggestionErrorKey: error.localizedFailureReason ?: @""
                                                                            }];
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
