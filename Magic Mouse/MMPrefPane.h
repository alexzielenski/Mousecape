//
//  Magic_Mouse.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface MMPrefPane : NSPreferencePane {
	IBOutlet SFAuthorizationView *authView;
	IBOutlet NSPopUpButton *actionMenu;
	IBOutlet NSPopUpButton *cursorThemes;
	IBOutlet NSTableView *table;
}

- (void)mainViewDidLoad;
- (BOOL)isUnlocked;

- (IBAction)applyCursors:(id)sender;
- (IBAction)resetCursors:(id)sender;

- (IBAction)visitWebsite:(id)sender;
- (IBAction)donate:(id)sender;
- (IBAction)uninstall:(id)sender;

- (IBAction)slideScale:(id)sender;

@end
