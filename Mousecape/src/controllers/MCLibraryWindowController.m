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

@interface MCLibraryWindowController ()
@property (copy) NSURL *libraryURL;
@property (nonatomic, strong, readwrite) NSMutableOrderedSet *documents;
@property (strong) NSArray *librarySortDescriptors;
- (void)composeAccessory;
- (void)_setupFacade;
@end


@implementation MCLibraryWindowController

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        self.documents = [NSMutableOrderedSet orderedSet];
        self.librarySortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
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
        
        // -loadLibraryAtURL: sends updates on how far it is in loading the library, we want the completed signal
        return [self loadLibraryAtURL:[NSURL fileURLWithPath:capesPath]];
        
    }] subscribeNext:^(RACSignal *loadSignal) {
        [[loadSignal deliverOn:[RACScheduler mainThreadScheduler]] subscribeCompleted:^{
            
            @strongify(self);
            [self.window.contentView setNeedsLayout:YES];
            
            NSString *appliedIdentifier = [NSUserDefaults.standardUserDefaults stringForKey:MCPreferencesAppliedCursorKey];
            MCCursorDocument *applied   = [self libraryWithIdentifier:appliedIdentifier];
            self.appliedCursor = applied;
            
            // Set original selection
            self.currentCursor = [self.documents objectAtIndex:self.libraryController.tableView.selectedRow];
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
    
    @weakify(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @strongify(self);
        self.libraryURL = url;
    
        NSFileManager *manager = [NSFileManager defaultManager];
        BOOL isDir;
        BOOL exists = [manager fileExistsAtPath:url.path isDirectory:&isDir];
        
        if (!exists || !isDir) {
            NSLog(@"Invalid library path");
            return;
        }
        
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
            
            // Make the document send the notification where we will add it
            [doc makeWindowControllers];
            [subject sendNext:doc];
        }
        
        [subject sendCompleted];
    });
    
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

- (void)addDocument:(MCCursorDocument *)doc {
    if ([self.documents containsObject:doc])
        return;
    if ([self libraryWithIdentifier:doc.library.identifier])
        return;
    
    if (!doc.fileURL) {
        doc.fileURL = [[self.libraryURL URLByAppendingPathComponent:doc.library.identifier] URLByAppendingPathExtension:@"cape"];
        [doc saveDocument:self];
    } else if (![[doc.fileURL URLByDeletingLastPathComponent].path isEqualToString:self.libraryURL.path]) {
        // If we are importing a cape, save it to the library and set that document to the curren tone
        [doc saveToURL:[self.libraryURL URLByAppendingPathComponent:doc.fileURL.lastPathComponent] ofType:@"cape" forSaveOperation:NSSaveAsOperation error:nil];
    }
    
    [self.documents addObject:doc];
    [doc addWindowController:self];
    [self.documents sortUsingDescriptors:self.librarySortDescriptors];
    
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        [self.libraryController.tableView reloadData];
    });
}

- (void)removeDocument:(MCCursorDocument *)document {
    if (![self.documents containsObject:document])
        return;
    
    [document removeWindowController:self];
    [self.document removeObject:document];
}

- (MCCursorDocument *)document {
    return self.currentCursor;
}

- (void)capeAction:(MCCursorDocument *)cape {    
    NSInteger clickedRow = self.libraryController.tableView.clickedRow;
    if (clickedRow == -1 || !cape)
        return;
    
    BOOL shouldApply = [NSUserDefaults.standardUserDefaults integerForKey:MCPreferencesAppliedClickActionKey] == 0;
    
    if (shouldApply) {
        [cape apply:self];
    } else {
        [cape edit:self];
    }
}

- (IBAction)restoreDefaults:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[MCCloakController sharedCloakController] restoreDefaults];
    });
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification*) notification {
    NSWindow *window = self.window;
    if (notification.object != window) {
        return;
    }
    
    // let's keep a reference to ourself and not have us thrown away while we clear out references.
    MCLibraryWindowController *me = self;
    
    // detach the view controllers from the document first
    self.currentCursor = nil;
    self.appliedCursor = nil;
    
    // disassociate this window controller from the document
    for (NSDocument *doc in me.documents) {
        [doc removeWindowController:me];
    }
    
    [me.documents removeAllObjects];
}

@end
