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
	} else {
		self.nameField.stringValue          = @"";
		self.xField.integerValue            = 0;
		self.yField.integerValue            = 0;
		self.frameCountField.integerValue   = 1;
		self.frameDurationField.doubleValue = 1.0;
		self.identifierField.stringValue    = @"";
		self.imageView.image                = nil;
	}
	[self.imageView resetAnimation];
}

#pragma mark - Actions
- (IBAction)nameChange:(NSTextField *)sender {
	if (self.appliesChangesImmediately) {
		self.cursor.name = sender.stringValue;
	}
}

- (IBAction)xChange:(NSTextField *)sender {
	if (self.appliesChangesImmediately) {
		self.cursor.hotSpot = NSMakePoint(sender.floatValue, self.cursor.hotSpot.y);
	}
}

- (IBAction)yChange:(NSTextField *)sender {
	if (self.appliesChangesImmediately) {
		self.cursor.hotSpot = NSMakePoint(self.cursor.hotSpot.x, sender.floatValue);
	}
}

- (IBAction)frameCountChange:(id)sender { // The image view needs to be updated when there is a a framecount/duration change
	if (self.appliesChangesImmediately) {
		self.cursor.frameCount = [sender integerValue];
	}
	self.imageView.frameCount = self.frameCountField.integerValue;
	[self.imageView resetAnimation];
}

- (IBAction)frameDurationChange:(id)sender {
	if (self.appliesChangesImmediately) {
		self.cursor.frameDuration = [sender doubleValue];
	}
	self.imageView.frameDuration = self.frameDurationField.doubleValue;
	[self.imageView resetAnimation];
}

- (IBAction)identifierChange:(NSTextField *)sender {
	if (self.appliesChangesImmediately) {
		self.cursor.cursorIdentifier = sender.stringValue;
	}
}

- (IBAction)done:(NSButton *)sender {
	NSAssert(self.didEndBlock != NULL, @"For done: to be called & implemented, didEndBlock must not be NULL");
	
	self.cursor.name             = self.nameField.stringValue;
	self.cursor.hotSpot          = NSMakePoint(self.xField.floatValue, self.yField.floatValue);
	self.cursor.frameCount       = self.frameCountField.integerValue;
	self.cursor.frameDuration    = self.frameDurationField.doubleValue;
	self.cursor.cursorIdentifier = self.identifierField.stringValue;
	self.cursor.image            = self.imageView.image;
	
	self.didEndBlock(YES);
}

- (IBAction)cancel:(NSButton *)sender {
	NSAssert(self.didEndBlock != NULL, @"For cancel: to be called & implemented, didEndBlock must not be NULL");
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
	if (self.appliesChangesImmediately) {
		self.cursor.image = [images objectAtIndex:0];
	}
	[imageView resetAnimation];
}

@end
