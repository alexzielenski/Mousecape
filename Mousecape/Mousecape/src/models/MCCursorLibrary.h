//
//  MCCursorLibrary.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCursor.h"

extern NSString *const MCLibraryWillSaveNotificationName;
extern NSString *const MCLibraryDidSaveNotificationName;

@class MCLibraryController;
@interface MCCursorLibrary : NSObject <NSCopying>
@property (nonatomic, copy)   NSString *name;
@property (nonatomic, copy)   NSString *author;
@property (nonatomic, copy)   NSString *identifier;
@property (nonatomic, copy)   NSNumber *version;
@property (nonatomic, copy)   NSURL    *fileURL;
@property (nonatomic, weak)   MCLibraryController *library;
@property (nonatomic, readonly) NSUndoManager *undoManager;
@property (nonatomic, readonly, getter=isDirty) BOOL dirty;
@property (nonatomic, assign, getter = isInCloud) BOOL inCloud;
@property (nonatomic, assign, getter = isHiDPI)   BOOL hiDPI;

+ (MCCursorLibrary *)cursorLibraryWithContentsOfFile:(NSString *)path;
+ (MCCursorLibrary *)cursorLibraryWithContentsOfURL:(NSURL *)URL;
+ (MCCursorLibrary *)cursorLibraryWithDictionary:(NSDictionary *)dictionary;
+ (MCCursorLibrary *)cursorLibraryWithCursors:(NSSet *)cursors;

- (instancetype)initWithContentsOfFile:(NSString *)path;
- (instancetype)initWithContentsOfURL:(NSURL *)URL;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithCursors:(NSSet *)cursors;

- (NSSet *)cursorsWithIdentifier:(NSString *)identifier;
- (void)addCursor:(MCCursor *)cursor;
- (void)removeCursor:(MCCursor *)cursor;
- (void)removeCursorsWithIdentifier:(NSString *)identifier;

- (NSDictionary *)dictionaryRepresentation;
- (BOOL)writeToFile:(NSString *)file atomically:(BOOL)atomically;
- (NSError *)save;

- (void)updateChangeCount:(NSDocumentChangeType)change;
- (void)revertToSaved;

@end

@interface MCCursorLibrary (Properties)
@property (nonatomic, readonly, strong) NSSet *cursors;
@end