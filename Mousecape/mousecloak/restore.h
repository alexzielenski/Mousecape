//
//  restore.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#ifndef Mousecape_restore_h
#define Mousecape_restore_h

extern NSString *restoreStringForIdentifier(NSString *identifier);
extern void restoreCursorForIdentifier(NSString *ident);
extern void resetAllCursors();

#endif
