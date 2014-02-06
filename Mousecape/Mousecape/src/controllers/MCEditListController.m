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

@interface MCEditListController ()
@property (nonatomic, strong) NSMutableOrderedSet *cursors;
+ (NSComparator)sortComparator;
@end

@implementation MCEditListController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self addObserver:self forKeyPath:@"cursorLibrary" options:0 context:nil];
        [self addObserver:self forKeyPath:@"cursorLibrary.cursors" options:0 context:NULL];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [self addObserver:self forKeyPath:@"cursorLibrary" options:0 context:nil];
        [self addObserver:self forKeyPath:@"cursorLibrary.cursors" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:(void*)&MCEditCursorsContext];

    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"cursorLibrary"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"cursorLibrary"]) {
        [(NSTableView *)self.view reloadData];
        // make sure the selected object is set
        [self tableViewSelectionDidChange:nil];
    } else if (context == &MCEditCursorsContext) {
        NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] integerValue];
        
        if (kind == NSKeyValueChangeSetting) {
            id nextSet = change[NSKeyValueChangeNewKey];
            if ([nextSet isKindOfClass:[NSNull class]]) {
                self.cursors = [NSMutableOrderedSet orderedSet];
            } else {
                self.cursors = [NSMutableOrderedSet orderedSetWithSet:nextSet copyItems:NO];
                [self.cursors sortUsingComparator:self.class.sortComparator];
            }
        } else if (kind == NSKeyValueChangeInsertion) {
            for (MCCursor *lib in change[NSKeyValueChangeNewKey]) {
                NSUInteger index = [self.cursors indexForInsertingObject:lib sortedUsingComparator:self.class.sortComparator];
                NSIndexSet *indices = [NSIndexSet indexSetWithIndex:index];
                
                [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"capes"];
                [self.cursors insertObject:lib atIndex:index];
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"capes"];
                [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:index + 1] withAnimation:NSTableViewAnimationSlideUp];
            }
        } else if (kind == NSKeyValueChangeRemoval) {
            for (MCCursor *lib in change[NSKeyValueChangeOldKey]) {
                NSUInteger index = [self.cursors indexOfObject:lib];
                NSIndexSet *indices = [NSIndexSet indexSetWithIndex:index];
                
                [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"capes"];
                [self.cursors removeObjectAtIndex:index];
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"capes"];
                [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index + 1] withAnimation:NSTableViewAnimationSlideUp | NSTableViewAnimationEffectFade];
                
            }

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

- (IBAction)removeAction:(id)sender {
    if (self.tableView.selectedRow != 0)
        [self.cursorLibrary removeCursor:[[self.tableView viewAtColumn:0 row:self.tableView.selectedRow makeIfNecessary:NO] objectValue]];
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = [(NSTableView *)self.view selectedRow];
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
