//
//  MCEditCursorViewController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursor.h"
#import "MCScaledImageView.h"

@interface MCEditCursorViewController : NSViewController <NSDraggingDestination>
@property (strong) MCCursor *cursor;
@property (strong) IBOutlet MCScaledImageView *imageView;
@property (weak) IBOutlet NSPopUpButton *typeButton;
@property (weak) IBOutlet NSTextField *hotSpotField;
@property (weak) IBOutlet NSTextField *frameCountField;
@property (weak) IBOutlet NSTextField *frameDurationField;
@property (weak) IBOutlet NSSegmentedControl *segmentedControl;
@property (weak) IBOutlet NSButton *actionButton;

- (IBAction)segment:(NSSegmentedControl *)sender;
- (IBAction)changeType:(NSPopUpButton *)sender;
- (IBAction)actionButton:(NSButton *)sender;

- (void)setCurrentImageToImageRep:(NSImageRep *)rep;
- (void)setCurrentImageToFileAtURL:(NSURL *)url;

@end
