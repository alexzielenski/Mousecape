//
//  MMPrefPane.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMPrefPane.h"
#import "MMDefs.h"
#import "NSCursor_Private.h"
#import "MMAdvancedEditViewController.h"

// Why does CFPreferences suck so much hard nuts?
@implementation MMPrefPane
@dynamic cursorScale;
@synthesize authView      = _authView;
@synthesize tableView     = _tableView;

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
	
	NSNumber *scaleNum  = [NSNumber numberWithDouble:cursorScale];
	NSTask *task        = [[NSTask alloc] init];
	task.launchPath     = kMMToolPath;
	task.arguments      = [NSArray arrayWithObjects:@"-s", scaleNum.stringValue, nil];
	task.standardOutput = [NSPipe pipe]; // We don't want to spam the console with the output from this
	
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
//!*****************************************************************************************************************************************//
//!** Each table column has an identifier that would correspond with an identifier built into one of the cursors ("TableIdentifier" key). **//
//!** We use that identifier to retrieve the cursor and display it accoringly.                                                            **//
//!*****************************************************************************************************************************************//
- (NSTableCellView *)tableView:(NSTableView*)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	// This identifier is set in the xib
	static NSString *cellIdentifier = @"MMCursorCell";
	
	MMAnimatingImageTableCellView *cellView       = [tableView makeViewWithIdentifier:cellIdentifier owner:self];
	MMCursor *cursor                              = [self.currentCursor cursorForTableIdentifier:tableColumn.identifier];
	
	if (cursor) {
		cellView.animatingImageView.image         = cursor.image;
		cellView.animatingImageView.frameCount    = cursor.frameCount;
		cellView.animatingImageView.frameDuration = cursor.frameDuration;
		cellView.animatingImageView.delegate                         = self;
		
		// We set our values, now we need to reset the animation to reflect our changes
		[cellView.animatingImageView resetAnimation];
	}
	
	return cellView;
}

// Disable tableview selection
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex {
	return NO;
}

#pragma mark - MMAnimatingImageCellViewDelegate
- (NSDragOperation)imageView:(MMAnimatingImageView *)imageView draggingEntered:(id <NSDraggingInfo>)drop {
	return (self.isUnlocked) ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPrepareForDragOperation:(id <NSDraggingInfo>)drop {
	return self.isUnlocked;
}

- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPerformDragOperation:(id <NSDraggingInfo>)drop {
	return self.isUnlocked;
}

//!**********************************************************************************************************************************************/
//!** When the user drops an image onto a table item, we show then a quick edit popover for them to be able to quickly customize some of       **/
//!** the settings. If they click "Done" these changes are applied. We make the identifier field uneditable because we don't want the user     **/
//!** changing the identifier value for any of the cursors in the table since they have preset identifier values that must stay static to work **/
//!**********************************************************************************************************************************************/
- (void)imageView:(MMAnimatingImageView *)imageView didAcceptDroppedImages:(NSArray *)images {	
	NSUInteger columnIdx  = [_tableView columnAtPoint:imageView.superview.frame.origin];
	if (columnIdx == -1) {
		NSLog(@"No column found at specified point (%@) after drag operation.", NSStringFromPoint(imageView.superview.frame.origin));
		return;
	}
	
	// Find the column that was dragged into
	NSTableColumn *column = [_tableView.tableColumns objectAtIndex:columnIdx];
	// Get the associated MMCursor* for the cell
	MMCursor *cursor      = [self.currentCursor cursorForTableIdentifier:column.identifier];
	
	if (!cursor) {
		NSLog(@"No cursor for column (%@, %lu)?", column.identifier, (unsigned long)columnIdx);
		return;
	}
	
	// There is guaranteed to be atleast one image and (and no more than one for now)
	NSBitmapImageRep *image = [images objectAtIndex:0];
	MMAdvancedEditViewController *advancedEdit = [[MMAdvancedEditViewController alloc] initWithNibName:@"AdvancedEdit"
																								bundle:kMMPrefsBundle];
	
	// create a popover to display
	__block NSPopover *popover = [[NSPopover alloc] init];
	popover.contentViewController                = advancedEdit;
	popover.behavior                             = NSPopoverBehaviorApplicationDefined;
	popover.appearance                           = NSPopoverAppearanceMinimal;
	
	// load the nib
	[popover showRelativeToRect:imageView.superview.bounds
						 ofView:imageView.superview
				  preferredEdge:NSMinYEdge];
	
	[advancedEdit release]; // decrease the retain count so that the popover is the only owner
	
	// set the dragged image to the image of the animating image view on the popover
	advancedEdit.cursor = cursor;
	advancedEdit.imageView.image                 = image;
	advancedEdit.imageView.frameDuration         = 1;
	advancedEdit.imageView.frameCount            = 1;
	advancedEdit.frameCountField.integerValue    = 1;
	advancedEdit.frameDurationField.integerValue = 1; 
	advancedEdit.appliesChangesImmediately       = NO; // we only want changes applied when the user clicks "Done"
	advancedEdit.identifierField.editable        = NO; // make the identifier field uneditable. (read the highlighted comment above)
	
	[advancedEdit.imageView resetAnimation];
	
	advancedEdit.didEndBlock                     = ^(BOOL finished) {
		[popover close];
		[popover release]; // get rid of the popover
		popover = nil;
	};
	


	
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