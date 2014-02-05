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

static AuthorizationRef obtainRights();

@interface MCAppDelegate ()
- (void)configureHelperToolMenuItem;
@end

@implementation MCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self configureHelperToolMenuItem];
    self.libraryWindowController = [[MCLibraryWindowController alloc] initWithWindowNibName:@"Library"];
    [self.libraryWindowController showWindow:self];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self.libraryWindowController showWindow:sender];
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
    NSString *mouseCloakDest = @"/usr/local/bin/mousecloak";
    NSString *agentDest = [@"/Library/LaunchAgents" stringByAppendingPathComponent: @"com.alexzielenski.mousecloak.listener.plist"];

    NSFileManager *manager = [NSFileManager defaultManager];
    [self.toggleHelperItem setTag: ([manager fileExistsAtPath:mouseCloakDest] && [manager fileExistsAtPath:agentDest])];
    [self.toggleHelperItem setTitle:self.toggleHelperItem.tag ? @"Uninstall Helper Tool" : @"Ininstall Helper Tool"];
}

- (IBAction)toggleInstall:(NSMenuItem *)sender {
    AuthorizationRef authRef = obtainRights();
    
    if (authRef == NULL) {
        NSLog(@"Failed to obtain authorization right.");
        return;
    }
    
    NSString *mouseCloakDest = @"/usr/local/bin/mousecloak";
    NSString *mouseCloakPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"mousecloak"];
    NSString *agentDest = [@"/Library/LaunchAgents" stringByAppendingPathComponent: @"com.alexzielenski.mousecloak.listener.plist"];
    NSString *agentPath = [NSTemporaryDirectory() stringByAppendingPathComponent: agentDest.lastPathComponent];
    
    NSString *loadCommand   = [NSString stringWithFormat:@"launchctl load %s", agentDest.UTF8String];
    NSString *unloadCommand = [NSString stringWithFormat:@"launchctl unload %s", agentDest.UTF8String];
    
    if (self.toggleHelperItem.tag) { // Uninstall
        system(unloadCommand.UTF8String);

        NSDictionary *removeTools = @{ @"Label": @"com.alexzielenski.mousecloak.remove", @"ProgramArguments": @[ @"/bin/rm", mouseCloakDest, agentDest ], @"RunAtLoad": @YES };
        SMJobSubmit(kSMDomainSystemLaunchd, (__bridge CFDictionaryRef)removeTools, authRef, NULL);
        SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)removeTools[@"Label"], authRef, true, NULL);
    } else {
        NSDictionary *copyTool = @{ @"Label": @"com.alexzielenski.mousecloak.install", @"ProgramArguments": @[ @"/bin/ln", @"-f", @"-s", mouseCloakPath, mouseCloakDest ], @"RunAtLoad": @YES };
        SMJobSubmit(kSMDomainSystemLaunchd, (__bridge CFDictionaryRef)copyTool, authRef, NULL);
        SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)copyTool[@"Label"], authRef, true, NULL);
        
        NSDictionary *launchAgent = @{ @"Label": @"com.alexzielenski.mousecloak.listener", @"ProgramArguments": @[ mouseCloakDest, @"--listen" ], @"LimitLoadToSessionType": @[ @"Aqua" ], @"RunAtLoad": @YES, @"KeepAlive": @YES };
        [launchAgent writeToFile:agentPath atomically:NO];
        
        NSDictionary *copyJob = @{ @"Label": @"com.alexzielenski.mousecloak.install2", @"ProgramArguments": @[ @"/bin/cp", @"-f", agentPath, agentDest ], @"RunAtLoad": @YES };
        SMJobSubmit(kSMDomainSystemLaunchd, (__bridge CFDictionaryRef)copyJob, authRef, NULL);
        SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)copyJob[@"Label"], authRef, true, NULL);

        system(loadCommand.UTF8String);
    }
    
    AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);
    [self configureHelperToolMenuItem];
}

#pragma mark - Interface Actions

// Cape Menu
- (IBAction)applyCape:(id)sender {
    [self.libraryWindowController.libraryViewController.libraryController applyCape:self.libraryWindowController.libraryViewController.selectedCape];
}

- (IBAction)editCape:(id)sender {
    [self.libraryWindowController.libraryViewController editCape:self.libraryWindowController.libraryViewController.selectedCape];
}

- (IBAction)removeCape:(id)sender {
    [self.libraryWindowController.libraryViewController.libraryController removeCape:self.libraryWindowController.libraryViewController.selectedCape];
}

- (IBAction)checkCape:(id)sender {
    
}

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

// File Menu

- (IBAction)newCape:(id)sender {
    [self.libraryWindowController.libraryViewController.libraryController importCape:[[MCCursorLibrary alloc] init]];
}

- (IBAction)importCape:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[ @"cape" ];
    panel.title = @"Import";
    panel.message = @"Choose a Mousecape to import";
    panel.prompt = @"Import";
    if ([panel runModal] == NSFileHandlingPanelOKButton) {
        [self.libraryWindowController.libraryViewController.libraryController importCapeAtURL:panel.URL];
    }
}

- (IBAction)duplicateCape:(id)sender {
        [self.libraryWindowController.libraryViewController.libraryController importCape:self.libraryWindowController.libraryViewController.selectedCape.copy];
}

@end

static AuthorizationRef obtainRights() {
    AuthorizationRef authRef = NULL;
    
    // Creating auth item to bless helper tool and install framework
    
    AuthorizationItem authItem = {kSMRightBlessPrivilegedHelper, 0, NULL, 0};
    AuthorizationItem modify   = {kSMRightModifySystemDaemons, 0, NULL, 0};
    
    AuthorizationItem items[2] = { authItem, modify };
    
    // Creating a set of authorization rights
	AuthorizationRights authRights = {2, items};
    
    // Specifying authorization options for authorization
	AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
    
    // Open dialog and prompt user for password
	OSStatus status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if (status == errAuthorizationSuccess)
        return authRef;
    return NULL;
}
