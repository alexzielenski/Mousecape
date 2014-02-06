//
//  backup.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#ifndef Mousecape_backup_h
#define Mousecape_backup_h

extern NSString *backupStringForIdentifier(NSString *identifier);
extern void backupCursorForIdentifier(NSString *ident);
extern void backupAllCursors();

#endif
