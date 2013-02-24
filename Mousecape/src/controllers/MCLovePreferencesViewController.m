//
//  MCLovePreferencesViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/24/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCLovePreferencesViewController.h"

@interface MCLovePreferencesViewController ()

@end

@implementation MCLovePreferencesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(NSString *)identifier {
    return @"Love";
}

-(NSImage *)toolbarItemImage {
    return [NSImage imageNamed:@"heart"];
}

-(NSString *)toolbarItemLabel {
    return @"Register";
}

@end
