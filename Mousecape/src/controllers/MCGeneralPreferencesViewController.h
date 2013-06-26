//
//  MCGeneralPreferencesViewController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/13/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MASPreferencesViewController.h>
#import "MCCloakController.h"

@interface MCGeneralPreferencesViewController : NSViewController <MASPreferencesViewController>
- (MCCloakController *)cloakController;
@end
