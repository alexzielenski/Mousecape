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
    self.tableView.delegate     = self;
    self.tableView.target       = self;
    self.tableView.doubleAction = @selector(doubleClick:);
    self.tableView.menu         = self.contextMenu;
}

- (void)loadView {
    [super loadView];
    self.tableView.delegate     = self;
    self.tableView.target       = self;
    self.tableView.doubleAction = @selector(doubleClick:);
    self.tableView.menu         = self.contextMenu;
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

#pragma mark - Context Menu

- (IBAction)applyAction:(NSMenuItem *)sender {
    NSUInteger row = self.tableView.clickedRow;
    MCCursorLibrary *library = [[self.tableView viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
    [self.libraryController applyCape:library];
}

- (IBAction)editAction:(NSMenuItem *)sender {
    NSUInteger row = self.tableView.clickedRow;
    MCCursorLibrary *library = [[self.tableView viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
    NSLog(@"edit %@", library);
}

- (IBAction)duplicateAction:(NSMenuItem *)sender {
    NSUInteger row = self.tableView.clickedRow;
    MCCursorLibrary *library = [[self.tableView viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
    [self.libraryController importCape:library.copy];
}

- (IBAction)removeAction:(NSMenuItem *)sender {
    NSUInteger row = self.tableView.clickedRow;
    MCCursorLibrary *library = [[self.tableView viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
    
    //!TODO: Prompt user if he/she is sure
    [self.libraryController removeCape:library];
    [[NSFileManager defaultManager] removeItemAtURL:library.fileURL error:nil];
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
