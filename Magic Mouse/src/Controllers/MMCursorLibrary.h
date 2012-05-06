//
//  MMCursorLibrary.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 5/6/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MMCursorAggregate.h"

@interface MMCursorLibrary : NSObject
@property (copy, readonly) NSString *libraryPath;
@property (retain, readonly) NSMutableSet *cursors; // Yeah, don't actually modify this

+ (MMCursorLibrary *)libraryWithPath:(NSString *)path;
- (id)initWithPath:(NSString *)path;

- (BOOL)addCursorAtPath:(NSString *)path;
- (void)removeCursor:(MMCursorAggregate *)cursor;
- (void)saveCursor:(MMCursorAggregate *)cursor;

@end
