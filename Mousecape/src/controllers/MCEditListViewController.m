//
//  MCEditListViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCEditListViewController.h"
#import "MCLibraryRowView.h"

@interface MCEditListViewController ()
@property (strong) NSArray *sortedValues;
- (void)_commonInit;
@end

@implementation MCEditListViewController
- (id)init {
    if ((self = [super init])) {
        [self _commonInit];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self _commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self _commonInit];
    }
    
    return self;
}

- (void)_commonInit {
    [self.tableView reloadData];
    
    @weakify(self);
    [[RACAble(self.cursorLibrary) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        if (!self.tableView.sortDescriptors.count)
            [self.tableView setSortDescriptors:@[
                                                 [NSSortDescriptor sortDescriptorWithKey:@"prettyName" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
                                                        return [obj1 compare:obj2 options:NSNumericSearch | NSCaseInsensitiveSearch];
                                                    }],
                                                 ]];
        
        // get new keys & sort em
        self.sortedValues = [self.cursorLibrary.cursors.allValues sortedArrayUsingDescriptors:self.tableView.sortDescriptors];
        [self.tableView reloadData];
        
        self.selectedObject = self.cursorLibrary;
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }];
}

- (void)reloadCursor:(MCCursor *)cursor {
    NSUInteger sortedIndex = [self.sortedValues indexOfObject:cursor];
    if (sortedIndex != NSNotFound) {
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:sortedIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}

#pragma mark - UI

- (IBAction)addCursor:(id)sender {
    MCCursor *cursor = [[MCCursor alloc] init];
    [self.cursorLibrary addCursor:cursor forIdentifier:[NSString stringWithFormat:@"Cursor %lu", self.cursorLibrary.cursors.count + 1]];
    
    self.sortedValues = [self.cursorLibrary.cursors.allValues sortedArrayUsingDescriptors:self.tableView.sortDescriptors];
    [self.tableView reloadData];
    
    self.selectedObject = cursor;
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.sortedValues indexOfObject:cursor] + 1] byExtendingSelection:NO];
}

- (IBAction)removeCursor:(id)sender {
    NSAlert *sureAlert = [NSAlert alertWithMessageText:@"Are you sure?"
                                         defaultButton:@"Positive"
                                       alternateButton:@"Nevermind"
                                           otherButton:nil
                             informativeTextWithFormat:@"This operation cannot be undone"];
    
    sureAlert.showsSuppressionButton = !MCFlag(MCSuppressDeleteCursorConfirmationKey);
    [sureAlert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(confirmationAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)confirmationAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSUInteger row = self.tableView.selectedRow;
        MCCursor *selectedCursor = self.sortedValues[row - 1];
        [self.cursorLibrary removeCursor:selectedCursor];
        
        MCSetFlag(alert.suppressionButton.state == NSOnState, MCSuppressDeleteCursorConfirmationKey);
        [self.tableView reloadData];
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {    
    return self.cursorLibrary.cursors.count + 1;
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.tableView.selectedRow == 0) {
        self.selectedObject = self.cursorLibrary;
    } else {
        self.selectedObject = self.sortedValues[self.tableView.selectedRow - 1];
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row == 0) {
        NSTableCellView *header = [tableView makeViewWithIdentifier:@"LibraryCell" owner:self];
        return header;
    }
    

    NSTableCellView *cv = [tableView makeViewWithIdentifier:@"CursorCell" owner:self];
    return cv;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    if (row == 0) {
        return [[MCLibraryRowView alloc] init];
    }
    return nil;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    return row == 0;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if (row == 0)
        return 48.0;
    return 18.0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row == 0) {
        return self.cursorLibrary;
    }
    
    return self.sortedValues[--row];
}

@end
