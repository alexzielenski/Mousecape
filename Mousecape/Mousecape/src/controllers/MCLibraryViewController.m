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
#import "MCEditWindowController.h"
#import "NSOrderedSet+AZSortedInsert.h"

const char MCLibraryCapesContext;
const char MCLibraryNameContext;

@interface MCLibraryViewController ()
@property (strong) MCEditWindowController *editWindowController;
@property (readwrite, strong) NSMutableOrderedSet *capes;
@property (strong, readwrite) MCLibraryController *libraryController;
- (void)setupEnvironment;
- (void)doubleClick:(id)sender;
+ (NSString *)capesPath;
+ (NSComparator)sortComparator;
@end

@implementation MCLibraryViewController
@dynamic clickedCape, selectedCape, editingCape;

+ (NSComparator)sortComparator {
    static NSComparator sortComparator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sortComparator = ^NSComparisonResult(id obj1, id obj2) {
            NSComparisonResult result = [[obj1 valueForKey:@"name"] localizedCaseInsensitiveCompare:[obj2 valueForKey:@"name"]];
            if (result == NSOrderedSame)
                result = [[obj1 valueForKey:@"author"] localizedCaseInsensitiveCompare:[obj2 valueForKey:@"author"]];
            return result;
        };
    });
    
    return sortComparator;
}

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
    
    for (MCCursorLibrary *library in self.capes) {
        [library removeObserver:self forKeyPath:@"name" context:(void *)&MCLibraryNameContext];
    }
    
}

+ (NSString *)capesPath {
    return [[NSFileManager defaultManager] findOrCreateDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appendPathComponent:@"Mousecape/capes" error:NULL];
}

- (void)awakeFromNib {
    self.tableView.doubleAction = @selector(doubleClick:);
    self.tableView.target       = self;
}

- (void)setupEnvironment {
    [self addObserver:self forKeyPath:@"libraryController.capes" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:(void *)&MCLibraryCapesContext];
    self.libraryController = [[MCLibraryController alloc] initWithURL:[NSURL fileURLWithPath:self.class.capesPath]];

    [self setRepresentedObject:self.libraryController];
    [self.libraryController addObserver:self forKeyPath:NSStringFromSelector(@selector(appliedCape)) options:0 context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(appliedCape))]) {
        for (NSUInteger x = 0; x < self.tableView.numberOfRows; x++) {
            MCCapeCellView *cv = [self.tableView viewAtColumn:0 row:x makeIfNecessary:NO];
            cv.appliedImageView.hidden = !(cv.objectValue == [self.libraryController appliedCape]);
        }
        
    } else if (context == &MCLibraryCapesContext) {
        NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] integerValue];
        [self.tableView beginUpdates];

        if (kind ==  NSKeyValueChangeInsertion || kind == NSKeyValueChangeSetting) {
            
            if (kind == NSKeyValueChangeSetting) {
                self.capes = [NSMutableOrderedSet orderedSet];
            }
                
            for (MCCursorLibrary *lib in change[NSKeyValueChangeNewKey]) {
                NSUInteger index = [self.capes indexForInsertingObject:lib sortedUsingComparator:self.class.sortComparator];
                NSIndexSet *indices = [NSIndexSet indexSetWithIndex:index];
                
                [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"capes"];
                [lib addObserver:self forKeyPath:@"name" options:0 context:(void *)&MCLibraryNameContext];
                [self.capes insertObject:lib atIndex:index];
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"capes"];
                [self.tableView insertRowsAtIndexes:indices withAnimation:NSTableViewAnimationSlideUp];
            }

        } else if (kind ==  NSKeyValueChangeRemoval) {
            for (MCCursorLibrary *lib in change[NSKeyValueChangeOldKey]) {
                NSUInteger index = [self.capes indexOfObject:lib];
                NSIndexSet *indices = [NSIndexSet indexSetWithIndex:index];
                [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indices forKey:@"capes"];
                [lib removeObserver:self forKeyPath:@"name" context:(void *)&MCLibraryNameContext];
                [self.capes removeObjectAtIndex:index];
                [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indices forKey:@"capes"];
                
                [self.tableView removeRowsAtIndexes:indices withAnimation:NSTableViewAnimationSlideUp | NSTableViewAnimationEffectFade];

                if (self.editWindowController.cursorLibrary == lib) {
                    self.editWindowController.cursorLibrary = nil;
                    [self.editWindowController close];
                }
            }
        }
        
        [self.tableView endUpdates];

    } else if (context == &MCLibraryNameContext) {
        // Reoder it
        MCCursorLibrary *cape = object;
        NSUInteger oldIndex = [self.capes indexOfObject:cape];
        if (oldIndex != NSNotFound) {
            [self.capes removeObjectAtIndex:oldIndex];
            NSUInteger newIndex = [self.capes indexForInsertingObject:cape sortedUsingComparator:self.class.sortComparator];
            [self.capes insertObject:cape atIndex:newIndex];
            [self.tableView moveRowAtIndex:oldIndex toIndex:newIndex];
        }
    } else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];

}

- (void)doubleClick:(NSTableView *)sender {
    NSUInteger row = sender.clickedRow;
    MCCursorLibrary *library = [[sender viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
    if ([[NSUserDefaults standardUserDefaults] integerForKey:MCPreferencesDoubleActionKey] == 0)
        [self.libraryController applyCape:library];
    else {
        [self editCape:library];
    }
}

#pragma mark - Editing

+ (NSSet *)keyPathsForValuesAffectingEditingCape {
    return [NSSet setWithObject:@"editWindowController.cursorLibrary"];
}

- (MCCursorLibrary *)selectedCape {
    return [[self.tableView viewAtColumn:0 row:self.tableView.selectedRow makeIfNecessary:NO] objectValue];
}

- (MCCursorLibrary *)clickedCape {
    return [[self.tableView viewAtColumn:0 row:self.tableView.clickedRow makeIfNecessary:NO] objectValue];
}

- (MCCursorLibrary *)editingCape {
    return self.editWindowController.cursorLibrary;
}

- (void)editCape:(MCCursorLibrary *)library {
    if (!library)
        return;
    
    if (!self.editWindowController) {
        self.editWindowController = [[MCEditWindowController alloc] initWithWindowNibName:@"Edit"];
        [self.editWindowController loadWindow];
    }
    self.editWindowController.cursorLibrary = library;
    [self.editWindowController showWindow:self];
}

#pragma mark - NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.capes.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return self.capes[row];
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    MCCapeCellView *cellView = (MCCapeCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    cellView.appliedImageView.hidden = !([self.capes objectAtIndex:row] == self.libraryController.appliedCape);
    return cellView;
}

//- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
//    return nil;
//}

@end
