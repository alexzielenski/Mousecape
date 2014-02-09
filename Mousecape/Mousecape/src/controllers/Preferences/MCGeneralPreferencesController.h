//
//  MCGeneralPreferencesController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/9/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MASPreferencesViewController.h"

@interface MCGeneralPreferencesController : NSViewController <MASPreferencesViewController>
@property (assign) float cursorScale;
@end
