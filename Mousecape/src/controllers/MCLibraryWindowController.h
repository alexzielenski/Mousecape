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
#import "MCDetailVewController.h"

@interface MCLibraryWindowController : NSWindowController
@property (assign) IBOutlet MCLibraryViewController *libraryController;
@property (assign) IBOutlet MCDetailVewController *detailController;
@property (assign) IBOutlet NSTextField *accessory;
@property (weak) MCCursorDocument *currentCursor;
@property (weak) MCCursorDocument *appliedCursor;

- (void)addDocument:(MCCursorDocument *)document;
- (void)removeDocument:(MCCursorDocument *)document;
- (void)capeAction:(MCCursorDocument *)cape;
- (void)editCape:(MCCursorDocument *)cape;

@end

@interface MCLibraryWindowController (Properties)
@property (nonatomic, strong, readonly) NSOrderedSet *documents;
@end
