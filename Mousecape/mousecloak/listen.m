//
//  listen.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "listen.h"
#import "apply.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "MCPrefs.h"
#import "CGSCursor.h"
#import <Cocoa/Cocoa.h>
#import "scale.h"

NSString *appliedCapePathForUser(NSString *user) {
    NSString *home = NSHomeDirectoryForUser(user);
    NSString *ident =     MCDefaultFor(@"MCAppliedCursor", user, (NSString *)kCFPreferencesCurrentHost);
    NSString *appSupport = [home stringByAppendingPathComponent:@"Library/Application Support"];
    return [[[appSupport stringByAppendingPathComponent:@"Mousecape/capes"] stringByAppendingPathComponent:ident] stringByAppendingPathExtension:@"cape"];
}

static void UserSpaceChanged(SCDynamicStoreRef	store, CFArrayRef changedKeys, void *info) {
    CFStringRef currentConsoleUser = SCDynamicStoreCopyConsoleUser(store, NULL, NULL);
    
    MMLog("Current user is %s", [(__bridge NSString *)currentConsoleUser UTF8String]);
    
    if (!currentConsoleUser || CFEqual(currentConsoleUser, CFSTR("loginwindow"))) {
        return;
    }
    
    NSString *appliedPath = appliedCapePathForUser((NSString *)currentConsoleUser);
    MMLog(BOLD GREEN "User Space Changed to %s, applying cape..." RESET, [(__bridge NSString *)currentConsoleUser UTF8String]);
    if (!applyCapeAtPath(appliedPath)) {
        MMLog(BOLD RED "Application of cape failed" RESET);
    }
    
    setCursorScale(defaultCursorScale());
    
    CFRelease(currentConsoleUser);
}

void reconfigurationCallback(CGDirectDisplayID display,
    	CGDisplayChangeSummaryFlags flags,
    	void *userInfo) {
    MMLog("Reconfigure user space");
    applyCapeAtPath(appliedCapePathForUser(NSUserName()));
    float scale;
    CGSGetCursorScale(CGSMainConnectionID(), &scale);
    CGSSetCursorScale(CGSMainConnectionID(), scale + .3);
    CGSSetCursorScale(CGSMainConnectionID(), scale);
}


void listener(void) {
    SCDynamicStoreRef store = SCDynamicStoreCreate(NULL, CFSTR("com.apple.dts.ConsoleUser"), UserSpaceChanged, NULL);
    assert(store != NULL);
    
    CFStringRef key = SCDynamicStoreKeyCreateConsoleUser(NULL);
    assert(key != NULL);
    
    CFArrayRef keys = CFArrayCreate(NULL, (const void **)&key, 1, &kCFTypeArrayCallBacks);
    assert(keys != NULL);
    
    Boolean success = SCDynamicStoreSetNotificationKeys(store, keys, NULL);
    assert(success);
    
    NSApplicationLoad();
    CGDisplayRegisterReconfigurationCallback(reconfigurationCallback, NULL);
    MMLog(BOLD CYAN "Listening for Display changes" RESET);
    
    CFRunLoopSourceRef rls = SCDynamicStoreCreateRunLoopSource(NULL, store, 0);
    assert(rls != NULL);
    MMLog(BOLD CYAN "Listening for User changes" RESET);
    
    // Apply the cape for the user on load
    applyCapeAtPath(appliedCapePathForUser(NSUserName()));
    setCursorScale(defaultCursorScale());
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
    CFRunLoopRun();

    // Cleanup
    CFRunLoopSourceInvalidate(rls);
    CFRelease(rls);
    CFRelease(keys);
    CFRelease(key);
    CFRelease(store);
}