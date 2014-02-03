//
//  MCLibraryViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCLibraryViewController.h"
#import "MCCapeCellView.h"
#import "NSFileManager+DirectoryLocations.h"

@interface MCLibraryViewController ()
- (void)setupEnvironment;
- (void)doubleClick:(id)sender;
+ (NSString *)capesPath;
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

- (void)dealloc {
    [self.libraryController removeObserver:self forKeyPath:@"appliedCape"];
}

+ (NSString *)capesPath {
    return [[NSFileManager defaultManager] findOrCreateDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appendPathComponent:@"Mousecape/capes" error:NULL];
}

- (void)awakeFromNib {
    self.tableView.doubleAction = @selector(doubleClick:);
    self.tableView.target       = self;
}

- (void)setupEnvironment {
    self.libraryController = [[MCLibraryController alloc] initWithURL:[NSURL fileURLWithPath:self.class.capesPath]];
    self.libraryController.delegate = self;
    
    [self setRepresentedObject:self.libraryController];
    [self.tableView reloadData];
    
    [self.libraryController addObserver:self forKeyPath:NSStringFromSelector(@selector(appliedCape)) options:0 context:NULL];
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

- (void)editCape:(MCCursorLibrary *)library {
    NSLog(@"edit %@", library);
}

#pragma mark - Context Menu

- (IBAction)applyAction:(NSMenuItem *)sender {
    [self.libraryController applyCape:self.clickedCape];
}

- (IBAction)editAction:(NSMenuItem *)sender {
    [self editCape:self.clickedCape];
}

- (IBAction)duplicateAction:(NSMenuItem *)sender {
    [self.libraryController importCape:self.clickedCape.copy];
}

- (IBAction)removeAction:(NSMenuItem *)sender {
    [self.libraryController removeCape:self.clickedCape];
}

#pragma mark - MCLibraryDelegate

- (BOOL)libraryController:(MCLibraryController *)controller shouldAddCape:(MCCursorLibrary *)library {
    //!TODO: Make sure the identifier isn't taken
    return YES;
}

- (BOOL)libraryController:(MCLibraryController *)controller shouldRemoveCape:(MCCursorLibrary *)library {
    NSUInteger index = [controller.capes indexOfObject:library];
    [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectFade | NSTableViewAnimationSlideUp];
    if (index >= controller.capes.count)
        index = self.tableView.numberOfRows - 1;
    [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    return YES;
}

- (void)libraryController:(MCLibraryController *)controller didAddCape:(MCCursorLibrary *)library {
    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:[controller.capes indexOfObject:library]];
    [self.tableView insertRowsAtIndexes:indices withAnimation: NSTableViewAnimationSlideUp];
    
    [self.tableView selectRowIndexes:indices byExtendingSelection:NO];
    
    [self.view.window.undoManager setActionName:[@"Add " stringByAppendingString:library.name]];
    [[self.view.window.undoManager prepareWithInvocationTarget:self.libraryController] removeCape:library];
}

- (void)libraryController:(MCLibraryController *)controller didRemoveCape:(MCCursorLibrary *)library {
    // Move the file to the trash
    NSURL *destinationURL = [NSURL fileURLWithPath:[[@"~/.Trash" stringByExpandingTildeInPath] stringByAppendingPathComponent:library.fileURL.lastPathComponent] isDirectory:NO];

    [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:NULL];
    [[NSFileManager defaultManager] moveItemAtURL:library.fileURL toURL:destinationURL error:NULL];
    
    [self.view.window.undoManager setActionName:[@"Remove " stringByAppendingString:library.name]];
    [[self.view.window.undoManager prepareWithInvocationTarget:self.libraryController] importCapeAtURL:destinationURL];
    
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
    cellView.appliedImageView.hidden = !([self.libraryController.capes objectAtIndex:row] == self.libraryController.appliedCape);
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
