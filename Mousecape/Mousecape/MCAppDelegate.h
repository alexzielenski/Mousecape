//
//  MCAppDelegate.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MCAppDelegate : NSObject <NSApplicationDelegate>
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenuItem *toggleHelperItem;
- (IBAction)toggleInstall:(NSMenuItem *)sender;

@end
