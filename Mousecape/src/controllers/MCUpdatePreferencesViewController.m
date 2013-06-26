//
//  MCUpdatePreferencesViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/24/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCUpdatePreferencesViewController.h"

@interface MCUpdatePreferencesViewController ()

@end

@implementation MCUpdatePreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(NSString *)identifier {
    return @"Update";
}

-(NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"software-update"];
}

-(NSString *)toolbarItemLabel {
    return @"Updates";
}

@end
