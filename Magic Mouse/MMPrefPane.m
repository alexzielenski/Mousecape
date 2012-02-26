//
//  Magic_Mouse.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMPrefPane.h"
#import "MMDefs.h"

// Why does CFPreferences suck so much hard nuts?

@implementation MMPrefPane
- (void)mainViewDidLoad {
	AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &items};
    [authView setAuthorizationRights:&rights];
    authView.delegate = self;
    [authView updateStatus:nil];
	[authView setAutoupdate:YES];
	
	// Action Menu
	[[actionMenu cell] setUsesItemFromMenu:NO];
	NSMenuItem *item = [[NSMenuItem allocWithZone:[self zone]] initWithTitle:@"" action:NULL keyEquivalent:@""];
    [item setImage:[NSImage imageNamed:@"NSActionTemplate"]];
    [item setOnStateImage:nil];
    [item setMixedStateImage:nil];
    [[actionMenu cell] setMenuItem:item];
    [item release];
}

- (BOOL)isUnlocked {
    return ([authView authorizationState] == SFAuthorizationViewUnlockedState);
}

#pragma mark - User Interface Actions
- (IBAction)applyCursors:(id)sender {
	
}
	
- (IBAction)resetCursors:(id)sender {
	
}

- (IBAction)visitWebsite:(id)sender {
	
}

- (IBAction)donate:(id)sender {
	
}

- (IBAction)uninstall:(id)sender {
	
}

- (IBAction)slideScale:(id)sender {
	
}

#pragma mark - Authorization Delegate
- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
	[self willChangeValueForKey:@"isUnlocked"];
	[self didChangeValueForKey:@"isUnlocked"];
}

- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
	[self willChangeValueForKey:@"isUnlocked"];
	//let observers know
	[self didChangeValueForKey:@"isUnlocked"];
}

@end