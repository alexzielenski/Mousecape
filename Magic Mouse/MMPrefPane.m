//
//  Magic_Mouse.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMPrefPane.h"
#import "MMDefs.h"

#define kLaunchdAgentPath [@"/Library/LaunchAgents/com.alexzielenski.magicmouse.plist" stringByExpandingTildeInPath]
@implementation MMPrefPane
- (void)mainViewDidLoad {
	NSLog(@"%@", kMMPrefsBundle);
}
- (void)createLaunchAgent {
	if ([[NSFileManager defaultManager] fileExistsAtPath:kLaunchdAgentPath])
		return; // Launchd Agent already exists. Why create it again?
	
	NSMutableDictionary *launchAgent = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:0], @"KeepAlive", 
										[NSNumber numberWithBool:1], @"RunAtLoad", 
										@"com.alexzielenski.magicmouse", @"Label", nil];
	NSString *magicPath = [kMMPrefsBundle pathForAuxiliaryExecutable:@"magicmouse"];
	NSString *prefsPath = [(NSString*)kMMPrefsLocation stringByExpandingTildeInPath];
	
	[launchAgent setObject:[NSArray arrayWithObjects:prefsPath, nil] forKey:@"WatchPaths"];
	[launchAgent setObject:[NSArray arrayWithObjects:magicPath, @"-p", nil] forKey:@"ProgramArguments"];
	
	[launchAgent writeToFile:kLaunchdAgentPath atomically:NO];
	
}
- (BOOL)isUnlocked {
    return ([authView authorizationState] == SFAuthorizationViewUnlockedState);
}
#pragma mark - Authorization Delegate
- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
	// Install the LaunchAgent
	[self createLaunchAgent];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
}

@end