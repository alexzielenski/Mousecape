//
//  MCLibraryWindowController.h
//  Mousecape
//
//  Created by Alex Zielenski on 6/25/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursorDocument.h"
#import "MCLibraryViewController.h"

extern NSString *MCLibraryDocumentRenamedNotification;

@interface MCLibraryWindowController : NSWindowController <NSWindowDelegate>
@property (assign) IBOutlet MCLibraryViewController *libraryController;
@property (assign) IBOutlet NSTextField *accessory;
@property (weak) MCCursorDocument *currentCursor;
@property (weak) MCCursorDocument *appliedCursor;

- (RACReplaySubject *)loadLibraryAtURL:(NSURL *)url;
- (MCCursorDocument *)libraryWithIdentifier:(NSString *)identifier;

- (BOOL)addDocument:(MCCursorDocument *)document;
- (void)removeDocument:(MCCursorDocument *)document;

// Asks preferences what to do on double click, apply or edit
- (IBAction)restoreDefaults:(id)sender;
- (IBAction)importMightyMouse:(id)sender;
@end

@interface MCLibraryWindowController (Properties)
@property (nonatomic, strong, readonly) NSOrderedSet *documents;
@end
