//
//  MCEditDetailController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCursor.h"
#import "MMAnimatingImageView.h"

@interface MCEditDetailController : NSViewController <MMAnimatingImageViewDelegate>
@property (strong) MCCursor *cursor;
@property (assign) IBOutlet NSPopUpButton *typePopUpButton;
@property (assign) IBOutlet MMAnimatingImageView *rep100View;
@property (assign) IBOutlet MMAnimatingImageView *rep200View;
@property (assign) IBOutlet MMAnimatingImageView *rep500View;
@property (assign) IBOutlet MMAnimatingImageView *rep1000View;
@end

@interface MCCursorTypeValueTransformer : NSValueTransformer
@end