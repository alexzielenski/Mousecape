//
//  Magic_Mouse.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import "MMCursorAggregate.h"

@interface MMPrefPane : NSPreferencePane <NSTabViewDelegate, NSTableViewDataSource> {
	IBOutlet SFAuthorizationView *_authView;
	IBOutlet NSPopUpButton       *_actionMenu;
	IBOutlet NSPopUpButton       *_cursorThemes;
	IBOutlet NSTableView         *_tableView;
	
@private
	CGFloat            _cursorScale;
	MMCursorAggregate *_currentCursor;
}
@property (nonatomic, assign) CGFloat cursorScale;
- (void)mainViewDidLoad;
- (void)initializeData;
- (BOOL)isUnlocked;

- (IBAction)applyCursors:(id)sender;
- (IBAction)resetCursors:(id)sender;

- (IBAction)visitWebsite:(id)sender;
- (IBAction)donate:(id)sender;
- (IBAction)uninstall:(id)sender;

@end
