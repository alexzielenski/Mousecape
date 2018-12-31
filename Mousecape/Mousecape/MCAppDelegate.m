//
//  MCAppDelegate.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCAppDelegate.h"
#import <Security/Security.h>
#import <ServiceManagement/ServiceManagement.h>
#import "MCCursorLibrary.h"
#import "create.h"
#import "MASPreferencesWindowController.h"
#import "MCGeneralPreferencesController.h"

@interface MCAppDelegate () {
    MASPreferencesWindowController *_preferencesWindowController;
}
@property (readonly) MASPreferencesWindowController *preferencesWindowController;
- (void)configureHelperToolMenuItem;
@end

@implementation MCAppDelegate
@dynamic preferencesWindowController;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    self.libraryWindowController = [[MCLibraryWindowController alloc] initWithWindowNibName:@"Library"];
    [self.libraryWindowController loadWindow];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self configureHelperToolMenuItem];
    [self.libraryWindowController showWindow:self];
    
    // Re-apply currently applied cape
    if (self.libraryWindowController.libraryViewController.libraryController.appliedCape != NULL) {
        [self.libraryWindowController.libraryViewController.libraryController applyCape:self.libraryWindowController.libraryViewController.libraryController.appliedCape];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    BOOL open = [filename.pathExtension.lowercaseString isEqualToString:@"cape"];
    NSURL *url = [NSURL fileURLWithPath:filename];
    if (open) {
        [self.libraryWindowController.libraryViewController.libraryController importCapeAtURL:url];
    }
    return open;
}

- (void)configureHelperToolMenuItem {
    CFDictionaryRef dict = SMJobCopyDictionary(kSMDomainUserLaunchd, CFSTR("com.alexzielenski.mousecloakhelper"));
    
    [self.toggleHelperItem setTag: dict ? 1 : 0];
    [self.toggleHelperItem setTitle:self.toggleHelperItem.tag ? @"Uninstall Helper Tool" : @"Install Helper Tool"];
    
    if (dict)
        CFRelease(dict);
}

- (IBAction)toggleInstall:(NSMenuItem *)sender {
    BOOL success = NO;
    
    if (self.toggleHelperItem.tag != 0) { // Uninstall
        success = SMLoginItemSetEnabled(CFSTR("com.alexzielenski.mousecloakhelper"), false);
    } else {
        success = SMLoginItemSetEnabled(CFSTR("com.alexzielenski.mousecloakhelper"), true);
    }
    
    // ServiceManagement.framework takes a while to actually register the job dictionary so if the return value is all good we
    // can be on our merry way
    if (success && self.toggleHelperItem.tag == 0) {
        // Successfully Installed
        [self.toggleHelperItem setTag: 1];
        [self.toggleHelperItem setTitle:@"Uninstall Helper Tool"];
    
        NSRunAlertPanel(@"Sucess", @"The Mousecape helper was successfully installed", @"Sweet", @"Thanks", nil);
    } else if (success) {
        // Successfully Uninstalled
        [self.toggleHelperItem setTag: 0];
        [self.toggleHelperItem setTitle:@"Install Helper Tool"];
        
        NSRunAlertPanel(@"Sucess", @"The Mousecape helper was successfully uninstalled", @"Sweet", @"Thanks", nil);
    } else {
        NSRunAlertPanel(@"Failure", @"The action did not complete successfully", @"Fuck", nil, nil);
    }
    
}

- (MASPreferencesWindowController *)preferencesWindowController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSViewController *general = [[MCGeneralPreferencesController alloc] init];
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[ general ] title:NSLocalizedString(@"Preferences", nil)];
    });
    
    return _preferencesWindowController;
}

#pragma mark - Interface Actions

- (IBAction)restoreCape:(id)sender {
    [self.libraryWindowController.libraryViewController.libraryController restoreCape];
}

- (IBAction)convertCape:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[ @"MightyMouse" ];
    panel.title = @"Import";
    panel.message = @"Choose a MightyMouse file to import";
    panel.prompt = @"Import";
    if ([panel runModal] == NSFileHandlingPanelOKButton) {
        NSString *name = panel.URL.lastPathComponent.stringByDeletingPathExtension;
        NSDictionary *metadata = @{
                                   @"name": name,
                                   @"version": @1.0,
                                   @"author": @"Unknown",
                                   @"identifier": [NSString stringWithFormat:@"local.import.%@.%f", name, [NSDate timeIntervalSinceReferenceDate]]
                                   };
        
        NSDictionary *cape = createCapeFromMightyMouse([NSDictionary dictionaryWithContentsOfURL:panel.URL], metadata);
        MCCursorLibrary *library = [MCCursorLibrary cursorLibraryWithDictionary:cape];
        [self.libraryWindowController.libraryViewController.libraryController importCape:library];
    }
}

- (IBAction)newDocument:(id)sender {
    [self.libraryWindowController.libraryViewController.libraryController importCape:[[MCCursorLibrary alloc] init]];
}

- (IBAction)openDocument:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[ @"cape" ];
    panel.title = @"Import";
    panel.message = @"Choose a Mousecape to import";
    panel.prompt = @"Import";
    if ([panel runModal] == NSFileHandlingPanelOKButton) {
        [self.libraryWindowController.libraryViewController.libraryController importCapeAtURL:panel.URL];
    }
}

- (IBAction)showPreferences:(id)sender {
    [self.preferencesWindowController showWindow:sender];
}

@end
