//
//  MMAnimatingImageTableCellView.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/26/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "MMAnimatingImageView.h"

@class MMAnimatingImageTableCellView; // Define the class for our protocol.
/*! Protocol for giving the delegate control over drops. */
@protocol MMAnimatingTableCellViewDelegate <NSObject>
@required

- (NSDragOperation)tableCellView:(MMAnimatingImageTableCellView *)cellView draggingEntered:(id <NSDraggingInfo>)drop;
- (BOOL)tableCellView:(MMAnimatingImageTableCellView *)cellView shouldPrepareForDragOperation:(id <NSDraggingInfo>)drop;
- (BOOL)tableCellView:(MMAnimatingImageTableCellView *)cellView shouldPerformDragOperation:(id <NSDraggingInfo>)drop;
- (void)tableCellView:(MMAnimatingImageTableCellView *)cellView didAcceptDroppedImages:(NSArray *)images; // I'm making this an array because in the future we mighty allow users
																										 // to drag multiple frames for a cursor instead of manually stacking them.

@end

// This is just a simple table cell subclass with an animating image view property. No big deal
@interface MMAnimatingImageTableCellView : NSTableCellView <NSDraggingDestination>

@property (nonatomic, assign) id <MMAnimatingTableCellViewDelegate> delegate;
@property (nonatomic, retain) IBOutlet MMAnimatingImageView         *animatingImageView;

// Don't call this. Registers the valid drag types. Probably should be a private category–but we're all developers here...
- (void)registerTypes;

@end
