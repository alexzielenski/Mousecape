//
//  MCPreferences.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/24/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#ifndef Mousecape_MCPreferences_h
#define Mousecape_MCPreferences_h

extern NSString *MCPreferencesAppliedCursorKey;
extern NSString *MCPreferencesAppliedClickActionKey;
extern NSString *MCSuppressDeleteLibraryConfirmationKey;
extern NSString *MCSuppressDeleteCursorConfirmationKey;

#define MCDefaults(key) [NSUserDefaults.standardUserDefaults objectForKey: key]
#define MCFlag(key) [MCDefaults(key) boolValue]

#define MCSetDefault(value, key) [NSUserDefaults.standardUserDefaults setObject:value forKey: key]
#define MCSetFlag(value, key) MCSetDefault(@(value), key)

#endif
