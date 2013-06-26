//
//  MCCursorDocument.h
//  Mousecape
//
//  Created by Alex Zielenski on 6/25/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MCCursorLibrary.h"

@interface MCCursorDocument : NSDocument
@property (strong) MCCursorLibrary *library;
@property (strong) NSWindowController *editWindowController;

- (IBAction)apply:(id)sender;
- (IBAction)edit:(id)sender;



#pragma mark - Wrapper
//- (NSString *)name;
//- (NSString *)author;
//- (NSString *)identifier;
//- (NSNumber *)version;
//- (BOOL)isInCloud;
//- (BOOL)isHiDPI;
//- (NSDictionary *)cursors;
@end
