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
	[self initializeCursorData];
	
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
- (void)initializeCursorData {
	// These methods tell CoreGraphics to register the images internally. I don't know how it does it–but it does.
	[[NSCursor contextualMenuCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor arrowCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor IBeamCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor pointingHandCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor closedHandCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor openHandCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor resizeLeftCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor resizeRightCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor resizeLeftRightCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor resizeUpCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor resizeDownCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor resizeUpDownCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor crosshairCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor disappearingItemCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor operationNotAllowedCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor busyButClickableCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor contextualMenuCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor IBeamCursorForVerticalLayout] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor dragCopyCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor dragLinkCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _genericDragCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _handCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _closedHandCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _moveCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _waitCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _crosshairCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _horizontalResizeCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _verticalResizeCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _bottomLeftResizeCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _topLeftResizeCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _bottomRightResizeCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _topRightResizeCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _resizeLeftCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _resizeRightCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _resizeLeftRightCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _zoomInCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _zoomOutCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeEastCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeEastWestCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeNorthCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeNorthEastCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeNorthEastSouthWestCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeNorthSouthCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeNorthWestCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeNorthWestSouthEastCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeSouthCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeSouthEastCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeSouthWestCursor] _getImageAndHotSpotFromCoreCursor];
	[[NSCursor _windowResizeWestCursor] _getImageAndHotSpotFromCoreCursor];
}

- (BOOL)isUnlocked {
    return ([_authView authorizationState] == SFAuthorizationViewUnlockedState);
}

// return the controller just incase we want to do extra things to it
- (MMAdvancedEditViewController *)displayPopoverForColumn:(NSInteger)columnIdx {
	if (columnIdx < 0 || columnIdx >= self.tableView.tableColumns.count)
		return nil;
	
	// Find the column that was dragged into
	NSTableColumn *column = [self.tableView.tableColumns objectAtIndex:columnIdx];
	// Get the associated MMCursor* for the cell
	MMCursor *cursor      = [self.currentCursor cursorForTableIdentifier:column.identifier];
	
	if (!cursor) {
		NSLog(@"No cursor for column (%@, %lu)?", column.identifier, (unsigned long)columnIdx);
		return nil;
	}
	
	// There is guaranteed to be atleast one image and (and no more than one for now)
	MMAdvancedEditViewController *advancedEdit = [[MMAdvancedEditViewController alloc] initWithNibName:@"AdvancedEdit"
																								bundle:kMMPrefsBundle];
	
	// create a popover to display
	__block NSPopover *popover = [[NSPopover alloc] init];
	popover.contentViewController                = advancedEdit;
	popover.behavior                             = NSPopoverBehaviorApplicationDefined;
	popover.appearance                           = NSPopoverAppearanceMinimal;
	
	NSView *imageView = [self.tableView viewAtColumn:columnIdx row:0 makeIfNecessary:NO];
	
	if (!imageView)
		return nil;
	
	// load the nib
	[popover showRelativeToRect:imageView.bounds
						 ofView:imageView
				  preferredEdge:NSMinYEdge];
	
	[advancedEdit release]; // decrease the retain count so that the popover is the only owner
	
	advancedEdit.cursor                          = cursor;
	advancedEdit.appliesChangesImmediately       = NO; // we only want changes applied when the user clicks "Done"
	advancedEdit.identifierField.editable        = NO; // make the identifier field uneditable. (read the highlighted comment below)
	advancedEdit.nameField.editable              = NO; // same as above
	
	[advancedEdit.imageView resetAnimation];
	
	__block MMPrefPane *selfRef = self;
	
	advancedEdit.didEndBlock                     = ^(BOOL finished) {
		[selfRef.tableView reloadData]; // reload the table for updated data
		
		[popover close];
		[popover release]; // get rid of the popover
		popover = nil;
	};
	
	return advancedEdit;
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
	// Delete the prefpane, remove the launch daemon, remove the preferences
}

- (IBAction)importCursor:(NSMenuItem *)sender {
	
}

- (IBAction)exportCursor:(NSMenuItem *)sender {
	NSSavePanel *sp = [NSSavePanel savePanel];
	sp.title = @"Export Cursor";
	sp.prompt = @"Select where to export the cursor.";
	sp.allowedFileTypes = [NSArray arrayWithObject:@"mightymouse"];
	[sp beginSheetModalForWindow:self.tableView.window 
			   completionHandler:^(NSInteger result){
				   if (result == NSFileHandlingPanelOKButton) {
					   [self.currentCursor.dictionaryRepresentation writeToURL:sp.URL atomically:YES];
				   }
			   }];
}

- (IBAction)advancedEdit:(NSMenuItem *)sender {
	
}

- (void)dumpCursorsToFile:(NSString*)filePath {
	[[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
	
	// Ask the tool to dump the cursors
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
	
	// set the dragged image to the image of the animating image view on the popover
	MMAdvancedEditViewController *vc   = [self displayPopoverForColumn:columnIdx];
	vc.imageView.image                 = [images objectAtIndex:0];
	vc.imageView.frameDuration         = 1;
	vc.imageView.frameCount            = 1;
	vc.frameCountField.integerValue    = 1;
	vc.frameDurationField.integerValue = 1; 
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