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
@property (strong) MCCursor *cursor;
@property (strong) IBOutlet MCScaledImageView *imageView;
@end
