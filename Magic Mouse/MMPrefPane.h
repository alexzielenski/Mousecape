//
//  Magic_Mouse.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface MMPrefPane : NSPreferencePane {
	IBOutlet SFAuthorizationView *authView;
}

- (void)mainViewDidLoad;
- (BOOL)isUnlocked;

@end
