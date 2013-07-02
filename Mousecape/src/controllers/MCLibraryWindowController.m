//
//  MCLibraryWindowController.m
//  Mousecape
//
//  Created by Alex Zielenski on 6/25/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCLibraryWindowController.h"
#import "NSFileManager+DirectoryLocations.h"
#import "MCCloakController.h"
#import "NSOrderedSet+AZSortedInsert.h"

NSString *MCLibraryDocumentRenamedNotification;

@interface MCLibraryWindowController ()
@property (copy) NSURL *libraryURL;
@property (nonatomic, strong, readwrite) NSMutableOrderedSet *documents;
@property (strong) NSArray *librarySortDescriptors;
- (void)composeAccessory;
- (void)_setupFacade;
@end


@implementation MCLibraryWindowController

+ (void)initialize {
    MCLibraryDocumentRenamedNotification = @"MCLibraryDocumentRenamed";
}

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        self.documents = [NSMutableOrderedSet orderedSet];
        self.librarySortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"library.name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
    }
    
    return self;
}

- (NSString *)windowNibName {
    return @"Library";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self.libraryController.windowController = self;
    
    [self _setupFacade];
    
    @weakify(self);
    
    //!TODO: Release the observers in dealloc
    [[NSNotificationCenter defaultCenter] addObserverForName:MCCloakControllerDidApplyCursorNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      @strongify(self);
                                                      
                                                      MCCursorDocument *obj = note.userInfo[MCCloakControllerAppliedCursorKey];
                                                      if (![obj isKindOfClass:[NSNull class]]) {
                                                          self.appliedCursor = obj;
                                                          [NSUserDefaults.standardUserDefaults setObject:obj.library.identifier forKey:MCPreferencesAppliedCursorKey];
                                                      } else
                                                          self.appliedCursor = nil;
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:MCCloakControllerDidRestoreCursorNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      @strongify(self);
                                                      self.appliedCursor = nil;
                                                  }];
    
    [self composeAccessory];
}

- (void)_setupFacade {
    @weakify(self);
    
    /*
     This code asynchronously loads the library and updates the interface on the main thread when completed.
     */
    RACCommand *loadCommand = [RACCommand command];
    
    [[loadCommand addSignalBlock:^RACSignal *(id sender) {
        @strongify(self);
        NSString *appSupport = [[NSFileManager defaultManager] applicationSupportDirectory];
        NSString *capesPath  = [appSupport stringByAppendingPathComponent:@"capes"];
        
        [[NSFileManager defaultManager] createDirectoryAtPath:capesPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
        [self.libraryController.tableView beginUpdates];
        // -loadLibraryAtURL: sends updates on how far it is in loading the library, we want the completed signal
        return [self loadLibraryAtURL:[NSURL fileURLWithPath:capesPath]];
        
    }] subscribeNext:^(RACSignal *loadSignal) {
        [[loadSignal deliverOn:[RACScheduler mainThreadScheduler]] subscribeCompleted:^{
            @strongify(self);
            [self.window.contentView setNeedsLayout:YES];
            [self.window makeKeyAndOrderFront:self];
            
            NSString *appliedIdentifier = [NSUserDefaults.standardUserDefaults stringForKey:MCPreferencesAppliedCursorKey];
            MCCursorDocument *applied   = [self libraryWithIdentifier:appliedIdentifier];
            self.appliedCursor = applied;
            
            // Set original selection
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                
                // need the update this on the main thread
                [self.libraryController.tableView endUpdates];

                if (self.documents.count) {
                    self.currentCursor = [self.documents objectAtIndex:self.libraryController.tableView.selectedRow != -1 ? self.libraryController.tableView.selectedRow : 0];   
                }
            });

        }];
    }];
    
    [loadCommand execute:self];
    
    RAC(self.accessory.stringValue) = [RACAble(self.appliedCursor.library.name) map:^id(NSString *value) {
        return [NSLocalizedString(@"Applied Cape: ", @"Accessory label for applied cape")stringByAppendingString:value ? value : NSLocalizedString(@"None", @"Accessory label for when no cape is applied")];
    }];
}

- (MCCursorDocument *)libraryWithIdentifier:(NSString *)identifier {
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"library.identifier == %@", identifier];
    NSSet *filtered = [self.documents.set filteredSetUsingPredicate:pred];

    if (filtered.count > 0)
        return filtered.anyObject;
    
    return nil;
}

- (RACReplaySubject *)loadLibraryAtURL:(NSURL *)url {
    RACReplaySubject *subject = [RACReplaySubject subject];
    self.libraryURL = url;
    
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL exists = [manager fileExistsAtPath:url.path isDirectory:&isDir];
    
    if (!exists || !isDir) {
        NSLog(@"Invalid library path");
        return nil;
    }
    
//    @weakify(subject);
//    @weakify(self);
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        @strongify(subject);
//        @strongify(self);
        NSArray *contents = [manager contentsOfDirectoryAtURL:url
                                   includingPropertiesForKeys:nil
                                                      options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                        error:nil];
        for (NSURL *url in contents) {
            if (![url.pathExtension.lowercaseString isEqualToString:@"cape"])
                continue;
            MCCursorDocument *doc = [[MCCursorDocument alloc] initForURL:url
                                                       withContentsOfURL:url
                                                                  ofType:@"cape"
                                                                   error:nil];
            [self addDocument:doc];
            [subject sendNext:doc];
        }
        
        [subject sendCompleted];
//    });
    
    return subject;
}

