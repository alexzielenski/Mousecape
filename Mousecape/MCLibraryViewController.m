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
#import "MCLibraryWindowController.h"

@interface MCLibraryViewController ()
@property (copy) NSString *libraryPath;
@property (strong) RACSignal *_appliedSignal;
- (void)_init;
- (void)sidekickAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)confirmationAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end

@implementation MCLibraryViewController
- (void)awakeFromNib {
    self.tableView.target = self;
    self.tableView.doubleAction = @selector(doubleClick:);
}

- (void)_init {    
    @weakify(self);
    [RACAble(self.windowController.appliedCursor.library.name) subscribeNext:^(NSString *value) {
        @strongify(self);
        NSString *appliedCape = NSLocalizedString(@"Applied Cape: ", @"Accessory label for applied cape");
        self.appliedCursorField.stringValue = [appliedCape stringByAppendingString:value ? value : NSLocalizedString(@"None", @"Accessory label for when no cape is applied")];
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
        NSURL *url = [NSURL fileURLWithPath:filePath];
        MCCursorDocument *document = [[MCCursorDocument alloc] initForURL:url
                                                        withContentsOfURL:url
                                                                   ofType:@"cape"
                                                                    error:nil];
        
        if (document) {
            [self addLibrary:document];
        }
    }
  
    [self.tableView reloadData];
}

#pragma mark - Library Management
- (NSError *)addToLibrary:(NSString *)path {
    if ([path.pathExtension.lowercaseString isEqualToString:@"cape"])
        return [NSError errorWithDomain:@"com.alexzielenski.mousecape.errordomain" code:3 userInfo:@{ NSLocalizedDescriptionKey: @"This is not a cursor document." }];
    
    NSError *error = nil;

    MCCursorDocument *document = [[MCCursorDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] ofType:@"cape" error:&error];
    if (error)
        return error;
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *destinationPath = [[self.libraryPath stringByAppendingPathComponent:document.library.identifier] stringByAppendingPathExtension:@"cape"];
    [manager copyItemAtPath:path toPath:destinationPath error:&error];
    
    if (error != nil) {
        return error;
    }
    
    document.fileURL = [NSURL fileURLWithPath:destinationPath];
    
    [self addLibrary:document];
    
    NSUInteger idx = [self.windowController.documents indexOfObject:document];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:idx] withAnimation:NSTableViewAnimationSlideDown];
    [self.tableView endUpdates];
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(idx, 1)] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    
    return nil;
    
}

- (NSError *)removeFromLibrary:(MCCursorDocument *)library {
    if (![self.windowController.documents containsObject:library])
        return [NSError errorWithDomain:@"com.alexzielenski.mousecape.errordomain" code:2 userInfo:@{NSLocalizedDescriptionKey : @"Library is not a member of this controller"}];
    
    NSError *error = nil;
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager removeItemAtURL:library.fileURL error:&error];
    
    if (error != nil) {
        return error;
    }
    
    [self removeLibrary:library];
    
    return nil;
}

- (void)addLibrary:(MCCursorDocument *)library {
    if ([[self.windowController.documents valueForKeyPath:@"library.identifier"] containsObject:library.library.identifier]) {
        NSLog(@"A library with the identifier %@ already exists", library.library.identifier);
        return;
    }
    
    if (!library.library.identifier) {
        NSLog(@"Library must contain an identifier");
        return;
    }
    
    [self.windowController addDocument:library];
}

- (void)removeLibrary:(MCCursorDocument *)library {
    [self.windowController removeDocument:library];
}

- (MCCursorDocument *)libraryWithIdentifier:(NSString *)identifier {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"library.identifier == %@", identifier];
    NSSet *filtered = [self.windowController.documents.set filteredSetUsingPredicate:pred];
    
    if (filtered.count > 0)
        return filtered.anyObject;
    
    return nil;
}

#pragma mark - Interface Actions
- (IBAction)createSidekick:(id)sender {
    
    NSMutableDictionary *selectedCursors = [NSMutableDictionary dictionary];
    
    for (NSUInteger idx = 0; idx < self.tableView.numberOfRows; idx++) {
        MCTableCellView *cellView = [self.tableView viewAtColumn:0 row:idx makeIfNecessary:NO];
        MCCursorLine *line = cellView.cursorLine;
        
        __weak MCCursorDocument *objectValue = (MCCursorDocument *)cellView.objectValue;
        [line.selectedCursorIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            MCCursor *selectedCursor = [line.dataSource cursorLine:line cursorAtIndex:idx];
            selectedCursors[[objectValue.library identifierForCursor:selectedCursor]] = selectedCursor;
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
            MCCursorDocument *document = [[MCCursorDocument alloc] initWithType:@"cape" error:nil];
            document.library = library;
            document.fileURL = [NSURL fileURLWithPath:path];
            [self addLibrary:document];
            
            [self.tableView reloadData];
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
        
        MCCursorDocument *selectedLibrary = [[self.tableView viewAtColumn:0 row:row makeIfNecessary:NO] objectValue];
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

- (void)doubleClick:(id)sender {
    [self.windowController capeAction:self.windowController.currentCursor];
}

#pragma mark - NSTableViewDelgate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    MCTableCellView *cellView = (MCTableCellView *)[tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    [cellView.cursorLine bind:@"animationsEnabled" toObject:[NSUserDefaults standardUserDefaults] withKeyPath:@"MCAnimationsEnabled" options:nil];

    @weakify(self);

    if (!cellView.appliedDisposable) {
        RACDisposable *binding = [[[RACSignal combineLatest:@[
                                                             RACAble(cellView, objectValue),
                                                             RACAble(self.windowController, appliedCursor)
                                                             ]
                                                    reduce:^(id objectValue, MCCursorLibrary *appliedLib) {
                                                        @strongify(self);
                                                        return @(objectValue == self.windowController.appliedCursor);
                                                    }] deliverOn:[RACScheduler mainThreadScheduler]] toProperty:@"applied" onObject:cellView];
        cellView.appliedDisposable = binding;
    }
    cellView.applied = [self tableView:tableView objectValueForTableColumn:tableColumn row:row] == self.windowController.appliedCursor;
    
    return cellView;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.tableView.selectedRow == -1)
        self.windowController.currentCursor = nil;
    else {
        MCCursorDocument *selectedLibrary = [[self.tableView viewAtColumn:0 row:self.tableView.selectedRow makeIfNecessary:NO] objectValue];
        self.windowController.currentCursor = selectedLibrary;
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.windowController.documents count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    return [self.windowController.documents objectAtIndex:rowIndex];
}

@end
