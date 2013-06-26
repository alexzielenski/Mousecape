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
#import "MCEditWindowController.h"

@interface MCLibraryWindowController ()
@property (nonatomic, strong, readwrite) NSMutableOrderedSet *documents;
//@property (strong) MCEditWindowController *editWindowController;
@property (strong) NSArray *librarySortDescriptors;
- (void)composeAccessory;

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
    self.detailController.windowController  = self;
    
    NSString *appSupport = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *capesPath  = [appSupport stringByAppendingPathComponent:@"capes"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:capesPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    [self.libraryController loadLibraryAtPath:capesPath];

    [self.window.contentView setNeedsLayout:YES];

    
    NSString *appliedIdentifier = [NSUserDefaults.standardUserDefaults stringForKey:MCPreferencesAppliedCursorKey];
    MCCursorDocument *applied   = [self.libraryController libraryWithIdentifier:appliedIdentifier];
    self.appliedCursor = applied;
    
    @weakify(self);
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
    
    [self.documents addObject:doc];
//    [doc addWindowController:self];
    [self.documents sortUsingDescriptors:self.librarySortDescriptors];
    
    [self.libraryController.tableView reloadData];
}

- (void)removeDocument:(MCCursorDocument *)document {
    if (![self.documents containsObject:document])
        return;
    
    [document removeWindowController:self];
    [self.document removeObject:document];
}

- (MCCursorDocument *)document {
    return nil;
}

- (void)capeAction:(MCCursorDocument *)cape {    
    NSInteger clickedRow = self.libraryController.tableView.clickedRow;
    if (clickedRow == -1 || !cape)
        return;
    
    BOOL shouldApply = [NSUserDefaults.standardUserDefaults integerForKey:MCPreferencesAppliedClickActionKey] == 0;
    
    if (shouldApply) {
        [self applyCape:cape];
    } else {
        [self editCape:cape];
    }
}

- (void)applyCape:(MCCursorDocument *)cape {
    if (!cape)
        return;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[MCCloakController sharedCloakController] applyCape:cape];
    });
}

- (void)editCape:(MCCursorDocument *)cape {
    if (!cape)
        return;
    
    if (!cape.editWindowController)
        cape.editWindowController = [[MCEditWindowController alloc] initWithWindowNibName:@"EditWindow"];
    
    [cape addWindowController:cape.editWindowController];
    [[NSDocumentController sharedDocumentController] addDocument:cape];
    [cape showWindows];
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
