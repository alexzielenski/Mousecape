//
//  MMPrefPane.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMPrefPane.h"
#import "NSCursor_Private.h"
#import "MMAdvancedEditViewController.h"

@interface MMPrefPane () {
	CGFloat _cursorScale;
	dispatch_queue_t _actionQueue;
}

@property (nonatomic, assign) IBOutlet NSPopUpButton *_cursorThemes;
@property (nonatomic, assign) IBOutlet NSPopUpButton *_actionMenu;

@end

// Why does CFPreferences suck so much hard nuts?
@implementation MMPrefPane

#pragma mark - Private Properties

@synthesize _cursorThemes;
@synthesize _actionMenu;

#pragma mark - Public Properties

@dynamic cursorScale;
@dynamic currentCursor;
@synthesize authView             = _authView;
@synthesize cursorViewController = _cursorViewController;
@synthesize advancedEditWindowController = _advancedEditWindowController;
@synthesize cursorLibrary        = _cursorLibrary;
@synthesize cursorPicker         = _cursorPicker;

#pragma mark - Lifecycle

- (void)dealloc {
	[self.cursorViewController unbind:@"enabled"];
	
	self.authView = nil;
	self.cursorViewController = nil;
	self.advancedEditWindowController = nil;
	
	[super dealloc];
}

- (void)mainViewDidLoad {
	NSArray *supports = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
															NSUserDomainMask,
															YES);
	
	NSString *appSupport = [[supports objectAtIndex:0] stringByAppendingPathComponent:@"MagicMouse"];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:appSupport withIntermediateDirectories:YES attributes:nil error:nil];
    
	self.cursorLibrary = [MMCursorLibrary libraryWithPath:appSupport];
	
	_actionQueue = dispatch_queue_create("com.alexzielenski.magicmouse.action.queue", 0);
	
	[self initializeCursorData];
	
	self.advancedEditWindowController = [[[MMAdvancedEditWindowController alloc] initWithWindowNibName:@"EditWindow"] autorelease];
	
	// Gather some authorization rights for the lock.
	AuthorizationItem items           = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights        = {1, &items};
	self.authView.authorizationRights = &rights;
    self.authView.delegate            = self;
	self.authView.autoupdate          = YES;
	
	// Update the lock for our new rights
    [self.authView updateStatus:nil];
	
	// Action Menu – Force it to have the gear
	[self._actionMenu.cell setUsesItemFromMenu:NO];
	NSMenuItem *item     = [[[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""] autorelease];
	item.image           = [NSImage imageNamed:@"NSActionTemplate"];
	item.onStateImage    = nil;
	item.mixedStateImage = nil;
	
    [self._actionMenu.cell setMenuItem:item];
	
	[self.cursorViewController bind:@"enabled" toObject:self withKeyPath:@"isUnlocked" options:nil];
	
	self.cursorPicker.action = @selector(chooseCursor:);
	self.cursorPicker.target = self;
	self.cursorPicker.menu.delegate = self;
	
	// Size to fit
	[self chooseCursor:self.cursorPicker];
	
	[self menuNeedsUpdate:self.cursorPicker.menu];
	[self.cursorPicker selectItemAtIndex:0];
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
	self.currentCursor          = [MMCursorAggregate aggregateWithContentsOfFile:cursorDump];
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

#pragma mark - Accessors
#import <objc/runtime.h>

static char MMCurrentCursor;

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
	return objc_getAssociatedObject(self, &MMCurrentCursor);
}

