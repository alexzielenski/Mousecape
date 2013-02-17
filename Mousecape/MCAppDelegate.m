//
//  MCAppDelegate.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCAppDelegate.h"
#import "NSFileManager+DirectoryLocations.h"
#import "MCCursorLibrary.h"
#import "MCCloakController.h"
#import "NSCursor_Private.h"
#import "CGSCursor.h"

#import <MASPreferencesWindowController.h>
#import "MCGeneralPreferencesViewController.h"

@interface MCAppDelegate ()
@end

@implementation MCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
//    CoreCursorUnregisterAll(CGSMainConnectionID());
//    [[NSCursor contextualMenuCursor] _getImageAndHotSpotFromCoreCursor];
//    [[[NSCursor alloc] initWithImage:[NSImage imageNamed:@"NSApplicationIcon"] hotSpot:NSZeroPoint] push];
//    return;
    
    [self.window.contentView setNeedsLayout:YES];
    [self composeAccessory];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    NSString *appSupport = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *capesPath  = [appSupport stringByAppendingPathComponent:@"capes"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:capesPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    [self.libraryController loadLibraryAtPath:capesPath];
    [self.detailController bind:@"currentLibrary" toObject:self.libraryController withKeyPath:@"selectedLibrary" options:nil];
    
    __block MCAppDelegate *blockSelf = self;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:MCCloakControllerDidApplyCursorNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      id obj = note.userInfo[MCCloakControllerAppliedCursorKey];
                                                      blockSelf.libraryController.appliedLibrary = [obj isKindOfClass:[NSNull class]] ? nil : obj;
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:MCCloakControllerDidRestoreCursorNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      blockSelf.libraryController.appliedLibrary = nil;
                                                  }];
    
}
- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.detailController unbind:@"currentLibrary"];
}
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    if (![filename.pathExtension.lowercaseString isEqualToString:@"cape"])
        return NO;
    
    // add to library
    NSError *err = [self.libraryController addToLibrary:filename];
    if (err) {
        NSRunAlertPanel(@"Could not add cursor to library", err.localizedDescription ? err.localizedDescription : @"These are not the droids you are looking for", @"Crap", nil,  nil);
    }
    
    return YES;
}
- (IBAction)showPreferences:(NSMenuItem *)sender {
    if (!self.preferencesWindowController) {
        NSViewController *general = [[MCGeneralPreferencesViewController alloc] initWithNibName:@"GeneralPreferences" bundle:nil];
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        self.preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[general] title:title];
    }
    
    [self.preferencesWindowController showWindow:self];
}
- (void)composeAccessory {
    NSView *themeFrame = [self.window.contentView superview];
    NSView *accessory = self.accessory.superview;
    [accessory setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSRect c  = themeFrame.frame;
    NSRect aV = accessory.frame;
    NSRect newFrame = NSMakeRect(
                                 c.size.width - aV.size.width,	// x position
                                 c.size.height - aV.size.height,	// y position
                                 aV.size.width,	// width
                                 aV.size.height);	// height
    
    [accessory setFrame:newFrame];
    [themeFrame addSubview:accessory];
    
    [themeFrame addConstraints:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"H:|-(>=100)-[accessory(245)]-(0)-|"
                                options:0
                                metrics:nil
                                views:NSDictionaryOfVariableBindings(accessory)]];
    [themeFrame addConstraints:[NSLayoutConstraint
                                constraintsWithVisualFormat:@"V:|-(0)-[accessory(20)]-(>=22)-|"
                                options:0
                                metrics:nil
                                views:NSDictionaryOfVariableBindings(accessory)]];    
}

@end
