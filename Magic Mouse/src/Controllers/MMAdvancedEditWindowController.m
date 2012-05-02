//
//  MMAdvancedEditWindowController.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 5/2/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMAdvancedEditWindowController.h"
#import "MMAdvancedEditViewController.h"

@interface MMAdvancedEditWindowController ()
@property (nonatomic, assign) IBOutlet NSView *_contentView;
@property (nonatomic, retain) MMAdvancedEditViewController *_advancedEditViewController;
@end

@implementation MMAdvancedEditWindowController

#pragma mark - Private Properties

@synthesize _contentView;
@synthesize _advancedEditViewController;

#pragma mark - Public Properties

@synthesize tableView    = _tableView;
@synthesize cursor       = _cursor;
@synthesize parentWindow = _parentWindow;

#pragma mark - Lifecycle

- (id)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc {
	self._contentView = nil;
	self.tableView    = nil;
	self.cursor       = nil;
	self._advancedEditViewController = nil;
	
	[super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    self._advancedEditViewController = [[[MMAdvancedEditViewController alloc] initWithNibName:@"AdvancedEdit" bundle:kMMPrefsBundle] autorelease];
	self._advancedEditViewController.view.frame = self._contentView.bounds;
	self._advancedEditViewController.appliesChangesImmediately = NO;
	
	self._advancedEditViewController.didEndBlock = ^(BOOL doneButton) {
		if (doneButton) {
			
		} else {
			
		}
		
		[self.window orderOut:self];
		[NSApp endSheet:self.window];
	};
	
	[self._contentView addSubview:self._advancedEditViewController.view];
}

- (void)displayForWindow:(NSWindow *)window cursor:(MMCursorAggregate *)cursor {
	self.cursor       = cursor;
	self.parentWindow = window;
	
	[self showWindow:self];
}

- (void)showWindow:(id)sender {	
	[NSApp beginSheet:self.window 
	   modalForWindow:self.parentWindow 
		modalDelegate:self 
	   didEndSelector:NULL
		  contextInfo:nil];
	
	if (self.cursor.cursors.count > 0)
		[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return self.cursor.cursors.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"AdvancedEditWindow" owner:self];
	
	MMCursor *currentCursor = [self.cursor.cursors.allValues objectAtIndex:row];	
	cellView.textField.stringValue = currentCursor.name;
		
	return cellView;
}

#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	MMCursor *cursor = [self.cursor.cursors.allValues objectAtIndex:self.tableView.selectedRow];
	self._advancedEditViewController.cursor = cursor;
}

@end
