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

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"cursorLibrary"];
}

- (NSUndoManager *)undoManager {
    return self.view.window.undoManager;
}

- (void)_commonInit {
    [self addObserver:self forKeyPath:@"cursorLibrary" options:NSKeyValueObservingOptionNew context:nil];
    [self.tableView reloadData];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"cursorLibrary"]) {
        static NSArray *sortDescriptors = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sortDescriptors = @[
                                [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {return [obj1 compare:obj2 options:NSNumericSearch];}],
                                [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES selector:@selector(caseInsensitiveCompare:)]
                                ];
        });
        // get new keys & sort em
        self.sortedValues = [self.cursorLibrary.cursors.allValues sortedArrayUsingDescriptors:sortDescriptors];
    }
    [self.tableView reloadData];
    self.selectedObject = self.cursorLibrary;
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (void)reloadCursor:(MCCursor *)cursor {
    NSUInteger sortedIndex = [self.sortedValues indexOfObject:cursor];
    if (sortedIndex != NSNotFound) {
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:sortedIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    }
}

#pragma mark - UI

- (IBAction)addCursor:(id)sender {
    NSLog(@"add");
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
        NSString *name = self.cursorLibrary.name;
        header.textField.stringValue = name ? name : @"NO CURSOR";
        
        return header;
    }
    
    row--;
    
    NSTableCellView *cv = [tableView makeViewWithIdentifier:@"CursorCell" owner:self];
    cv.textField.stringValue = [[self.sortedValues objectAtIndex:row] prettyName];
    
    [cv.textField unbind:@"value"];
    [cv.textField bind:@"value" toObject:self.sortedValues[row] withKeyPath:@"prettyName" options:nil];
    
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

@end
