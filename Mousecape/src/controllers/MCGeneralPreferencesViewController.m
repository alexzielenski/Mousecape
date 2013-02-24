//
//  MCGeneralPreferencesViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/13/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCGeneralPreferencesViewController.h"

@interface MCGeneralPreferencesViewController ()

@end

@implementation MCGeneralPreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Initialization code here.
    }
    
    return self;
}

-(NSString *)identifier {
    return @"General";
}

-(NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

-(NSString *)toolbarItemLabel {
    return @"General";
}

- (MCCloakController *)cloakController {
    return [MCCloakController sharedCloakController];
}

@end
