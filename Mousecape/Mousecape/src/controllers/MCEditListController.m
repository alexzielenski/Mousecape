//
//  MCEditListController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCEditListController.h"

@interface MCEditListController ()
@property (strong) NSArrayController *arrayController;
@end

@implementation MCEditListController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.arrayController = [[NSArrayController alloc] init];
        [self addObserver:self forKeyPath:@"cursorLibrary" options:0 context:nil];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        self.arrayController = [[NSArrayController alloc] init];
        self.arrayController.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] ];
        [self addObserver:self forKeyPath:@"cursorLibrary" options:0 context:nil];
        [self.arrayController bind:@"contentSet" toObject:self withKeyPath:@"cursorLibrary.cursors" options:nil];

    }
    return self;
}

- (void)dealloc {
    [self.arrayController unbind:@"contentSet"];
    [self removeObserver:self forKeyPath:@"cursorLibrary"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"cursorLibrary"]) {
        [(NSTableView *)self.view reloadData];
        
        // make sure the selected object is set
        [self tableViewSelectionDidChange:nil];
    }
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selectedRow = [(NSTableView *)self.view selectedRow];
    if (selectedRow == 0)
        self.selectedObject = self.cursorLibrary;
    else
        self.selectedObject = [self.arrayController.arrangedObjects objectAtIndex:selectedRow - 1];
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
    return [self.arrayController.arrangedObjects count] + 1;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row == 0)
        return self.cursorLibrary;
    return [[self.arrayController arrangedObjects] objectAtIndex: row - 1];
}

@end
