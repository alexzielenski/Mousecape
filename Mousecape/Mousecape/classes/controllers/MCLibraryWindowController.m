//
//  MCLbraryWindowController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCLibraryWindowController.h"

@interface MCLibraryWindowController ()

@end

@implementation MCLibraryWindowController

- (id)initWithWindow:(NSWindow *)window {
    if ((self = [super initWithWindow:window])) {
        
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (NSString *)windowNibName {
    return @"Library";
}

@end
