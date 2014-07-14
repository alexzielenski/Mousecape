//
//  MCEditListController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCEditListController.h"
#import "NSOrderedSet+AZSortedInsert.h"

const char MCEditCursorsContext;
const char MCCursorNameContext;

@interface MCEditListController ()
@property (nonatomic, strong) NSMutableOrderedSet *cursors;
+ (NSComparator)sortComparator;
- (void)startObservingCursor:(MCCursor *)cursor;
- (void)stopObservingCursor:(MCCursor *)cursor;
@end

@implementation MCEditListController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self addObserver:self forKeyPath:@"cursorLibrary.cursors" options:0 context:NULL];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [self addObserver:self forKeyPath:@"cursorLibrary.cursors" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:(void*)&MCEditCursorsContext];

    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"cursorLibrary.cursors" context:(void *)&MCEditCursorsContext];
    
    for (MCCursor *cursor in self.cursors) {
        [self stopObservingCursor:cursor];
    }
    
}

- (void)startObservingCursor:(MCCursor *)cursor {
    [cursor addObserver:self forKeyPath:@"name" options:0 context:(void *)&MCCursorNameContext];
}

- (void)stopObservingCursor:(MCCursor *)cursor {
    [cursor removeObserver:self forKeyPath:@"name" context:(void *)&MCCursorNameContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &MCEditCursorsContext) {
        NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] integerValue];
        [self.tableView beginUpdates];
        
        if (kind == NSKeyValueChangeSetting) {
            id nextSet = change[NSKeyValueChangeNewKey];
            if ([nextSet isKindOfClass:[NSNull class]]) {
                self.cursors = [NSMutableOrderedSet orderedSet];
            } else {
                self.cursors = [NSMutableOrderedSet orderedSetWithSet:nextSet copyItems:NO];
                [self.cursors sortUsingComparator:self.class.sortComparator];
                for (MCCursor *cursor in self.cursors) {
                    [self startObservingCursor:cursor];
                }
            }
            
            [self.tableView reloadData];
            [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        } else if (kind == NSKeyValueChangeInsertion) {
            for (MCCursor *lib in change[NSKeyValueChangeNewKey]) {
                NSUInteger index = [self.cursors indexForInsertingObject:lib sortedUsingComparator:self.class.sortComparator];
                NSIndexSet *indices = [NSIndexSet indexSetWithIndex:index];

                [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"cursors"];
                [self.cursors insertObject:lib atIndex:index];
                [self startObservingCursor:lib];
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"cursors"];
                [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index + 1] withAnimation:NSTableViewAnimationSlideUp];
            }
        } else if (kind == NSKeyValueChangeRemoval) {
            for (MCCursor *lib in change[NSKeyValueChangeOldKey]) {
                NSUInteger index = [self.cursors indexOfObject:lib];
                
                if (index != NSNotFound) {
                    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:index];
                    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indices forKey:@"cursors"];
                    [self stopObservingCursor:lib];
                    [self.cursors removeObjectAtIndex:index];
                    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indices forKey:@"cursors"];
                    [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index + 1] withAnimation:NSTableViewAnimationSlideUp | NSTableViewAnimationEffectFade];
                }
            }
        }
        [self.tableView endUpdates];
    } else if (context == &MCCursorNameContext) {
        // Reorder it
        MCCursorLibrary *cape = object;
        NSUInteger oldIndex = [self.cursors indexOfObject:cape];
        if (oldIndex != NSNotFound) {
            [self.cursors removeObjectAtIndex:oldIndex];
            NSUInteger newIndex = [self.cursors indexForInsertingObject:cape sortedUsingComparator:self.class.sortComparator];
            
            [self.cursors insertObject:cape atIndex:newIndex];
            [self.tableView moveRowAtIndex:oldIndex + 1 toIndex:newIndex + 1];
        }
    }
}

+ (NSComparator)sortComparator {
    static NSComparator sortComparator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sortComparator = ^NSComparisonResult(id obj1, id obj2) {
            return [[obj1 valueForKey:@"name"] localizedCaseInsensitiveCompare:[obj2 valueForKey:@"name"]];
        };
    });
    
    return sortComparator;
}

- (IBAction)addAction:(id)sender {
    [self.cursorLibrary addCursor:[[MCCursor alloc] init]];
}

- (IBAction)removeAction:(NSMenuItem *)sender {
    NSInteger row = NSNotFound;
    if (sender.tag == -1)
        row = self.tableView.clickedRow;
    else
        row = self.tableView.selectedRow;
    
    if (row > 0)
        [self.cursorLibrary removeCursor:[[self.tableView viewAtColumn:0 row:row makeIfNecessary:NO] objectValue]];
}

- (IBAction)duplicateAction:(NSMenuItem *)sender {
    NSUInteger row = NSNotFound;
    if (sender.tag == -1)
        row = self.tableView.clickedRow;
    else
        row = self.tableView.selectedRow;
    
    if (row > 0) {
        MCCursor *cursor = [[[self.tableView viewAtColumn:0 row:row makeIfNecessary:NO] objectValue] copy];
        cursor.identifier = UUID();
        [self.cursorLibrary addCursor:cursor];
    }
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = [(NSTableView *)self.view selectedRow];
    if (selectedRow == NSNotFound || selectedRow >= self.cursors.count + 1)
        return;
    
    if (selectedRow == 0)
        self.selectedObject = self.cursorLibrary;
    else
        self.selectedObject = [self.cursors objectAtIndex:selectedRow - 1];
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
    return row == 0;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    if (row == 0)
        return 32.0;
    return 22.0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSView *view;
    if (row == 0)
        view = [tableView makeViewWithIdentifier:@"MCCursorLibrary" owner:self];
    else
        view = [tableView makeViewWithIdentifier:@"MCCursor" owner:self];
    return view;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.cursors.count + 1;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row == 0)
        return self.cursorLibrary;
    return [self.cursors objectAtIndex: row - 1];
}

@end
