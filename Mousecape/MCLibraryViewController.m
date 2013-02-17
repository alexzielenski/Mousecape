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

static const NSString *MCAppliedCursorValueTransformerName = @"mousecape.appliedCursorTransformer";
static NSArray *librarySortDescriptors =  nil;

@interface MCAppliedCursorValueTransformer : NSValueTransformer
@end

@implementation MCAppliedCursorValueTransformer
+ (BOOL)allowsReverseTransformation {
    return NO;
}
+ (Class)transformedValueClass {
    return [NSString class];
}
- (NSString *)transformedValue:(NSString *)value {
    NSString *appliedCape = NSLocalizedString(@"Applied Cape: ", @"Accessory label for applied cape");
    return [appliedCape stringByAppendingString:value ? value : NSLocalizedString(@"None", @"Accessory label for when no cape is applied")];
}
@end

@interface MCLibraryViewController ()
@property (readwrite, strong) NSMutableArray *libraries;
@property (copy) NSString *libraryPath;
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
    
    MCAppliedCursorValueTransformer *trns = [[MCAppliedCursorValueTransformer alloc] init];
    [NSValueTransformer setValueTransformer:trns forName: (NSString *)MCAppliedCursorValueTransformerName];
    
}
- (void)_init {
    self.libraries = [NSMutableArray array];
    [self addObserver:self forKeyPath:@"appliedLibrary" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"appliedCursorField" options:NSKeyValueObservingOptionOld context:nil];
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
- (void)loadView {
    [super loadView];
}
- (void)dealloc {
    [self removeObserver:self forKeyPath:@"appliedLibrary"];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"appliedLibrary"]) {
        MCCursorLibrary *oldLib = change[NSKeyValueChangeOldKey];
        if (oldLib && ![oldLib isKindOfClass:[NSNull class]])
            oldLib.applied = NO;
        
        self.appliedLibrary.applied = YES;
    } else if ([keyPath isEqualToString:@"appliedCursorField"]) {
        NSTextField *oldField = change[NSKeyValueChangeOldKey];
        [oldField unbind:@"value"];

        [self.appliedCursorField bind:@"value" toObject:self withKeyPath:@"appliedLibrary.name" options:@{ NSValueTransformerNameBindingOption: MCAppliedCursorValueTransformerName }];
    }
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
    NSError *error = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *destinationPath = [[self.libraryPath stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] stringByAppendingPathExtension:@"cape"];
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
            NSBeginAlertSheet(@"Oops!", @"Sorry, boss", nil, nil, self.view.window, nil, NULL, NULL, nil, @"You did not specify a name for your sidekick");
            return;
        }
        
        MCCursorLibrary *library = [MCCursorLibrary cursorLibraryWithCursors:cursors];
        library.version    = @1.0;
        library.author     = NSUserName();
        library.identifier = [NSString stringWithFormat:@"com.mousecape.%@.sidekick.%@", library.author, name];
        library.name       = name;
        
        NSString *path = [[self.libraryPath stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"cape"];
        if ([library writeToFile:path atomically:NO]) {
            [library setValue:[NSURL fileURLWithPath:path] forKey:@"originalURL"];
            [self addLibrary:library];
            
            [self.tableView reloadData];
        } else {
            
        }
        
    }
}
- (IBAction)removeCape:(id)sender {
    if (self.tableView.selectedRow == -1)
        return;
    
    NSBeginAlertSheet(@"Are you sure?", @"Positive", @"Nevermind", nil, self.view.window, self, NULL, @selector(confirmationAlertDidEnd:returnCode:contextInfo:), NULL, @"This operation cannot be undone.");
}
- (void)confirmationAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        NSUInteger row = (self.tableView.clickedRow != -1) ? self.tableView.clickedRow : self.tableView.selectedRow;
        
        MCCursorLibrary *selectedLibrary = [[self.tableView viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
        [self removeFromLibrary:selectedLibrary];
        
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

#pragma mark - NSTableViewDelgate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    MCTableCellView *cellView = (MCTableCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        
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
