//
//  MCPrefs.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#ifndef Mousecape_MCPreferences_h
#define Mousecape_MCPreferences_h

#define kMCDomain @"com.alexzielenski.Mousecape"

extern NSString *MCPreferencesAppliedCursorKey;
extern NSString *MCPreferencesAppliedClickActionKey;
extern NSString *MCSuppressDeleteLibraryConfirmationKey;
extern NSString *MCSuppressDeleteCursorConfirmationKey;

extern id MCDefaults(NSString *key);
#define MCFlag(key) [MCDefaults(key) boolValue]

extern void MCSetDefault(id value, NSString *key);
#define MCSetFlag(value, key) MCSetDefault(@(value), key)
#endif