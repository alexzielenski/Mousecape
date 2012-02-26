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
}

- (BOOL)isUnlocked {
    return ([authView authorizationState] == SFAuthorizationViewUnlockedState);
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