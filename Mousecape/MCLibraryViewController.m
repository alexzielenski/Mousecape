//
//  MCLibraryViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCLibraryViewController.h"
#import "MCCursorLibrary.h"
#import "MCTableCellView.h"
#import "NSArray+CWSortedInsert.h"
#import "MCCloakController.h"

static NSArray *librarySortDescriptors =  nil;

@interface MCLibraryViewController ()
@property (readwrite, strong) NSMutableArray *libraries;
@property (copy) NSString *libraryPath;
@property (strong) RACSignal *_appliedSignal;
- (void)_init;
// KVO
- (void)insertObject:(MCCursorLibrary *)library inLibrariesAtIndex:(NSUInteger)index;
- (void)removeObjectFromLibrariesAtIndex:(NSUInteger)index;

- (void)sidekickAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)confirmationAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@implementation MCLibraryViewController
+ (void)initialize {
    [super initialize];
    
    librarySortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    
}

- (void)_init {
    self.libraries = [NSMutableArray array];
    
    __weak MCLibraryViewController *weakSelf = self;
    [RACAble(self.appliedLibrary.name) subscribeNext:^(NSString *value) {
        NSString *appliedCape = NSLocalizedString(@"Applied Cape: ", @"Accessory label for applied cape");
        weakSelf.appliedCursorField.stringValue = [appliedCape stringByAppendingString:value ? value : NSLocalizedString(@"None", @"Accessory label for when no cape is applied")];
    }];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self _init];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _init];
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
            [self addLibrary:library];
        }
    }
  
    [self.tableView reloadData];
}

#pragma mark - Library Management
- (NSError *)addToLibrary:(NSString *)path {
    MCCursorLibrary *library = [MCCursorLibrary cursorLibraryWithContentsOfFile:path];
    
    NSError *error = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *destinationPath = [[self.libraryPath stringByAppendingPathComponent:library.identifier] stringByAppendingPathExtension:@"cape"];
    [manager copyItemAtPath:path toPath:destinationPath error:&error];
    
    if (error != nil) {
        return error;
    }
    
    // cursor has been copied. load it into our library now
    [library setValue:[NSURL fileURLWithPath:destinationPath] forKey:@"originalURL"];
    
    if (library)
        [self addLibrary:library];
    
    else {
        [manager removeItemAtPath:destinationPath error:nil];
        return [NSError errorWithDomain:@"com.alexzielenski.mousecape.errordomain" code:1 userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Invalid cursor file (%@)", path]}];
    }
    
    NSUInteger idx = [self.libraries indexOfObject:library];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:idx] withAnimation:NSTableViewAnimationSlideDown];
    [self.tableView endUpdates];
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx, 1)] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    
    return nil;
    
}

- (NSError *)removeFromLibrary:(MCCursorLibrary *)library {
    if (![self.libraries containsObject:library])
        return [NSError errorWithDomain:@"com.alexzielenski.mousecape.errordomain" code:2 userInfo:@{NSLocalizedDescriptionKey : @"Library is not a member of this controller"}];
    
    NSError *error = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtURL:library.originalURL error:&error];
    
    if (error != nil) {
        return error;
    }
    
    [self removeLibrary:library];
    
    return nil;
}

- (void)addLibrary:(MCCursorLibrary *)library {
    if ([[self.libraries valueForKeyPath:@"identifier"] containsObject:library.identifier]) {
        NSLog(@"A library with the identifier %@ already exists", library.identifier);
        return;
    }
    
    if (!library.identifier) {
        NSLog(@"Library must contain an identifier");
        return;
    }
    
    [self.libraries insertObject:library sortedUsingDescriptors:librarySortDescriptors];
}

- (void)removeLibrary:(MCCursorLibrary *)library {
    NSUInteger libraryIndex = [self.libraries indexOfObject:library];
    if (libraryIndex != NSNotFound) {
        [self removeObjectFromLibrariesAtIndex:libraryIndex];
    }
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

- (MCCursorLibrary *)libraryWithIdentifier:(NSString *)identifier {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSArray *filtered = [self.libraries filteredArrayUsingPredicate:pred];
    
    if (filtered.count > 0)
        return filtered[0];
    
    return nil;
}

#pragma mark - Interface Actions
- (IBAction)createSidekick:(id)sender {
    
    NSMutableDictionary *selectedCursors = [NSMutableDictionary dictionary];
    
    for (NSUInteger idx = 0; idx < self.tableView.numberOfRows; idx++) {
        MCTableCellView *cellView = [self.tableView viewAtColumn:0 row:idx makeIfNecessary:NO];
        MCCursorLine *line = cellView.cursorLine;
        
        __block MCCursorLibrary *objectValue = (MCCursorLibrary *)cellView.objectValue;
        [line.selectedCursorIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            MCCursor *selectedCursor = [line.dataSource cursorLine:line cursorAtIndex:idx];
            selectedCursors[[objectValue identifierForCursor:selectedCursor]] = selectedCursor;
        }];
        
    }
    
    if (selectedCursors.count == 0) {
        NSBeginAlertSheet(@"Oops!", @"Sorry, boss", nil, nil, self.view.window, nil, NULL, NULL, nil, @"You did not select individual cursors to add to your sidekick?");
        return;
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Almost done"
                                     defaultButton:@"Create Sidekick"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@"Input a name for your Sidekick:"];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    alert.accessoryView = input;
    
    [alert beginSheetModalForWindow:self.view.window
                      modalDelegate:self
                     didEndSelector:@selector(sidekickAlertDidEnd:returnCode:contextInfo:)
                        contextInfo:(__bridge_retained void *)selectedCursors];
    
}

