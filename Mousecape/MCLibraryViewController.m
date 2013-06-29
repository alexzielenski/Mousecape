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
#import "MCCloakController.h"
#import "MCLibraryWindowController.h"

@interface MCLibraryViewController ()
- (void)startWatchingWindowController:(MCLibraryWindowController *)ctrl;
- (void)stopWatchingWindowController:(MCLibraryWindowController *)ctrl;
@end

@implementation MCLibraryViewController
- (void)awakeFromNib {
    self.tableView.target = self;
    self.tableView.doubleAction = @selector(doubleClick:);
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self rac_addDeallocDisposable:[[RACAble(self.windowController) mapPreviousWithStart:nil
                                                     combine:^id(id previous, id current) {
                                                         NSMutableDictionary *dict = [NSMutableDictionary dictionary];
                                                         if (previous)
                                                             dict[@"previous"] = previous;
                                                         if (current)
                                                             dict[@"current"] = current;
                                                         return dict;
                                                         
                                                     }] subscribeNext:^(NSDictionary *x) {
                                                         if ([x objectForKey:@"previous"])
                                                             [self stopWatchingWindowController:[x objectForKey:@"previous"]];
                                                         if ([x objectForKey:@"current"])
                                                             [self startWatchingWindowController:[x objectForKey:@"current"]];
                                                     }]];
    }
    
    return self;
}

static void *MCDocumentsContext;
- (void)startWatchingWindowController:(MCLibraryWindowController *)ctrl {
    [ctrl addObserver:self forKeyPath:@"documents" options:NSKeyValueObservingOptionNew context:&MCDocumentsContext];
}
- (void)stopWatchingWindowController:(MCLibraryWindowController *)ctrl {
    [ctrl removeObserver:self forKeyPath:@"documents"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != &MCDocumentsContext)
        return;
    
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        NSUInteger kind     = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        NSIndexSet *indices = change[NSKeyValueChangeIndexesKey];
        
        if (kind == NSKeyValueChangeInsertion)
            [self.tableView insertRowsAtIndexes:indices withAnimation:NSTableViewAnimationEffectGap];
        else if (kind == NSKeyValueChangeRemoval)
            [self.tableView removeRowsAtIndexes:indices withAnimation:NSTableViewAnimationEffectFade];
        
    });    
}

#pragma mark - Interface Actions
- (IBAction)contextMenu:(NSMenuItem *)sender {
    MCCursorDocument *clickedDocument = [self.windowController.documents objectAtIndex:self.tableView.clickedRow];
    switch (sender.tag) {
        case 0: { // Apply
            [clickedDocument apply:sender];
            break;
        }
        case 1: { // Edit
            [clickedDocument edit:sender];
            break;
        }
        case 2: { // Duplicate
            [clickedDocument duplicateDocument:sender];
            break;
        }
        case 3: { // Remove
            [clickedDocument remove:sender];
        }
        default:
            break;
    }
}

//- (IBAction)importMightyMouse:(id)sender {
//    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//    openPanel.allowedFileTypes = @[ @"MightyMouse" ];
//    openPanel.message = @"Select a MightyMouse file to convert";
//    openPanel.prompt = @"Import";
//    openPanel.allowsOtherFileTypes = NO;
//    openPanel.allowsMultipleSelection = YES;
//    
//    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSInteger result) {
//        if (result == NSOKButton) {
//            for (NSURL *url in openPanel.URLs) {
//                MCCloakController *clk = [MCCloakController sharedCloakController];
//                
//                NSString *outPath = [clk convertMightyMouse:url.path];
//                [self addToLibrary:outPath];
//            }
//        }
//    }];
//}

- (void)capeAction:(MCCursorDocument *)cape {
    NSInteger clickedRow = self.tableView.clickedRow;
    if (clickedRow == -1 || !cape)
        return;
    
    BOOL shouldApply = [NSUserDefaults.standardUserDefaults integerForKey:MCPreferencesAppliedClickActionKey] == 0;
    
    if (shouldApply) {
        [cape apply:self];
    } else {
        [cape edit:self];
    }
}


- (void)doubleClick:(id)sender {
    [self capeAction:self.windowController.currentCursor];
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
