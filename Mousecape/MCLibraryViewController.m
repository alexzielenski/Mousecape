//
//  MCLibraryViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCLibraryViewController.h"
#import "MCCursorLibrary.h"
#import "MCTableCellView.h"
#import "NSArray+CWSortedInsert.h"
#import "MCCloakController.h"
#import "MCLibraryWindowController.h"

@implementation MCLibraryViewController
- (void)awakeFromNib {
    self.tableView.target = self;
    self.tableView.doubleAction = @selector(doubleClick:);
}

#pragma mark - Interface Actions
- (IBAction)contextMenu:(NSMenuItem *)sender {
    MCCursorDocument *clickedDocument = [self.windowController.documents objectAtIndex:self.tableView.clickedRow];
    switch (sender.tag) {
        case 0: { // Apply
            [clickedDocument apply:sender];
            break;
        }
        case 1: { // Edit
            [clickedDocument edit:sender];
            break;
        }
        case 2: { // Duplicate
            [clickedDocument duplicateDocument:sender];
            break;
        }
        case 3: { // Remove
            [clickedDocument close];
        }
        default:
            break;
    }
}

//- (IBAction)importMightyMouse:(id)sender {
//    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//    openPanel.allowedFileTypes = @[ @"MightyMouse" ];
//    openPanel.message = @"Select a MightyMouse file to convert";
//    openPanel.prompt = @"Import";
//    openPanel.allowsOtherFileTypes = NO;
//    openPanel.allowsMultipleSelection = YES;
//    
//    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
//        if (result == NSOKButton) {
//            for (NSURL *url in openPanel.URLs) {
//                MCCloakController *clk = [MCCloakController sharedCloakController];
//                
//                NSString *outPath = [clk convertMightyMouse:url.path];
//                [self addToLibrary:outPath];
//            }
//        }
//    }];
//}

- (void)doubleClick:(id)sender {
    [self.windowController capeAction:self.windowController.currentCursor];
}

#pragma mark - NSTableViewDelgate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    MCTableCellView *cellView = (MCTableCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    [cellView.cursorLine bind:@"animationsEnabled" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"MCAnimationsEnabled" options:nil];

    @weakify(self);

    if (!cellView.appliedDisposable) {
        RACDisposable *binding = [[[RACSignal combineLatest:@[
                                                             RACAble(cellView, objectValue),
                                                             RACAble(self.windowController, appliedCursor)
                                                             ]
                                                    reduce:^(id objectValue, MCCursorLibrary *appliedLib) {
                                                        @strongify(self);
                                                        return @(objectValue == self.windowController.appliedCursor);
                                                    }] deliverOn:[RACScheduler mainThreadScheduler]] toProperty:@"applied" onObject:cellView];
        cellView.appliedDisposable = binding;
    }
    cellView.applied = [self tableView:tableView objectValueForTableColumn:tableColumn row:row] == self.windowController.appliedCursor;
    
    return cellView;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.tableView.selectedRow == -1)
        self.windowController.currentCursor = nil;
    else {
        MCCursorDocument *selectedLibrary = [[self.tableView viewAtColumn:0 row:self.tableView.selectedRow makeIfNecessary:NO] objectValue];
        self.windowController.currentCursor = selectedLibrary;
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.windowController.documents count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [self.windowController.documents objectAtIndex:rowIndex];
}

@end
