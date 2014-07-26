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
extern NSString *MCPreferencesCursorScaleKey;
extern NSString *MCPreferencesDoubleActionKey;
extern NSString *MCPreferencesHandednessKey;
extern NSString *MCSuppressDeleteLibraryConfirmationKey;
extern NSString *MCSuppressDeleteCursorConfirmationKey;
extern id MCDefaultFor(NSString *key);
#define MCDefault(key) MCDefaultFor(key)
#define MCFlag(key) [MCDefault(key) boolValue]

extern void MCSetDefaultFor(id value, NSString *key);
#define MCSetDefault(value, key) MCSetDefaultFor(value, key)
#define MCSetFlag(value, key) MCSetDefault(@(value), key)
#endif