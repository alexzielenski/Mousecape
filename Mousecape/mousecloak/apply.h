//
//  apply.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#ifndef Mousecape_apply_h
#define Mousecape_apply_h

extern NSString *appliedCapePathForUser(NSString *user);
extern BOOL applyCursorForIdentifier(NSUInteger frameCount, CGFloat frameDuration, CGPoint hotSpot, CGSize size, NSArray *images, NSString *ident, NSUInteger repeatCount);
extern BOOL applyCapeForIdentifier(NSDictionary *cursor, NSString *identifier);
extern BOOL applyCape(NSDictionary *dictionary);

#endif
