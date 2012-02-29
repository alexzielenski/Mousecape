//
//  MMAnimatingImageTableCellView.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/26/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMAnimatingImageTableCellView.h"

@implementation MMAnimatingImageTableCellView
@synthesize animatingImageView, delegate;
- (id)init {
	if ((self = [super init])) {
		[self registerTypes];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder])) {
		[self registerTypes];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect])) {
		[self registerTypes];
	}
	return self;
}

// Tell OSX that our view can accept images to be dragged in
- (void)registerTypes {
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSPasteboardTypeTIFF, NSPasteboardTypePNG, NSFilenamesPboardType, nil]];
}

#pragma mark - NSDragDestination
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
	// Only thing we have to do here is confirm that the dragged file is an image. We use NSImage's +canInitWithPasteboard: and we also check to see there is only one item being dragged
	if ([self.delegate conformsToProtocol:@protocol(MMAnimatingTableCellViewDelegate)] &&  // No point in accepting the drop if the delegate doesn't support it/exist
		[NSImage canInitWithPasteboard:sender.draggingPasteboard] &&                       // Only Accept Images
		sender.draggingPasteboard.pasteboardItems.count == 1) {                            // Only accept one item
		return [self.delegate tableCellView:self draggingEntered:sender];
	}
	return NSDragOperationNone;
}

// Give the delegate some more control
- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
	if ([self.delegate conformsToProtocol:@protocol(MMAnimatingTableCellViewDelegate)]) {
		return [self.delegate tableCellView:self shouldPerformDragOperation:sender];
	}
	return NO;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
	if ([self.delegate conformsToProtocol:@protocol(MMAnimatingTableCellViewDelegate)] &&  // Only do the operation if a delegate exists to actually set the image.
		[self.delegate tableCellView:self shouldPerformDragOperation:sender]) {            // Only do the operation if a delegate wants us to do the operation.
		// Get the image from the pasteboard
		NSImage *im = [[NSImage alloc] initWithPasteboard:sender.draggingPasteboard];
		
		// Make an array of the valid drops (NSBitmapImageRep)
		NSMutableArray *acceptedDrops = [[NSMutableArray alloc] initWithCapacity:im.representations.count];
		for (NSImageRep *rep in im.representations) {
			if (![rep isKindOfClass:[NSBitmapImageRep class]]) // We don't want PDFs
				continue;
			
			[acceptedDrops addObject:rep];
			
		}
		
		if (acceptedDrops.count > 0) {
			// We already confirmed that the delegate conforms to the protocol above. Now we can let the delegate
			// decide what to do with the dropped images.
			[self.delegate tableCellView:self didAcceptDroppedImages:acceptedDrops];
		}
		
		[acceptedDrops release];
		[im release];
		return YES;
	}
	
	return NO;
}

@end
