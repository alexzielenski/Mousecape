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
    self.tableView.doubleAction = @selector(doubleClick:);
}

- (void)setupEnvironment {
    self.libraryController = [MCLibraryController sharedLibraryController];
    [self setRepresentedObject:self.libraryController];
    [self.tableView reloadData];
    
//    [self.libraryController addObserver:self forKeyPath:NSStringFromSelector(@selector(capes)) options:0 context:NULL];
    [self.libraryController  addObserver:self forKeyPath:NSStringFromSelector(@selector(appliedCape)) options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(appliedCape))]) {
        for (NSUInteger x = 0; x < self.tableView.numberOfRows; x++) {
            MCCapeCellView *cv = [self.tableView viewAtColumn:0 row:x makeIfNecessary:NO];
            cv.appliedImageView.hidden = !(cv.objectValue == [self.libraryController appliedCape]);
        }
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];

}

- (void)doubleClick:(NSTableView *)sender {
    NSUInteger row = sender.clickedRow;
    MCCursorLibrary *library = [[sender viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
    [self.libraryController applyCape:library];
}

- (MCCursorLibrary *)selectedCape {
    return [[self.tableView viewAtColumn:0 row:self.tableView.selectedRow makeIfNecessary:NO] objectValue];
}

- (MCCursorLibrary *)clickedCape {
    return [[self.tableView viewAtColumn:0 row:self.tableView.clickedRow makeIfNecessary:NO] objectValue];
}

- (void)newCape:(id)sender {
    MCCursorLibrary *lib = [[MCCursorLibrary alloc] init];
    [self.libraryController importCape:lib];
    [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:[self.libraryController.capes indexOfObject:lib]] withAnimation:NSTableViewAnimationSlideUp];
}

- (void)applyCape:(MCCursorLibrary *)library {
    [self.libraryController applyCape:library];
}

- (void)editCape:(MCCursorLibrary *)library {
    NSLog(@"edit %@", library);
}

- (void)duplicateCape:(MCCursorLibrary *)library {
    MCCursorLibrary *lib = library.copy;
    [self.libraryController importCape:lib];
    [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:[self.libraryController.capes indexOfObject:lib]] withAnimation:NSTableViewAnimationSlideUp];
}

- (void)removeCape:(MCCursorLibrary *)library {
    //!TODO: Prompt user if he/she is sure
    if (NSRunAlertPanel(@"Warning", @"This operation cannot be undone. Continue?", @"Yeah", @"Nope", nil) == NSOKButton) {
        [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:[self.libraryController.capes indexOfObject:library]] withAnimation:NSTableViewAnimationSlideUp | NSTableViewAnimationEffectFade];
        [self.libraryController removeCape:library];
        [[NSFileManager defaultManager] moveItemAtURL:library.fileURL toURL:[NSURL fileURLWithPath:[[@"~/.Trash" stringByExpandingTildeInPath] stringByAppendingPathComponent:library.fileURL.lastPathComponent] isDirectory:YES] error:NULL];
    }
}

#pragma mark - Context Menu

- (IBAction)applyAction:(NSMenuItem *)sender {
    [self applyCape:self.clickedCape];
}

- (IBAction)editAction:(NSMenuItem *)sender {
    [self editCape:self.clickedCape];
}

- (IBAction)duplicateAction:(NSMenuItem *)sender {
    [self duplicateCape:self.clickedCape];
}

- (IBAction)removeAction:(NSMenuItem *)sender {
    [self removeCape:self.clickedCape];
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.libraryController.capes.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return self.libraryController.capes[row];
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

@implementation MCOrderedSetTransformer

+ (Class)transformedValueClass {
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (id)transformedValue:(id)value {
    return [(NSOrderedSet *)value array];
}

- (id)reverseTransformedValue:(id)value {
	return [NSOrderedSet orderedSetWithArray:value];
}

@end
