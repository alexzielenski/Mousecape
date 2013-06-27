//
//  MCCursorDocument.m
//  Mousecape
//
//  Created by Alex Zielenski on 6/25/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCCursorDocument.h"
#import "MCCloakController.h"
#import "MCEditWindowController.h"

@interface MCCursorDocument ()
- (void)startObservingLibrary:(MCCursorLibrary *)library;
- (void)stopObservingLibrary:(MCCursorLibrary *)library;
@end

static void *MCCursorDocumentContext;

@implementation MCCursorDocument

- (id)init {
    if ((self = [super init])) {
        @weakify(self);
        [[RACAble(self.library) mapPreviousWithStart:nil
                                             combine:^id(id previous, id current) {
                                                 if (previous && current)
                                                     return @[previous, current];
                                                 else if (previous)
                                                     return @[];
                                                 return @[current];
                                             }] subscribeNext:^(NSArray *x) {
            @strongify(self);

            if (x.count > 1)
                [self stopObservingLibrary:x[0]];
            [self startObservingLibrary:x.lastObject];
        }];
        
        self.library = [[MCCursorLibrary alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [self stopObservingLibrary:self.library];
}

- (void)startObservingLibrary:(MCCursorLibrary *)library {
    // Observe top level features
    [library addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld context:&MCCursorDocumentContext];
    [library addObserver:self forKeyPath:@"author" options:NSKeyValueObservingOptionOld context:&MCCursorDocumentContext];
    [library addObserver:self forKeyPath:@"identifier" options:NSKeyValueObservingOptionOld context:&MCCursorDocumentContext];
    [library addObserver:self forKeyPath:@"version" options:NSKeyValueObservingOptionOld context:&MCCursorDocumentContext];
    [library addObserver:self forKeyPath:@"cursors" options:NSKeyValueObservingOptionOld context:&MCCursorDocumentContext];
    
    for (NSString *key in self.library.cursors)
        [self startObservingCursor:self.library.cursors[key]];
    
}

static void *MCCursorContext;
- (void)startObservingCursor:(MCCursor *)cursor {
    [cursor addObserver:self forKeyPath:@"frameDuration" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
    [cursor addObserver:self forKeyPath:@"frameCount" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
    [cursor addObserver:self forKeyPath:@"size" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
    [cursor addObserver:self forKeyPath:@"hotSpot" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
    [cursor addObserver:self forKeyPath:@"identifier" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
}

- (void)stopObservingLibrary:(MCCursorLibrary *)library {
    [library removeObserver:self forKeyPath:@"name"];
    [library removeObserver:self forKeyPath:@"author"];
    [library removeObserver:self forKeyPath:@"identifier"];
    [library removeObserver:self forKeyPath:@"version"];
    [library removeObserver:self forKeyPath:@"cursors"];
    
    for (MCCursor *cursor in self.library.cursors)
        [self stopObservingCursor:cursor];
}

- (void)stopObservingCursor:(MCCursor *)cursor {
    [cursor removeObserver:self forKeyPath:@"frameDuration"];
    [cursor removeObserver:self forKeyPath:@"frameCount"];
    [cursor removeObserver:self forKeyPath:@"size"];
    [cursor removeObserver:self forKeyPath:@"hotSpot"];
    [cursor removeObserver:self forKeyPath:@"identifier"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != &MCCursorDocumentContext && context != &MCCursorContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if (context == &MCCursorContext) {
        MCCursor *proxy = [self.undoManager prepareWithInvocationTarget:object];
        id oldValue = change[NSKeyValueChangeOldKey];
        
        NSString *action = keyPath.capitalizedString;
        
        // Primitives
        if ([keyPath isEqualToString:@"frameDuration"]) {
            [proxy setFrameDuration:[(NSNumber *)oldValue doubleValue]];
            action = @"Frame Duration";
        } else if ([keyPath isEqualToString:@"frameCount"]) {
            [proxy setFrameCount:[(NSNumber *)oldValue unsignedIntegerValue]];
            action = @"Frame Count";
        } else if ([keyPath isEqualToString:@"size"]) {
            [proxy setSize:[(NSValue *)oldValue sizeValue]];
        } else if ([keyPath isEqualToString:@"hotSpot"]) {
            [proxy setHotSpot:[(NSValue *)oldValue pointValue]];
            action = @"Hot Spot";
        } else {
            // Other stuffs
            [proxy setValue:[oldValue copy] forKeyPath:keyPath];
        }
            
        
        if (!self.undoManager.isUndoing)
            [self.undoManager setActionName:[NSString stringWithFormat:@"Edit %@", action]];
        
        return;
    }
    
    if ([keyPath isEqualToString:@"cursors"]) {
        NSLog(@"%@", change);
        return;
    }
    
    [(MCCursorLibrary *)[self.undoManager prepareWithInvocationTarget:object] setValue:[(NSString *)[change objectForKey:NSKeyValueChangeOldKey] copy] forKeyPath:keyPath];
    if (!self.undoManager.isUndoing)
        [self.undoManager setActionName:[NSString stringWithFormat:@"Edit %@", keyPath.capitalizedString]];
        
}

- (void)makeWindowControllers {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MCCursorDocumentWantsAdoptionNotification" object:self];
}

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError **)outError {
    return [self.library writeToFile:absoluteURL.path atomically:NO];
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {        
    [self.undoManager disableUndoRegistration];
    self.library = [[MCCursorLibrary alloc] initWithContentsOfURL:absoluteURL];
    [self.undoManager enableUndoRegistration];
    
    return YES;
}

- (BOOL)isEntireFileLoaded {
    return !(!self.library);
}

+ (BOOL)autosavesInPlace {
    return NO;
}

- (BOOL)hasUndoManager {
    return YES;
}

- (NSString *)displayName {
    return self.library.name;
}

- (NSDocument *)duplicateAndReturnError:(NSError *__autoreleasing *)outError {
    MCCursorDocument *doc = [[MCCursorDocument alloc] initWithType:@"cape" error:nil];
    doc.library = [self.library copy];
    doc.library.identifier = [doc.library.identifier stringByAppendingFormat:@".%f", [NSDate timeIntervalSinceReferenceDate]];
    
    // register the document
    [[NSDocumentController sharedDocumentController] addDocument:self];
    [doc makeWindowControllers];
    
    *outError = nil;
    return doc;
}

#pragma mark - Actions

- (void)apply:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[MCCloakController sharedCloakController] applyCape:self];
    });
}

- (IBAction)remove:(id)sender {
    // Set our file path to nil and remove the cape file.
    NSError *err = nil;
    [[NSFileManager defaultManager] removeItemAtURL:self.fileURL error:&err];
    if (err) {
        //!TODO: Do something with the error
        return;
    }
    self.fileURL = nil;
    
    // Send a notification saying we have been disavowed
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MCCursorDocumentOrphanedNotification" object:self];
}

- (void)edit:(id)sender {
    if (!self.editWindowController)
        self.editWindowController = [[MCEditWindowController alloc] initWithWindowNibName:@"EditWindow"];
    
    [self addWindowController:self.editWindowController];
    [self showWindows];
}

#pragma mark - Wrapper
- (NSString *)name {
    return self.library.name;
}

- (NSString *)author {
    return self.library.author;
}

- (NSString *)identifier {
    return self.library.identifier;
}

- (NSNumber *)version {
    return self.library.version;
}

- (BOOL)isInCloud {
    return self.library.isInCloud;
}

- (BOOL)isHiDPI {
    return self.library.isHiDPI;
}
- (NSDictionary *)cursors {
    return self.library.cursors;
}

@end
