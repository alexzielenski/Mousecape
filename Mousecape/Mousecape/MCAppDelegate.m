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

@implementation MCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (IBAction)toggleInstall:(NSMenuItem *)sender {
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
    
    if (status != errAuthorizationSuccess) {
        NSLog(@"Failed to install helper tool. Failed to obtain authorization right.");
        return;
    }
    
    NSString *mouseCloakPath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"mousecloak"];
    NSString *mouseCloakDest = @"/usr/local/bin/mousecloak";
    
    NSDictionary *copyTool = @{ @"Label": @"com.alexzielenski.mousecloak.install", @"ProgramArguments": @[ @"/bin/ln", @"-f", @"-s", mouseCloakPath, mouseCloakDest ], @"RunAtLoad": @YES };
    SMJobSubmit(kSMDomainSystemLaunchd, (__bridge CFDictionaryRef)copyTool, authRef, NULL);
    SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)@"com.alexzielenski.mousecloak.install", authRef, true, NULL);
    
    NSDictionary *launchAgent = @{ @"Label": @"com.alexzielenski.mousecloak.listener", @"ProgramArguments": @[ mouseCloakDest, @"--listen" ], @"LimitLoadToSessionType": @[ @"LoginWindow", @"Aqua" ], @"RunAtLoad": @YES, @"KeepAlive": @YES };
    NSString *agentPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.alexzielenski.mousecloak.listener.plist"];
    NSString *agentDest = [@"/Library/LaunchAgents" stringByAppendingPathComponent: agentPath.lastPathComponent];

    [launchAgent writeToFile:agentPath atomically:NO];
    
    NSDictionary *copyJob = @{ @"Label": @"com.alexzielenski.mousecloak.install2", @"ProgramArguments": @[ @"/bin/cp", @"-f", agentPath, agentDest ], @"RunAtLoad": @YES };
    SMJobSubmit(kSMDomainSystemLaunchd, (__bridge CFDictionaryRef)copyJob, authRef, NULL);
    SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)@"com.alexzielenski.mousecloak.install2", authRef, true, NULL);
    
    NSString *loadCommand   = [NSString stringWithFormat:@"launchctl load %s", agentDest.UTF8String];
    NSString *unloadCommand = [NSString stringWithFormat:@"launchctl unload %s", agentDest.UTF8String];
    
    system(unloadCommand.UTF8String);
    system(loadCommand.UTF8String);
    
    AuthorizationFree(authRef, flags);
}

@end
