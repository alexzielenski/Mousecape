//
//  MCPrefs.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCPrefs.h"

NSString *MCPreferencesAppliedCursorKey          = @"MCAppliedCursor";
NSString *MCPreferencesAppliedClickActionKey     = @"MCLibraryClickAction";
NSString *MCSuppressDeleteLibraryConfirmationKey = @"MCSuppressDeleteLibraryConfirmationKey";
NSString *MCSuppressDeleteCursorConfirmationKey  = @"MCSuppressDeleteCursorConfirmationKey";

id MCDefaults(NSString *key) {
    NSString *value = (NSString *)CFPreferencesCopyValue((CFStringRef)key, (CFStringRef)kMCDomain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    return [value autorelease];
}

void MCSetDefault(id value, NSString *key) {
    CFPreferencesSetValue((CFStringRef)key, (CFPropertyListRef)value, (CFStringRef)kMCDomain, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
}

