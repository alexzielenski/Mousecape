//
//  MCLibraryViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCLibraryViewController.h"
#import "MCCapeCellView.h"

@interface MCLibraryViewController ()
- (void)setupEnvironment;
- (void)doubleClick:(id)sender;
@end

@implementation MCLibraryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self setupEnvironment];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [self setupEnvironment];
    }
        
    return self;
}

- (void)awakeFromNib {
    self.tableView.dataSource   = self;
    self.tableView.delegate     = self;
    self.tableView.target       = self;
    self.tableView.doubleAction = @selector(doubleClick:);
}

- (void)loadView {
    [super loadView];
    self.tableView.dataSource = self;
    self.tableView.delegate   = self;
}

- (void)setupEnvironment {
    [self setRepresentedObject:[MCLibraryController sharedLibraryController]];
    [self.tableView reloadData];
    
    [[MCLibraryController sharedLibraryController]  addObserver:self forKeyPath:NSStringFromSelector(@selector(appliedCape)) options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(appliedCape))]) {
        for (NSUInteger x = 0; x < self.tableView.numberOfRows; x++) {
            MCCapeCellView *cv = [self.tableView viewAtColumn:0 row:x makeIfNecessary:NO];
            cv.appliedImageView.hidden = !(cv.objectValue == [[MCLibraryController sharedLibraryController] appliedCape]);
        }
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];

}

- (void)doubleClick:(NSTableView *)sender {
    NSUInteger row = sender.clickedRow;
    MCCursorLibrary *library = [[sender viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
    [[MCLibraryController sharedLibraryController] applyCape:library];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [MCLibraryController.sharedLibraryController.capes count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [MCLibraryController.sharedLibraryController.capes objectAtIndex:rowIndex];
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    MCCapeCellView *cellView = (MCCapeCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    MCLibraryController *libraryController = MCLibraryController.sharedLibraryController;
    cellView.appliedImageView.hidden = !([libraryController.capes objectAtIndex:row] == libraryController.appliedCape);
    return cellView;
}

//- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
//    return nil;
//}

@end
