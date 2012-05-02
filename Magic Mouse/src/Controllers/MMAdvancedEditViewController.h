//
//  MMQuickEditViewController.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/29/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMCursorAggregate.h"
#import "MMAnimatingImageView.h"

/*! This is the class that will be used for display the popover for quick edits after drags, and it will be used
 for the advanced editing table. It is able to edit the important properties of MMCursor */

// Block for when done/cancel is clicked
typedef void(^MMAdvancedEditDidEndBlock)(BOOL doneClicked); // doneClicked = if it was done, NO if it was cancelled
@interface MMAdvancedEditViewController : NSViewController <MMAnimatingImageViewDelegate> {
	MMCursor *_cursor;
}

/* Properties and outlets for the views */
@property (nonatomic, retain) IBOutlet NSTextField          *nameField;
@property (nonatomic, retain) IBOutlet NSTextField          *xField;
@property (nonatomic, retain) IBOutlet NSTextField          *yField;
@property (nonatomic, retain) IBOutlet NSTextField          *frameCountField;
@property (nonatomic, retain) IBOutlet NSTextField          *frameDurationField;
@property (nonatomic, retain) IBOutlet NSTextField          *identifierField;
@property (nonatomic, retain) IBOutlet MMAnimatingImageView *imageView;
@property (nonatomic, retain) IBOutlet NSButton             *doneButton;
@property (nonatomic, retain) IBOutlet NSButton             *cancelButton;

@property (nonatomic, retain) MMCursor                      *cursor;
@property (nonatomic, assign) BOOL                          appliesChangesImmediately;
@property (nonatomic, copy) MMAdvancedEditDidEndBlock       didEndBlock;

// Actions called by the views when values are changed. I don't want to use bindings directly to have
// the power to cancel in the end.
- (IBAction)nameChange:(NSTextField *)sender;
- (IBAction)xChange:(NSTextField *)sender;
- (IBAction)yChange:(NSTextField *)sender;
- (IBAction)frameCountChange:(id)sender;
- (IBAction)frameDurationChange:(id)sender;
- (IBAction)identifierChange:(NSTextField *)sender;
- (IBAction)done:(NSButton *)sender;
- (IBAction)cancel:(NSButton *)sender;

@end