- (void)sidekickAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSDictionary *cursors = (__bridge_transfer NSDictionary *)(contextInfo);
        NSString *name = [(NSTextField *)alert.accessoryView stringValue];
        
        if (name.length == 0) {
            [alert.window orderOut:alert];
            NSBeginAlertSheet(@"Oops!", @"Sorry, boss", nil, nil, self.view.window, nil, NULL, NULL, nil, @"You did not specify a name for your sidekick");
            return;
        }
        
        
        MCCursorLibrary *library = [MCCursorLibrary cursorLibraryWithCursors:cursors];
        library.version    = @1.0;
        library.author     = NSUserName();
        library.identifier = [NSString stringWithFormat:@"%@.%@.sidekick.%@", NSBundle.mainBundle.bundleIdentifier, library.author, [NSProcessInfo.processInfo globallyUniqueString]];
        library.name       = name;

        NSArray *filteredCounts = [[library.cursors.allValues valueForKeyPath:@"representations"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSArray *evaluatedObject, NSDictionary *bindings) {
            return evaluatedObject.count > 1;
        }]];
        
        library.hiDPI      = filteredCounts.count == library.cursors.count;
        
        NSString *path = [[self.libraryPath stringByAppendingPathComponent:library.identifier] stringByAppendingPathExtension:@"cape"];
        if ([library writeToFile:path atomically:NO]) {
            [library setValue:[NSURL fileURLWithPath:path] forKey:@"originalURL"];
            [self addLibrary:library];
            
            [self.tableView reloadData];
        } else {
            
        }
        
    }
}

- (IBAction)removeCape:(id)sender {
    //!TODO: Disable this menu item and call this for the MCEditListViewController if that window is active
    
    if (self.tableView.selectedRow == -1)
        return;
    
    NSAlert *sureAlert = [NSAlert alertWithMessageText:@"Are you sure?"
                                         defaultButton:@"Positive"
                                       alternateButton:@"Nevermind"
                                           otherButton:nil
                             informativeTextWithFormat:@"This operation cannot be undone"];
    sureAlert.showsSuppressionButton = !MCFlag(MCSuppressDeleteLibraryConfirmationKey);
    [sureAlert beginSheetModalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(confirmationAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)confirmationAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSUInteger row = (self.tableView.clickedRow != -1) ? self.tableView.clickedRow : self.tableView.selectedRow;
        
        MCCursorLibrary *selectedLibrary = [[self.tableView viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
        [self removeFromLibrary:selectedLibrary];
        
        MCSetFlag(alert.suppressionButton.state == NSOnState, MCSuppressDeleteLibraryConfirmationKey);
        
        [self.tableView beginUpdates];
        [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row] withAnimation:NSTableViewAnimationEffectFade];
        [self.tableView endUpdates];
        
        [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];

    }
}

- (IBAction)importMightyMouse:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[ @"MightyMouse" ];
    openPanel.message = @"Select a MightyMouse file to convert";
    openPanel.prompt = @"Import";
    openPanel.allowsOtherFileTypes = NO;
    openPanel.allowsMultipleSelection = YES;
    
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            for (NSURL *url in openPanel.URLs) {
                MCCloakController *clk = [MCCloakController sharedCloakController];
                
                NSString *outPath = [clk convertMightyMouse:url.path];
                [self addToLibrary:outPath];
            }
        }
    }];
}

- (IBAction)importCape:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowedFileTypes = @[ @"cape" ];
    openPanel.message = @"Select a Cape file to add";
    openPanel.prompt = @"Import Cape";
    openPanel.allowsOtherFileTypes = NO;
    openPanel.allowsMultipleSelection = YES;
    
    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            for (NSURL *url in openPanel.URLs) {
                [self addToLibrary:url.path];
            }
        }
    }];
}

#pragma mark - NSTableViewDelgate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    MCTableCellView *cellView = (MCTableCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    [cellView.cursorLine bind:@"animationsEnabled" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"MCAnimationsEnabled" options:nil];
    if (![cellView rac_propertyForKeyPath:@"applied"])
        RAC(cellView, applied) = [RACSignal combineLatest:@[
                                                            RACAbleWithStart(cellView, objectValue),
                                                            RACAble(self.appliedLibrary)
                                                            ]
                                                   reduce:^(id objectValue, MCCursorLibrary *appliedLib) {
                                                       return @(objectValue == appliedLib);
                                                   }];
    
    return cellView;
}
- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return nil;
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.tableView.selectedRow == -1)
        self.selectedLibrary = nil;
    else {
        MCCursorLibrary *selectedLibrary = [[self.tableView viewAtColumn:0 row:self.tableView.selectedRow makeIfNecessary:NO] objectValue];
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
