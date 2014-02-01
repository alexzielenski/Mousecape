//
//  restore.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "backup.h"
#import "apply.h"

NSString *restoreStringForIdentifier(NSString *identifier) {
    return [identifier substringFromIndex:28];
}

void restoreCursorForIdentifier(NSString *ident) {
    bool registered = false;
    CGSIsCursorRegistered(CGSMainConnectionID(), (char *)ident.UTF8String, &registered);
    
    NSString *restoreIdent = restoreStringForIdentifier(ident);
    NSDictionary *cape = capeWithIdentifier(ident);
    
    MMLog("Restoring cursor %s from %s", restoreIdent.UTF8String, ident.UTF8String);
    if (cape && registered) {
        applyCapeForIdentifier(cape, restoreIdent);
    }
    
    CGSRemoveRegisteredCursor(CGSMainConnectionID(), (char *)ident.UTF8String, false);
}

void resetAllCursors() {
    MMLog("Restoring cursors...");
    
    // Backup main cursors first
    for (NSString *key in defaultCursors) {
        restoreCursorForIdentifier(backupStringForIdentifier(key));
    }

    // Backup auxiliary cursors
    MMLog("Restoring core cursors...");
    if (CoreCursorUnregisterAll(CGSMainConnectionID()) == 0) {
        MMLog(BOLD GREEN "Successfully restored all cursors." RESET);
    } else
        MMLog(BOLD RED "Received an error while restoring core cursors." RESET);
}