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
NSString *MCPreferencesCursorScaleKey            = @"MCCursorScale";
NSString *MCPreferencesDoubleActionKey           = @"MCDoubleAction";
NSString *MCPreferencesHandednessKey             = @"MCHandedness";
NSString *MCSuppressDeleteLibraryConfirmationKey = @"MCSuppressDeleteLibraryConfirmationKey";
NSString *MCSuppressDeleteCursorConfirmationKey  = @"MCSuppressDeleteCursorConfirmationKey";
id MCDefaultFor(NSString *key) {
    NSString *value = (NSString *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)kMCDomain);
    return [value autorelease];
}

void MCSetDefaultFor(id value, NSString *key) {
    CFPreferencesSetAppValue((CFStringRef)key, (CFPropertyListRef)value, (CFStringRef)kMCDomain);
//    CFPreferencesSynchronize((CFStringRef)kMCDomain, (CFStringRef)user, (CFStringRef)host);
}

