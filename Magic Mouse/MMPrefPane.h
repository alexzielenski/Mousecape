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
#import "MMAnimatingImageTableCellView.h"
#import "MMAdvancedEditViewController.h"

@interface MMPrefPane : NSPreferencePane <NSTabViewDelegate, NSTableViewDataSource, MMAnimatingImageViewDelegate> {
	IBOutlet NSPopUpButton       *_actionMenu;
	IBOutlet NSPopUpButton       *_cursorThemes;
	
@private
	CGFloat            _cursorScale;
}
@property (nonatomic, assign) IBOutlet SFAuthorizationView *authView;
@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, assign) CGFloat cursorScale;
@property (nonatomic, retain) MMCursorAggregate *currentCursor;

- (void)mainViewDidLoad;
- (void)initializeData;
- (BOOL)isUnlocked;

- (MMAdvancedEditViewController *)displayPopoverForColumn:(NSInteger)column;

// Interface actions
- (IBAction)applyCursors:(NSButton *)sender;
- (IBAction)resetCursors:(NSButton *)sender;

- (IBAction)visitWebsite:(NSButton *)sender;
- (IBAction)donate:(NSButton *)sender;
- (IBAction)uninstall:(NSButton *)sender;

- (IBAction)importCursor:(NSMenuItem *)sender;
- (IBAction)exportCursor:(NSMenuItem *)sender;
- (IBAction)advancedEdit:(NSMenuItem *)sender;

- (void)dumpCursorsToFile:(NSString*)filePath;

@end
