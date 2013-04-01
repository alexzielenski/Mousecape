//
//  MCCloakController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/13/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCursorLibrary.h"

extern NSString *MCCloakControllerDidApplyCursorNotification;
extern NSString *MCCloakControllerDidRestoreCursorNotification;

extern NSString *MCCloakControllerAppliedCursorKey;

@interface MCCloakController : NSObject
@property (assign) float cursorScale;
@property (copy)   void(^outputBlock)(NSString *output);

+ (MCCloakController *)sharedCloakController;
- (void)applyCape:(MCCursorLibrary *)cursor;
- (NSString *)convertMightyMouse:(NSString *)mightyMouse;
- (void)restoreDefaults;

@end
