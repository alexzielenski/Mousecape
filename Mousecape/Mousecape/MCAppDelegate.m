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

static AuthorizationRef obtainRights();

@interface MCAppDelegate ()
- (void)configureHelperToolMenuItem;
@end

@implementation MCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self configureHelperToolMenuItem];
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
        
        NSDictionary *launchAgent = @{ @"Label": @"com.alexzielenski.mousecloak.listener", @"ProgramArguments": @[ mouseCloakDest, @"--listen" ], @"LimitLoadToSessionType": @[ @"LoginWindow", @"Aqua" ], @"RunAtLoad": @YES, @"KeepAlive": @YES };
        [launchAgent writeToFile:agentPath atomically:NO];
        
        NSDictionary *copyJob = @{ @"Label": @"com.alexzielenski.mousecloak.install2", @"ProgramArguments": @[ @"/bin/cp", @"-f", agentPath, agentDest ], @"RunAtLoad": @YES };
        SMJobSubmit(kSMDomainSystemLaunchd, (__bridge CFDictionaryRef)copyJob, authRef, NULL);
        SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)copyJob[@"Label"], authRef, true, NULL);

        system(loadCommand.UTF8String);
    }
    
    AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);
    [self configureHelperToolMenuItem];
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
