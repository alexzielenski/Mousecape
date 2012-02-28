//
//  Magic_Mouse.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMPrefPane.h"
#import "MMDefs.h"
#import "MMAnimatingImageTableCellView.h"
#import "NSCursor_Private.h"

// Why does CFPreferences suck so much hard nuts?
@implementation MMPrefPane
@dynamic cursorScale;
@synthesize authView      = _authView;

// Let objective-c runtime release this for me
@synthesize currentCursor = _currentCursor;

- (void)mainViewDidLoad {
	// Gather some authorization rights for the lock.
	AuthorizationItem items       = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights    = {1, &items};
	_authView.authorizationRights = &rights;
    _authView.delegate            = self;
	_authView.autoupdate          = YES;
	
	// Update the lock for our new rights
    [_authView updateStatus:nil];
	
	// Action Menu – Force it to have the gear
	[_actionMenu.cell setUsesItemFromMenu:NO];
	NSMenuItem *item     = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
	item.image           = [NSImage imageNamed:@"NSActionTemplate"];
	item.onStateImage    = nil;
	item.mixedStateImage = nil;
	
    [_actionMenu.cell setMenuItem:item];
    [item release];
}

- (void)willSelect {
	// Renew data every time the prefpane opens
	[self initializeData];
}

- (void)initializeData {
	[self willChangeValueForKey:@"cursorScale"];
	// Get the current cursor scale. It needs to be synchronous so that the text field is always in sync
	NSTask *task                = [[NSTask alloc] init];
	task.launchPath             = kMMToolPath;
	task.arguments              = [NSArray arrayWithObject:@"-s"];
	task.standardOutput         = [NSPipe pipe];
	
	[task launch];
	[task waitUntilExit];
	
	// We need a way to view the output because the tool logs the current cursor scale.
	NSFileHandle *outFileHandle = [task.standardOutput fileHandleForReading];
	NSData *data                = [outFileHandle availableData];
	NSString *output            = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	_cursorScale                = output.doubleValue;
	[self didChangeValueForKey:@"cursorScale"];
	
	[output release];
	[task release];
	
	// Dump the current cursors to a temporary location for the initial table view.
	NSString *cursorDump        = [NSTemporaryDirectory() stringByAppendingPathComponent:@"magicmousecursordump.plist"];
	[self dumpCursorsToFile:cursorDump];
	self.currentCursor          = [MMCursorAggregate aggregateWithDictionary:[NSDictionary dictionaryWithContentsOfFile:cursorDump]];
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
	_cursorScale       = cursorScale;
	[self didChangeValueForKey:@"cursorScale"];
	
	NSNumber *scaleNum = [NSNumber numberWithDouble:cursorScale];
	NSTask *task       = [[NSTask alloc] init];
	task.launchPath    = kMMToolPath;
	task.arguments     = [NSArray arrayWithObjects:@"-s", scaleNum.stringValue, nil];
	
	[task launch];
	[task waitUntilExit];
	[task release];
}

- (MMCursorAggregate *)currentCursor {
	return _currentCursor;
}

- (void)setCurrentCursor:(MMCursorAggregate *)currentCursor {
	[self willChangeValueForKey:@"currentCursor"];
	if (_currentCursor)
		[_currentCursor release];
	_currentCursor = [currentCursor retain];
	[self didChangeValueForKey:@"currentCursor"];
	
	[_tableView reloadData];
}

#pragma mark - User Interface Actions
- (IBAction)applyCursors:(NSButton *)sender {
}
	
- (IBAction)resetCursors:(NSButton *)sender {
	
}

- (IBAction)visitWebsite:(NSButton *)sender {
	[[NSWorkspace sharedWorkspace] openURL:kMMWebsiteURL];
}

- (IBAction)donate:(NSButton *)sender {
	[[NSWorkspace sharedWorkspace] openURL:kMMDonateURL];
}

- (IBAction)uninstall:(NSButton *)sender {
	// Remove the magicmouse binary, delete the prefpane, remove the launch daemon, remove the preferences
}

- (IBAction)importCursor:(NSMenuItem *)sender {
	
}

- (IBAction)exportCursor:(NSMenuItem *)sender {
	
}

- (IBAction)advancedEdit:(NSMenuItem *)sender {
	
}

- (void)dumpCursorsToFile:(NSString*)filePath {
	// Tell NSCursor to init some cursors that may not be registered
	[[NSCursor operationNotAllowedCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor dragCopyCursor]            _getImageAndHotSpotFromCoreCursor];
	[[NSCursor dragLinkCursor]            _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _moveCursor]               _getImageAndHotSpotFromCoreCursor];

	// Ask the tool to dump
	NSTask *task    = [[NSTask alloc] init];
	task.launchPath = kMMToolPath;
	task.arguments  = [NSArray arrayWithObjects:@"-d", filePath, nil];
	
	[task launch];
	[task waitUntilExit];
	[task release];
}

#pragma mark - NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	// We only have 1 row, but 9 columns
	return 1;
}

#pragma mark - NSTableViewDelegate
//*****************************************************************************************************************************************//
//** Each table column has an identifier that would correspond with an identifier built into one of the cursors ("TableIdentifier" key). **//
//** We use that identifier to retrieve the cursor and display it accoringly.                                                            **//
//*****************************************************************************************************************************************//
- (NSTableCellView *)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	// This identifier is set in the xib
	static NSString *cellIdentifier = @"MMCursorCell";
	
	MMAnimatingImageTableCellView *cellView       = [tableView makeViewWithIdentifier:cellIdentifier owner:self];
	MMCursor *cursor                              = [self.currentCursor cursorForTableIdentifier:tableColumn.identifier];
	
	if (cursor) {
		cellView.animatingImageView.image         = cursor.image;
		cellView.animatingImageView.frameCount    = cursor.frameCount;
		cellView.animatingImageView.frameDuration = cursor.frameDuration;
		
		// We set our values, now we need to reset the animation to reflect our changes
		[cellView.animatingImageView resetAnimation];
	}
	
	return cellView;
}

#pragma mark - Authorization Delegate
- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
	[self willChangeValueForKey:@"isUnlocked"];
	// Let observers know.
	[self didChangeValueForKey:@"isUnlocked"];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
	[self willChangeValueForKey:@"isUnlocked"];
	// Let observers know.
	[self didChangeValueForKey:@"isUnlocked"];
}

@end