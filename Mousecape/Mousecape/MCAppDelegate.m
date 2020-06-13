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
    [self.toggleHelperItem setTitle:self.toggleHelperItem.tag ?
                    NSLocalizedString(@"Uninstall Helper Tool", "Uninstall Helper Tool Menu Item") :
                    NSLocalizedString(@"Install Helper Tool", "Install Helper Tool Menu Item")];
    
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
        [self.toggleHelperItem setTitle:NSLocalizedString(@"Uninstall Helper Tool", "Uninstall Helper Tool Menu Item")];
    
        NSRunAlertPanel(NSLocalizedString(@"Sucess", "Helper Tool Install Result Title Success"),
                        NSLocalizedString(@"The Mousecape helper was successfully installed", "Helper Tool Install Success Result useless description"),
                        NSLocalizedString(@"Sweet", "Helper Tool Install Result Gratitude 1"),
                        NSLocalizedString(@"Thanks", "Helper Tool Install Result Gratitude 2"), nil);
    } else if (success) {
        // Successfully Uninstalled
        [self.toggleHelperItem setTag: 0];
        [self.toggleHelperItem setTitle:NSLocalizedString(@"Install Helper Tool", "Install Helper Tool Menu Item")];
        
        NSRunAlertPanel(NSLocalizedString(@"Sucess", "Helper Tool Uninstall Result Title Success"),
                        NSLocalizedString(@"The Mousecape helper was successfully uninstalled", "Helper Tool Uninstall Success Result useless description"),
                        NSLocalizedString(@"Sweet", "Helper Tool Uninstall Result Gratitude 1"),
                        NSLocalizedString(@"Thanks", "Helper Tool Uninstall Result Gratitude 2"), nil);
    } else {
        NSRunAlertPanel(NSLocalizedString(@"Failure", "Helper Tool Result Title Failure"),
                        NSLocalizedString(@"The action did not complete successfully", "Helper Tool Result Useless Failure Description"),
                        NSLocalizedString(@"Fuck", "Helper Tool Result Failure Expletive"), nil, nil);
    }
    
}

- (MASPreferencesWindowController *)preferencesWindowController {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSViewController *general = [[MCGeneralPreferencesController alloc] init];
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[ general ] title:NSLocalizedString(@"Preferences", "Preferences Window Title")];
    });
    
    return _preferencesWindowController;
}

#pragma mark - Interface Actions

- (IBAction)restoreCape:(id)sender {
    [self.libraryWindowController.libraryViewController.libraryController restoreCape];
}

- (IBAction)convertCape:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes  = @[ @"MightyMouse" ];
    panel.title             = NSLocalizedString(@"Import", "MightyMouse Import Panel Title");
    panel.message           = NSLocalizedString(@"Choose a MightyMouse file to import", "MightyMouse Import Panel useless description");
    panel.prompt            = NSLocalizedString(@"Import", "MightyMouse Import Panel Prompt");
    if ([panel runModal] == NSFileHandlingPanelOKButton) {
        NSString *name = panel.URL.lastPathComponent.stringByDeletingPathExtension;
        NSDictionary *metadata = @{
                                   @"name": name,
                                   @"version": @1.0,
                                   @"author": NSLocalizedString(@"Unknown", "MightyMouse Import Default Author"),
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
    panel.allowedFileTypes  = @[ @"cape" ];
    panel.title             = NSLocalizedString(@"Import", "Mousecape Import Title");
    panel.message           = NSLocalizedString(@"Choose a Mousecape to import", "Mousecape Import useless description");
    panel.prompt            = NSLocalizedString(@"Import", "Mousecape Import Prompt");
    if ([panel runModal] == NSFileHandlingPanelOKButton) {
        [self.libraryWindowController.libraryViewController.libraryController importCapeAtURL:panel.URL];
    }
}

- (IBAction)showPreferences:(id)sender {
    [self.preferencesWindowController showWindow:sender];
}

@end
