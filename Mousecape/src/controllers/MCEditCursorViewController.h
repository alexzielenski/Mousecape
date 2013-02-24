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

@interface MCEditCursorViewController : NSViewController
@property (copy) NSString *identifier;
@property (strong) MCCursor *cursor;
@property (strong) IBOutlet MCScaledImageView *imageView;
@property (weak) IBOutlet NSTextField *identifierField;
@property (weak) IBOutlet NSTextField *sizeField;
@property (weak) IBOutlet NSTextField *hotSpotField;
@property (weak) IBOutlet NSTextField *frameCountField;
@property (weak) IBOutlet NSTextField *frameDurationField;
@end