- (void)composeAccessory {
    NSView *themeFrame = [self.window.contentView superview];
    NSView *accessory = self.accessory.superview;
    [accessory setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSRect c  = themeFrame.frame;
    NSRect aV = accessory.frame;
    NSRect newFrame = NSMakeRect(
                                 c.size.width - aV.size.width,	// x position
                                 c.size.height - aV.size.height,	// y position
                                 aV.size.width,	// width
                                 aV.size.height);	// height
    
    [accessory setFrame:newFrame];
    [themeFrame addSubview:accessory];
    
    [themeFrame addConstraints:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"H:|-(>=100)-[accessory(245)]-(0)-|"
                                options:0
                                metrics:nil
                                views:NSDictionaryOfVariableBindings(accessory)]];
    [themeFrame addConstraints:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"V:|-(0)-[accessory(20)]-(>=22)-|"
                                options:0
                                metrics:nil
                                views:NSDictionaryOfVariableBindings(accessory)]];
}

- (BOOL)addDocument:(MCCursorDocument *)doc {
    if ([self.documents containsObject:doc]) {
        NSLog(@"Cannot add same document twice");
        return NO;
    }
    if ([self libraryWithIdentifier:doc.library.identifier]) {
        NSLog(@"Document exists with that identifier already");
        return NO;
    }
    
    NSUInteger idx = [self.documents indexForInsertingObject:doc sortedUsingDescriptors:self.librarySortDescriptors];
    NSIndexSet *indices = [NSIndexSet indexSetWithIndex:idx];
    
    @weakify(self);
    @weakify(doc);
    [doc rac_addDeallocDisposable:[RACAbleWithStart(doc, library.identifier) subscribeNext:^(NSString *identifier) {
        @strongify(self);
        @strongify(doc);
        NSFileManager *manager = [NSFileManager defaultManager];
        NSURL *expectedURL     = [[self.libraryURL URLByAppendingPathComponent:identifier] URLByAppendingPathExtension:@"cape"];
        BOOL exists            = [manager fileExistsAtPath:doc.fileURL.path];
        
        if (![doc.fileURL isEqualTo:expectedURL] && exists) {
            NSError *err = nil;
            [manager moveItemAtURL:doc.fileURL toURL:expectedURL error:&err];
            
            // If it failed, it's not really a big deal, so do nothing
            if (!err)
                doc.fileURL = expectedURL;
        } else if (!doc.fileURL || !exists) {
            [doc saveToURL:expectedURL ofType:@"cape" forSaveOperation:NSSaveAsOperation error:nil];
        }
        
    }]];
    
    [doc rac_addDeallocDisposable:[RACAble(doc, library.name) subscribeNext:^(NSString *name) {
        @strongify(self);
        @strongify(doc);
        
        NSUInteger newIndex     = [self.documents indexForInsertingObject:doc sortedUsingDescriptors:self.librarySortDescriptors];
        NSUInteger currentIndex = [self.documents indexOfObject:doc];
        
        if (newIndex != currentIndex) {
            [self.documents moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:currentIndex] toIndex:newIndex];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:MCLibraryDocumentRenamedNotification
                                                                object:doc
                                                              userInfo:@{ @"oldIndex": @(currentIndex), @"newIndex": @(newIndex) }];
        }
        
    }]];
    
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"documents"];
    [self.documents insertObject:doc atIndex:idx];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"documents"];
    
//    [(NSDocumentController *)[NSDocumentController sharedDocumentController] addDocument:doc];
    return YES;
}

- (void)removeDocument:(MCCursorDocument *)document {
    if (![self.documents containsObject:document])
        return;
    
    if (self.appliedCursor == document)
        self.appliedCursor = nil;
    
    [document.editWindowController close];
    [document removeWindowController:document.editWindowController];
    [document removeWindowController:self];
    
    [[NSDocumentController sharedDocumentController] removeDocument:document];
    
    NSIndexSet *set = [NSIndexSet indexSetWithIndex:[self.documents indexOfObject:document]];
    
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"documents"];
    [self.documents removeObject:document];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:set forKey:@"documents"];
}

- (MCCursorDocument *)document {
    return self.currentCursor;
}

- (IBAction)restoreDefaults:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[MCCloakController sharedCloakController] restoreDefaults];
    });
}

- (IBAction)importMightyMouse:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.message = @"Choose a Mighty Mouse file to convert";
    panel.allowsMultipleSelection = YES;
    panel.allowedFileTypes = @[@"mightymouse"];
    
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            for (NSURL *url in panel.URLs) {
                NSString *result = [[MCCloakController sharedCloakController] convertMightyMouse:url.path];
                MCCursorDocument *document = [[MCCursorDocument alloc] initForURL:[NSURL fileURLWithPath:result]
                                                                withContentsOfURL:[NSURL fileURLWithPath:result]
                                                                           ofType:@"cape"
                                                                            error:nil];
                [document makeWindowControllers];
            }
        }
    }];
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *) notification {
    NSWindow *window = self.window;
    if (notification.object != window) {
        return;
    }
    
    // let's keep a reference to ourself and not have us thrown away while we clear out references.
    MCLibraryWindowController *me = self;
    
    // detach the view controllers from the document first
    me.currentCursor = nil;
    me.appliedCursor = nil;
    
    // disassociate this window controller from the document
    for (NSDocument *doc in me.documents) {
        [doc removeWindowController:me];
    }

    [me.documents removeAllObjects];
    
    [NSApp terminate:self];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return @"Mousecape";
}

@end
