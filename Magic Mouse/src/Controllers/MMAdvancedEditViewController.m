//
//  MMQuickEditViewController.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/29/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMAdvancedEditViewController.h"

@implementation MMAdvancedEditViewController
@synthesize nameField                 = _nameField;
@synthesize xField                    = _xField;
@synthesize yField                    = _yField;
@synthesize frameCountField           = _frameCountField;
@synthesize frameDurationField        = _frameDurationField;
@synthesize identifierField           = _identifierField;
@synthesize imageView                 = _imageView;
@synthesize doneButton                = _doneButton;
@synthesize cancelButton              = _cancelButton;
@synthesize appliesChangesImmediately = _appliesChangesImmediately;
@synthesize didEndBlock               = _didEndBlock;
@dynamic cursor;

- (void)dealloc {
	self.cursor = nil;
	[super dealloc];
}

#pragma mark - Accessors
- (MMCursor *)cursor {
	return _cursor;
}

- (void)setCursor:(MMCursor *)cursor {
	[self willChangeValueForKey:@"cursor"];
	if (_cursor)
		[_cursor release];
	_cursor = [cursor retain];
	[self didChangeValueForKey:@"cursor"];
	
	if (_cursor) {		
		// Set all of our fields to their values based upon this here cursor
		self.nameField.stringValue          = self.cursor.name;
		self.xField.integerValue            = self.cursor.hotSpot.x;
		self.yField.integerValue            = self.cursor.hotSpot.y;
		self.frameCountField.integerValue   = self.cursor.frameCount;
		self.frameDurationField.doubleValue = self.cursor.frameDuration;
		self.identifierField.stringValue    = self.cursor.cursorIdentifier;
		
		self.imageView.image                = self.cursor.image;
		self.imageView.frameCount           = self.cursor.frameCount;
		self.imageView.frameDuration        = self.cursor.frameDuration;
				
		[self.imageView resetAnimation];
	}
	
}

#pragma mark - Actions
- (IBAction)nameChange:(NSTextField *)sender {
	
}

- (IBAction)xChange:(NSTextField *)sender {
	
}

- (IBAction)yChange:(NSTextField *)sender {
	
}

- (IBAction)frameCountChange:(id)sender { // The image view needs to be updated when there is a a framecount/duration change
	self.imageView.frameCount = self.frameCountField.integerValue;
	[self.imageView resetAnimation];
}

- (IBAction)frameDurationChange:(id)sender {
	self.imageView.frameDuration = self.frameDurationField.doubleValue;
	[self.imageView resetAnimation];
}

- (IBAction)identifierChange:(NSTextField *)sender {
	
}

- (IBAction)done:(NSButton *)sender {
	NSAssert(self.didEndBlock != NULL, @"For done: to be called & implemented, didEndBlock must not be NULL");
	self.didEndBlock(YES);
}

- (IBAction)cancel:(NSButton *)sender {
	NSAssert(self.didEndBlock != NULL, @"For cancelled: to be called & implemented, didEndBlock must not be NULL");
	self.didEndBlock(NO);
}

#pragma mark - MMAnimatedImageViewDelegate
- (NSDragOperation)imageView:(MMAnimatingImageView *)imageView draggingEntered:(id <NSDraggingInfo>)drop {
	return NSDragOperationCopy;
}

- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPrepareForDragOperation:(id <NSDraggingInfo>)drop {
	return YES;
}

- (BOOL)imageView:(MMAnimatingImageView *)imageView shouldPerformDragOperation:(id <NSDraggingInfo>)drop {
	return YES;
}

- (void)imageView:(MMAnimatingImageView *)imageView didAcceptDroppedImages:(NSArray *)images {
}

@end
