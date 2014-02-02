//
//  MCLibraryController.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCursorLibrary.h"
@interface MCLibraryController : NSObject
@property (weak) MCCursorLibrary *appliedCape;

+ (instancetype)sharedLibraryController;
- (void)importCursorLibraryAtURL:(NSURL *)url;

- (void)addCape:(MCCursorLibrary *)cape;
- (void)removeCape:(MCCursorLibrary *)cape;

- (void)applyCape:(MCCursorLibrary *)cape;

@end

@interface MCLibraryController (Capes)
@property (nonatomic, readonly) NSOrderedSet *capes;
@end