//
//  MCEditListViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCEditListViewController.h"
#import "MCLibraryRowView.h"
#import "NSOrderedSet+AZSortedInsert.h"

@interface MCEditListViewController ()
@property (strong) NSMutableOrderedSet *sortedValues;
@property (strong) NSArray *sortDescriptors;
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

static void *MCCursorChangeContext;
- (void)_commonInit {
    self.sortedValues = [NSMutableOrderedSet orderedSet];
    self.sortDescriptors = @[
                             [NSSortDescriptor sortDescriptorWithKey:@"prettyName" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
                                 return [obj1 compare:obj2 options:NSNumericSearch | NSCaseInsensitiveSearch];
                             }],
                             ];
    
    @weakify(self);
    [self rac_addDeallocDisposable:[[RACAble(self.cursorLibrary) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(MCCursorLibrary *library) {
        @strongify(self);
        [self.tableView reloadData];
        self.selectedObject = library;
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }]];
    
    [self addObserver:self forKeyPath:@"cursorLibrary.cursors" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&MCCursorChangeContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != &MCCursorChangeContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
    NSUInteger selection  = self.tableView.selectedRow;
    
    [self.tableView beginUpdates];
    
    if (kind == NSKeyValueChangeInsertion) {
        NSSet *objects = change[NSKeyValueChangeNewKey];
        for (id object in objects) {
            NSUInteger idx = [self.sortedValues indexForInsertingObject:object sortedUsingDescriptors:self.sortDescriptors];
            [self.sortedValues insertObject:object atIndex:idx];
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:idx + 1] withAnimation:NSTableViewAnimationEffectGap];
            selection = idx;
        }
    } else if (kind == NSKeyValueChangeSetting) {
        NSSet *objects = change[NSKeyValueChangeNewKey];
        if ([objects isKindOfClass:[NSNull class]])
            self.sortedValues = [NSMutableOrderedSet orderedSet];
        else
            self.sortedValues = [NSMutableOrderedSet orderedSetWithArray:[objects sortedArrayUsingDescriptors:self.sortDescriptors]];
        [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, self.sortedValues.count)] withAnimation:NSTableViewAnimationEffectGap];
    } else if (kind == NSKeyValueChangeRemoval) {
        NSSet *objects = change[NSKeyValueChangeOldKey];
        for (id object in objects) {
            NSUInteger idx = [self.sortedValues indexOfObject:object];
            BOOL select = (self.tableView.selectedRow == idx + 1);
            if (select) {
                selection = idx;
            }
            [self.sortedValues removeObjectAtIndex:idx];
            [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:idx + 1] withAnimation:NSTableViewAnimationEffectFade];
        }
    } else if (kind == NSKeyValueChangeReplacement) {
//        NSLog(@"%@", change);
    }
    
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:MIN(selection, self.sortedValues.count)] byExtendingSelection:NO];
    
    [self.tableView endUpdates];
}

#pragma mark - UI

- (IBAction)addCursor:(id)sender {
    MCCursor *cursor = [[MCCursor alloc] init];
    cursor.identifier = [NSString stringWithFormat:@"Cursor %lu", self.cursorLibrary.cursors.count + 1];
    [self.cursorLibrary addCursor:cursor];
}

- (IBAction)removeCursor:(id)sender {
    if (![self.selectedObject isKindOfClass:[MCCursor class]])
        return;
    
    if (MCFlag(MCSuppressDeleteCursorConfirmationKey)) {
        [self confirmationAlertDidEnd:nil returnCode:NSAlertDefaultReturn contextInfo:self.selectedObject];
    } else {
        NSAlert *sureAlert = [NSAlert alertWithMessageText:@"Are you sure?"
                                             defaultButton:@"Positive"
                                           alternateButton:@"Nevermind"
                                               otherButton:nil
                                 informativeTextWithFormat:@"This operation cannot be undone"];
        sureAlert.showsSuppressionButton = YES;
        [sureAlert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(confirmationAlertDidEnd:returnCode:contextInfo:) contextInfo:(void *)self.selectedObject];
    }
}

- (void)confirmationAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(MCCursor *)selectedCursor {
    if (returnCode == NSAlertDefaultReturn) {
        [alert.window orderOut:self];
        
        [self.cursorLibrary removeCursor:selectedCursor];
        
        MCSetFlag(alert.suppressionButton.state == NSOnState, MCSuppressDeleteCursorConfirmationKey);
        [self.tableView reloadData];
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {    
    return self.sortedValues.count + 1;
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
