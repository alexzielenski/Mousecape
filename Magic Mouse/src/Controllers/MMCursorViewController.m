//
//  MMCursorViewController.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 5/1/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMCursorViewController.h"
#import "MMAdvancedEditViewController.h"

@interface MMCursorViewController ()

- (MMAdvancedEditViewController *)_displayPopoverForColumn:(NSInteger)column;

@end

@implementation MMCursorViewController

#pragma mark - Public Properties

@synthesize tableView = _tableView;
@synthesize cursor    = _cursor;
@synthesize enabled   = _enabled;

#pragma mark - Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc {
	self.cursor    = nil;
	
	[super dealloc];
}


// return the controller just incase we want to do extra things to it
- (MMAdvancedEditViewController *)_displayPopoverForColumn:(NSInteger)columnIdx {
	if (columnIdx < 0 || columnIdx >= self.tableView.tableColumns.count)
		return nil;
	
	// Find the column that was dragged into
	NSTableColumn *column = [self.tableView.tableColumns objectAtIndex:columnIdx];
	
	// Get the associated MMCursor* for the cell
	MMCursor *cursor      = [self.cursor cursorForTableIdentifier:column.identifier];
	
	if (!cursor) {
		NSLog(@"No cursor for column (%@, %lu)?", column.identifier, (unsigned long)columnIdx);
		return nil;
	}
	
	// There is guaranteed to be atleast one image and (and no more than one for now)
	MMAdvancedEditViewController *advancedEdit = [[MMAdvancedEditViewController alloc] initWithNibName:@"AdvancedEdit"
																								bundle:kMMPrefsBundle];
	
	// create a popover to display
	NSPopover *popover             = [[[NSPopover alloc] init] autorelease];
	popover.contentViewController  = advancedEdit;
	popover.behavior               = NSPopoverBehaviorApplicationDefined;
	popover.appearance             = NSPopoverAppearanceMinimal;
	
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
		
	advancedEdit.didEndBlock                     = ^(BOOL finished) {
		[self.tableView reloadData]; // reload the table for updated data
		
		[popover close];
	};
	
	return advancedEdit;
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
	MMCursor *cursor                              = [self.cursor cursorForTableIdentifier:tableColumn.identifier];
	
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
	return (self.isEnabled) ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPrepareForDragOperation:(id <NSDraggingInfo>)drop {
	return self.isEnabled;
}

- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPerformDragOperation:(id <NSDraggingInfo>)drop {
	return self.isEnabled;
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
	MMAdvancedEditViewController *vc   = [self _displayPopoverForColumn:columnIdx];
	vc.imageView.image                 = [images objectAtIndex:0];
	vc.imageView.frameDuration         = 1;
	vc.imageView.frameCount            = 1;
	vc.frameCountField.integerValue    = 1;
	vc.frameDurationField.integerValue = 1; 
}

@end
