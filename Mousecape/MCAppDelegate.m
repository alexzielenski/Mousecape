//
//  MCAppDelegate.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCAppDelegate.h"
#import "MCLibraryWindowController.h"

#import <MASPreferencesWindowController.h>
#import "MCGeneralPreferencesViewController.h"

NSString *MCPreferencesAppliedCursorKey          = @"MCAppliedCursor";
NSString *MCPreferencesAppliedClickActionKey     = @"MCLibraryClickAction";
NSString *MCSuppressDeleteLibraryConfirmationKey = @"MCSuppressDeleteLibraryConfirmationKey";
NSString *MCSuppressDeleteCursorConfirmationKey  = @"MCSuppressDeleteCursorConfirmationKey";

@implementation MCAppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    self.libraryWindowController = [[MCLibraryWindowController alloc] initWithWindowNibName:@"Library"];
    (void)self.libraryWindowController.window;
    
    [NSUserDefaults.standardUserDefaults registerDefaults:
         @{
               MCPreferencesAppliedClickActionKey: @(0)
         }
     ];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleDocumentNeedWindowNotification:) name:@"MCDocumentNeedWindowNotification" object:nil];

#ifdef DEBUG
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    
#endif
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    if (![filename.pathExtension.lowercaseString isEqualToString:@"cape"])
        return NO;
    
    NSError *err = nil;
    MCCursorDocument *document = [[MCCursorDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filename] ofType:@"cape" error:&err];
    if (err)
        NSRunAlertPanel(@"Could not read cursor file.", err.localizedDescription ? err.localizedDescription : @"These are not the droids you are looking for", @"Crap", nil,  nil);
    
    [document makeWindowControllers];
    
    
    // add to library
//    NSError *err = [self.libraryController addToLibrary:filename];
//    if (err) {
//        NSRunAlertPanel(@"Could not add cursor to library", err.localizedDescription ? err.localizedDescription : @"These are not the droids you are looking for", @"Crap", nil,  nil);
//    }
    
    return YES;
}

#pragma mark - Interface Actions

- (void)handleDocumentNeedWindowNotification:(NSNotification *)notification {
    MCCursorDocument *doc = notification.object;
    [self.libraryWindowController addDocument:doc];
    [self.libraryWindowController.window makeKeyAndOrderFront:doc];
}

- (IBAction)showPreferences:(NSMenuItem *)sender {
    if (!self.preferencesWindowController) {
        NSViewController *general = [[MCGeneralPreferencesViewController alloc] initWithNibName:@"GeneralPreferences" bundle:nil];
        
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        
        self.preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[general] title:title];
    }
    
    [self.preferencesWindowController showWindow:self];
}

- (IBAction)installTool:(id)sender {
    NSLog(@"User wants to install mousecloak");
    // Alias mousecloak to the user's path
}

@end
