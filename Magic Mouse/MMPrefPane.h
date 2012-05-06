//
//  MMPrefPane.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import "MMCursorAggregate.h"
#import "MMCursorViewController.h"
#import "MMAdvancedEditWindowController.h"
#import "MMCursorLibrary.h"

@interface MMPrefPane : NSPreferencePane <NSTabViewDelegate, NSMenuDelegate>

@property (nonatomic, assign) IBOutlet SFAuthorizationView *authView;
@property (nonatomic, assign) IBOutlet NSPopUpButton *cursorPicker;
@property (nonatomic, assign) CGFloat cursorScale;
@property (nonatomic, retain) MMCursorAggregate *currentCursor;
@property (nonatomic, retain) IBOutlet MMCursorViewController *cursorViewController;
@property (nonatomic, retain) MMAdvancedEditWindowController *advancedEditWindowController;
@property (nonatomic, retain) MMCursorLibrary *cursorLibrary;

- (void)mainViewDidLoad;
- (void)initializeData;
- (void)initializeCursorData;
- (BOOL)isUnlocked;

// Interface actions
- (IBAction)applyCursors:(NSButton *)sender;
- (IBAction)resetCursors:(NSButton *)sender;

- (IBAction)visitWebsite:(NSButton *)sender;
- (IBAction)donate:(NSButton *)sender;
- (IBAction)uninstall:(NSButton *)sender;

- (IBAction)importCursor:(NSMenuItem *)sender;
- (IBAction)exportCursor:(NSMenuItem *)sender;
- (IBAction)advancedEdit:(NSMenuItem *)sender;
- (void)chooseCursor:(id)sender;

- (void)dumpCursorsToFile:(NSString*)filePath;

@end
