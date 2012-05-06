//
//  MMCursorLibrary.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 5/6/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMCursorLibrary.h"

@interface MMCursorLibrary () {
	NSMutableSet *_cursors;
}
@property (retain, readwrite) NSMutableSet *cursors;
@property (copy, readwrite) NSString *libraryPath;

- (BOOL)_validateLibraryPath:(NSString *)path;
- (void)_addCursorAtPath:(NSString *)path;
- (void)_syncWithLibrary;

@end

@implementation MMCursorLibrary
@synthesize libraryPath = _libraryPath;
@synthesize cursors = _cursors;

+ (MMCursorLibrary *)libraryWithPath:(NSString *)path
{
	return [[[self alloc] initWithPath:path] autorelease];
}

- (id)initWithPath:(NSString *)path
{
	if (![self _validateLibraryPath:path]) {
		NSLog(@"Invalid Library Path.");
		
		[self release];
		return nil;
	}
	
	if ((self = [super init])) {
		self.cursors     = [NSMutableSet set];
		self.libraryPath = path;
		
		[self _syncWithLibrary];
	}
	
	return self;
}

- (BOOL)addCursorAtPath:(NSString *)path
{
	if ([[self.cursors valueForKey:path] containsObject:path])
		return NO;
	
	[self _addCursorAtPath:path];
	return YES;
}

- (void)removeCursor:(MMCursorAggregate *)cursor
{
	if (![self.cursors containsObject:cursor])
		return;
	
	[self willChangeValueForKey:@"cursors"];
	
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:cursor.path error:&error];
	
	if (!error)
		[self.cursors removeObject:cursor];
	else {
		NSLog(@"Error Removing Cursor");
		NSLog(@"%@", error);
	}
	
	[self didChangeValueForKey:@"cursors"];
}

- (void)saveCursor:(MMCursorAggregate *)cursor
{
	if (![self.cursors containsObject:cursor]) {
		NSLog(@"Cursor (%@) is not a member of this library", cursor);
		return;
	}
	
	if (!cursor.path) {
		NSLog(@"Cursor (%@) was not instantiated with its path.", cursor);
		return;
	}
	
	[cursor.dictionaryRepresentation writeToFile:cursor.path atomically:NO];
	
}

- (BOOL)_validateLibraryPath:(NSString *)path
{
	if (!path)
		return NO;
	
	NSFileManager *manager = [NSFileManager defaultManager];
	BOOL isDir  = NO;
	BOOL exists = [manager fileExistsAtPath:path isDirectory:&isDir];
	
	if (!exists || !isDir)
		return NO;
	
	return ([manager isReadableFileAtPath:path] && [manager isWritableFileAtPath:path]);
}

- (void)_syncWithLibrary
{
	NSFileManager *manager = [NSFileManager defaultManager];
	NSSet *paths           = [self.cursors valueForKeyPath:@"path"];
	
	NSError *error   = nil;
	NSArray *cursors = [manager contentsOfDirectoryAtPath:self.libraryPath error:&error];
	
	if (error) {
		NSLog(@"%@", error);
		return;
	}
	
	for (NSString *filename in cursors) {
		NSString *path = [self.libraryPath stringByAppendingPathComponent:filename];
		
		if ([paths containsObject:path])
			continue;
		
		[self _addCursorAtPath:path];
	}
	
}

- (void)_addCursorAtPath:(NSString *)path
{
	[self willChangeValueForKey:@"cursors"];
	
	MMCursorAggregate *agg = [MMCursorAggregate aggregateWithContentsOfFile:path];
	[self.cursors addObject:agg];
	
	[self didChangeValueForKey:@"cursors"];
}

@end
