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
static void *MCCursorDocumentLibraryContext;
- (id)init {
    if ((self = [super init])) {
        self.shouldVaryCursorSize = YES;
        [self addObserver:self forKeyPath:@"library" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&MCCursorDocumentLibraryContext];
        self.library = [[MCCursorLibrary alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"library"];
    [self stopObservingLibrary:self.library];
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
    
    if (*outError)
        *outError = nil;
    return doc;
}

#pragma mark - Undo Support

- (void)startObservingLibrary:(MCCursorLibrary *)library {
    if (!library)
        return;
    
    // Observe top level features
    [library addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionOld context:&MCCursorDocumentContext];
    [library addObserver:self forKeyPath:@"author" options:NSKeyValueObservingOptionOld context:&MCCursorDocumentContext];
    [library addObserver:self forKeyPath:@"identifier" options:NSKeyValueObservingOptionOld context:&MCCursorDocumentContext];
    [library addObserver:self forKeyPath:@"version" options:NSKeyValueObservingOptionOld context:&MCCursorDocumentContext];
    [library addObserver:self forKeyPath:@"cursors" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionPrior context:&MCCursorDocumentContext];
    
    for (MCCursor *cursor in library.cursors)
        [self startObservingCursor:cursor];
    
}

static void *MCCursorContext;
- (void)startObservingCursor:(MCCursor *)cursor {
    if (!cursor)
        return;
    
    [cursor addObserver:self forKeyPath:@"frameDuration" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
    [cursor addObserver:self forKeyPath:@"frameCount" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
    [cursor addObserver:self forKeyPath:@"size" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
    [cursor addObserver:self forKeyPath:@"hotSpot" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
    [cursor addObserver:self forKeyPath:@"identifier" options:NSKeyValueObservingOptionOld context:&MCCursorContext];
    [cursor addObserver:self forKeyPath:@"representations" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&MCCursorContext];
}

- (void)stopObservingLibrary:(MCCursorLibrary *)library {
    if (!library)
        return;
    
    [library removeObserver:self forKeyPath:@"name"];
    [library removeObserver:self forKeyPath:@"author"];
    [library removeObserver:self forKeyPath:@"identifier"];
    [library removeObserver:self forKeyPath:@"version"];
    [library removeObserver:self forKeyPath:@"cursors"];
    
    for (MCCursor *cursor in library.cursors)
        [self stopObservingCursor:cursor];
}

- (void)stopObservingCursor:(MCCursor *)cursor {
    if (!cursor)
        return;
    
    [cursor removeObserver:self forKeyPath:@"frameDuration"];
    [cursor removeObserver:self forKeyPath:@"frameCount"];
    [cursor removeObserver:self forKeyPath:@"size"];
    [cursor removeObserver:self forKeyPath:@"hotSpot"];
    [cursor removeObserver:self forKeyPath:@"identifier"];
    [cursor removeObserver:self forKeyPath:@"representations"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != &MCCursorDocumentContext && context != &MCCursorContext && context != &MCCursorDocumentLibraryContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    
    if (context == &MCCursorDocumentLibraryContext) {
        id oldValue = change[NSKeyValueChangeOldKey];
        id newValue = change[NSKeyValueChangeNewKey];
        
        if (![oldValue isKindOfClass:[NSNull class]] && oldValue)
            [self stopObservingLibrary:oldValue];
        if (![newValue isKindOfClass:[NSNull class]] && newValue)
            [self startObservingLibrary:newValue];
        return;
    }
    
    if ([keyPath isEqualToString:@"cursors"]) {
        NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        if (kind == NSKeyValueChangeSetting || kind == NSKeyValueChangeReplacement) {
            NSSet *oldCursors = change[NSKeyValueChangeOldKey];
            for (MCCursor *cursor in oldCursors)
                [self stopObservingCursor:cursor];
            
            NSSet *newCursors = change[NSKeyValueChangeNewKey];
            for (MCCursor *cursor in newCursors)
                [self startObservingCursor:cursor];
            
        } else if (kind == NSKeyValueChangeInsertion) {
            NSSet *objects = change[NSKeyValueChangeNewKey];
            for (MCCursor *cursor in objects) {
                [self startObservingCursor:cursor];
                
                [[self.undoManager prepareWithInvocationTarget:self.library] removeCursor:cursor];
                if (!self.undoManager.isUndoing) {
                    [self.undoManager setActionName:@"Add Cursor"];
                }
            }
        } else if (kind == NSKeyValueChangeRemoval) {
            NSSet *objects = change[NSKeyValueChangeOldKey];
            for (MCCursor *object in objects) {
                [self stopObservingCursor:object];
                
                [[self.undoManager prepareWithInvocationTarget:self.library] addCursor:object];
                if (!self.undoManager.isUndoing) {
                    [self.undoManager setActionName:@"Remove Cursor"];
                }
            }
        }
        
        return;
    } else if (context == &MCCursorContext) {
        if ([object parentLibrary] != self.library)
            return;
        
        if ([keyPath isEqualToString:@"frameCount"] && self.shouldVaryCursorSize) {
            // When th frame count changes, change the size
            MCCursor *cu = (MCCursor *)object;
            CGFloat scale = 1.0;
            NSImageRep *rep = [cu smallestRepresentationWithScale:&scale];
            NSSize size = NSMakeSize(rep.pixelsWide / scale, rep.pixelsHigh / scale / cu.frameCount);
            
            cu.size = size;
        }
        
        MCCursor *proxy = [self.undoManager prepareWithInvocationTarget:object];
        id oldValue = change[NSKeyValueChangeOldKey];
        
        if ([keyPath isEqualToString:@"representations"]) {
            NSKeyValueChange kind = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
            NSString *action = @"";
            
            if (kind == NSKeyValueChangeInsertion) {
                for (NSImageRep *cursor in change[NSKeyValueChangeNewKey])
                    [proxy removeRepresentation:cursor];
                action = @"Add Representation";
            } else if (kind == NSKeyValueChangeRemoval) {
                for (NSImageRep *cursor in oldValue)
                    [proxy addRepresentation:cursor];
                action = @"Remove Representation";
            }
            
            if (action.length && !self.undoManager.isUndoing) {
                [self.undoManager setActionName:action];
            }

            return;
        }
        
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
    
    [(MCCursorLibrary *)[self.undoManager prepareWithInvocationTarget:object] setValue:[(NSString *)[change objectForKey:NSKeyValueChangeOldKey] copy] forKeyPath:keyPath];
    if (!self.undoManager.isUndoing)
        [self.undoManager setActionName:[NSString stringWithFormat:@"Edit %@", keyPath.capitalizedString]];
    
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
- (NSSet *)cursors {
    return self.library.cursors;
}

@end