- (void)setCurrentCursor:(MMCursorAggregate *)currentCursor {
	[self willChangeValueForKey:@"currentCursor"];
	
	objc_setAssociatedObject(self, &MMCurrentCursor, currentCursor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
	[self didChangeValueForKey:@"currentCursor"];
	
	[self.cursorViewController.tableView reloadData];
}

- (BOOL)isUnlocked {
    return YES;//([_authView authorizationState] == SFAuthorizationViewUnlockedState);
}

#pragma mark - User Interface Actions

- (IBAction)applyCursors:(NSButton *)sender {
	// Save the current cursor to a temporary location and then apply it with the command line tool.
	
	NSString *location = self.cursorViewController.cursor.path;
	
	if (!location) {
		[NSTemporaryDirectory() stringByAppendingPathComponent:@"MagicMouseTemporary.MightyMouse"];
		[self.cursorViewController.cursor.dictionaryRepresentation writeToFile:location atomically:NO];
	}
	
	dispatch_async(_actionQueue, ^{
		NSTask *task                = [[NSTask alloc] init];
		task.launchPath             = kMMToolPath;
		task.arguments              = [NSArray arrayWithObject:location];
		task.standardOutput         = [NSPipe pipe];
		
		[task launch];
		[task waitUntilExit];
		[task release];
		
		// Update the cursor
		//! TODO: Find some way to update the cursor live
		[NSCursor _clearOverrideCursorAndSetArrow];
		[NSCursor _makeCursors];
		[NSCursor _clearOverrideCursorAndSetArrow];
	});
	
}

- (IBAction)resetCursors:(NSButton *)sender {
	[self initializeData];
	[self.cursorViewController.tableView reloadData];
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
	NSOpenPanel *sp = [NSOpenPanel openPanel];
	sp.title   = @"Import Cursor";
	sp.message = @"Select a cursor to import into your library."; 
	sp.prompt  = @"Import";
	
	sp.allowedFileTypes = [NSArray arrayWithObject:@"MightyMouse"];
	
	[sp beginSheetModalForWindow:[NSApp mainWindow]
			   completionHandler:^(NSInteger result){
				   if (result == NSFileHandlingPanelOKButton) {
					   
//					   self.currentCursor = [MMCursorAggregate aggregateWithDictionary:[NSDictionary dictionaryWithContentsOfURL:sp.URL]];
					   [self.cursorLibrary addCursorAtPath:sp.URL.path];
					   
				   }
			   }];
}

- (IBAction)exportCursor:(NSMenuItem *)sender {
	NSSavePanel *sp = [NSSavePanel savePanel];
	sp.title   = @"Export Cursor";
	sp.message = @"Select where to export the cursor."; 
	sp.prompt  = @"Export";
	
	sp.allowedFileTypes = [NSArray arrayWithObject:@"MightyMouse"];
	
	[sp beginSheetModalForWindow:[NSApp mainWindow] 
			   completionHandler:^(NSInteger result){
				   if (result == NSFileHandlingPanelOKButton) {
					   [self.cursorViewController.cursor.dictionaryRepresentation writeToURL:sp.URL atomically:YES];
				   }
			   }];
}

- (void)chooseCursor:(NSPopUpButton *)sender
{
	[sender sizeToFit];
	sender.frameOrigin = NSMakePoint(round(NSWidth(sender.superview.bounds) / 2 - NSWidth(sender.frame) / 2), sender.frame.origin.y);
}

- (IBAction)advancedEdit:(NSMenuItem *)sender {
	[self.advancedEditWindowController displayForWindow:[NSApp mainWindow] cursor:self.cursorViewController.cursor];
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

#pragma mark - NSMenuDelegate

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu
{
	return self.cursorLibrary.cursors.count + 1; // For the currently applied cursor, of course.
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSInteger count = [self numberOfItemsInMenu:menu];
	while ([menu numberOfItems] < count)
		[menu insertItem:[[NSMenuItem new] autorelease] atIndex:0];
	while ([menu numberOfItems] > count)
		[menu removeItemAtIndex:0];
	for (NSInteger index = 0; index < count; index++)
		[self menu:menu updateItem:[menu itemAtIndex:index] atIndex:index shouldCancel:NO];
}

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel
{
	if (shouldCancel)
		return NO;
	
	if (index == 0) {
		[item setTitle:@"Current"];
		return YES;
	}
	
	MMCursorAggregate *cursor = [self.cursorLibrary.cursors.allObjects objectAtIndex:0];
	
	item.title = cursor.path.lastPathComponent.stringByDeletingPathExtension;
	
	return YES;
	
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