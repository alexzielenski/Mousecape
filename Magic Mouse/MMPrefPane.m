//
//  Magic_Mouse.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMPrefPane.h"
#import "MMDefs.h"
#import "MMAnimatingImageView.h"

// Why does CFPreferences suck so much hard nuts?
@implementation MMPrefPane
@dynamic cursorScale;
- (void)mainViewDidLoad {
	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &items};
    [_authView setAuthorizationRights:&rights];
    _authView.delegate = self;
    [_authView updateStatus:nil];
	[_authView setAutoupdate:YES];
	
	// Action Menu
	[[_actionMenu cell] setUsesItemFromMenu:NO];
	NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [item setImage:[NSImage imageNamed:@"NSActionTemplate"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[_actionMenu cell] setMenuItem:item];
    [item release];
}

- (void)willSelect {
	// Get the data values
	[self initializeData];
}

- (void)initializeData {
	// Get the current cursor scale. It needs to be synchronous so that the text field is always in sync
	NSTask *task = [[NSTask alloc] init];
	task.launchPath = kMMToolPath;
	task.arguments = [NSArray arrayWithObject:@"-s"];
	task.standardOutput = [NSPipe pipe];
	[task launch];
	[task waitUntilExit];
	
	NSFileHandle *outFileHandle = [task.standardOutput fileHandleForReading];
	NSData *data = [outFileHandle availableData];
	NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	[self willChangeValueForKey:@"cursorScale"];
	_cursorScale = output.doubleValue;
	[self didChangeValueForKey:@"cursorScale"];
	
	[output release];
	[task release];
	
	// Use magic mouse to dump the current cursor to a temporary location and initialize the current cursor off of that?
	
}

- (BOOL)isUnlocked {
    return ([_authView authorizationState] == SFAuthorizationViewUnlockedState);
}

#pragma mark - Accessors
- (CGFloat)cursorScale {
	return _cursorScale;
}
- (void)setCursorScale:(CGFloat)cursorScale {
	// Tell the observers it change, write it out to prefs, and use magicmouse tool to change the scale
	[self willChangeValueForKey:@"cursorScale"];
	_cursorScale = cursorScale;
	[self didChangeValueForKey:@"cursorScale"];
	
	NSNumber *scaleNum = [NSNumber numberWithDouble:cursorScale];
	
	CFPreferencesSetValue(kMMPrefsCursorScaleKey, 
						  (CFPropertyListRef)scaleNum,
						  kMMPrefsAppID, 
						  kCFPreferencesAnyUser,
						  kCFPreferencesCurrentHost);
	
	CFPreferencesSynchronize(kMMPrefsAppID, 
							 kCFPreferencesAnyUser, 
							 kCFPreferencesCurrentHost);
	
	NSTask *task = [[NSTask alloc] init];
	task.launchPath = kMMToolPath;
	task.arguments = [NSArray arrayWithObjects:@"-s", scaleNum.stringValue, nil];
	[task launch];
	[task waitUntilExit];
	[task release];
}

#pragma mark - User Interface Actions
- (IBAction)applyCursors:(id)sender {
	
}
	
- (IBAction)resetCursors:(id)sender {
	
}

- (IBAction)visitWebsite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:kMMWebsiteURL];
}

- (IBAction)donate:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:kMMDonateURL];
}

- (IBAction)uninstall:(id)sender {
	// Remove the magicmouse binary, delete the prefpane, remove the launch daemon, remove the preferences
}
#pragma mark - NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return 0;
}
#pragma mark - NSTableViewDelegate
- (NSTableCellView*)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
	return nil;
}
#pragma mark - Authorization Delegate
- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
	[self willChangeValueForKey:@"isUnlocked"];
	[self didChangeValueForKey:@"isUnlocked"];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
	[self willChangeValueForKey:@"isUnlocked"];
	//let observers know
	[self didChangeValueForKey:@"isUnlocked"];
}

@end