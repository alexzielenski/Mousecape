//
//  MCLibraryViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCLibraryViewController.h"
#import "MCCursorLibrary.h"

@interface MCLibraryViewController ()
@property (readwrite, strong) NSMutableArray *libraries;
@property (copy) NSString *libraryPath;
// KVO
- (void)insertObject:(MCCursorLibrary *)library inLibrariesAtIndex:(NSUInteger)index;
- (void)removeObjectFromLibrariesAtIndex:(NSUInteger)index;

@end

@implementation MCLibraryViewController

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        self.libraries = [NSMutableArray array];
    }
    return self;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.libraries = [NSMutableArray array];
    }
    
    return self;
}
- (void)loadLibraryAtPath:(NSString *)path {
    self.libraryPath = path;
    
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL exists = [manager fileExistsAtPath:path isDirectory:&isDir];
    
    if (!exists || !isDir) {
        NSLog(@"Invalid library path");
        return;
    }
    
    NSArray *contents = [manager contentsOfDirectoryAtPath:path error:nil];
    for (NSString *fileName in contents) {
        if (![fileName.pathExtension.lowercaseString isEqualToString:@"cape"])
            continue;
        
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        MCCursorLibrary *library = [MCCursorLibrary cursorLibraryWithContentsOfFile:filePath];
        if (library) {
//            library.name = [fileName stringByDeletingPathExtension];
            [self addLibrary:library];
        }
    }
  
    [self.tableView reloadData];

}
- (NSError *)addToLibrary:(NSString *)path {
    NSError *error = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *destinationPath = [self.libraryPath stringByAppendingPathComponent:path.lastPathComponent];
    [manager copyItemAtPath:path toPath:destinationPath error:&error];
    
    if (error != nil) {
        return error;
    }
    
    // cursor has been copied. load it into our library now
    MCCursorLibrary *library = [MCCursorLibrary cursorLibraryWithContentsOfFile:destinationPath];
    if (library)
        [self addLibrary:library];
    
    else {
        [manager removeItemAtPath:destinationPath error:nil];
        return [NSError errorWithDomain:@"com.alexzielenski.mousecape.errordomain" code:1 userInfo:@{NSLocalizedDescriptionKey : @"Invalid cursor file"}];
    }
    
    [self.tableView reloadData];
    
    return nil;
    
}
- (void)addLibrary:(MCCursorLibrary *)library {
    [self insertObject:library inLibrariesAtIndex:self.libraries.count];
}
- (void)insertLibrary:(MCCursorLibrary *)library atIndex:(NSUInteger)index {
    [self insertObject:library inLibrariesAtIndex:index];
}
- (void)removeLibrary:(MCCursorLibrary *)library {
    NSUInteger libraryIndex = [self.libraries indexOfObject:library];
    if (libraryIndex != NSNotFound)
        [self removeObjectFromLibrariesAtIndex:libraryIndex];
}
- (void)removeLibraryAtIndex:(NSUInteger)index {
    [self removeObjectFromLibrariesAtIndex:index];
}
- (void)insertObject:(MCCursorLibrary *)library inLibrariesAtIndex:(NSUInteger)index {
    if (index <= self.libraries.count)
        [self.libraries insertObject:library atIndex:index];
}
- (void)removeObjectFromLibrariesAtIndex:(NSUInteger)index {
    if (index < self.libraries.count)
        [self.libraries removeObjectAtIndex:index];
}

#pragma mark - NSTableViewDelgate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    return cellView;
}
- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return nil;
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.tableView.selectedRow == -1)
        self.selectedLibrary = nil;
    else {
        MCCursorLibrary *selectedLibrary = [self.libraries objectAtIndex:self.tableView.selectedRow];
        self.selectedLibrary = selectedLibrary;
    }
}

#pragma mark - NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.libraries.count;
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [self.libraries objectAtIndex:rowIndex];
}

@end
