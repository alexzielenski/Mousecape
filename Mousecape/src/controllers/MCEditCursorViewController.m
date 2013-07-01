//
//  MCEditCursorViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCEditCursorViewController.h"
#import "MCCursorLibrary.h"
#import <objc/runtime.h>

@interface MCEditCursorViewController ()
- (void)reloadActionButton;
@end

@implementation MCEditCursorViewController
- (void)loadView {
    [super loadView];
    
    [self.undoManager disableUndoRegistration];
    @weakify(self);

    [self.segmentedControl setSelectedSegment:0];
    
    [self rac_addDeallocDisposable:[[RACAbleWithStart(self.imageView.scale) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSNumber *scale) {
        @strongify(self);
        NSUInteger ctrl = 0;
        CGFloat scl     = scale.doubleValue;
        
        if (scl >= 1.5 && scl < 3.5)
            ctrl = 1;
        else if (scl >= 3.5 && scl < 7.5)
            ctrl = 2;
        else if (scl >= 7.5)
            ctrl = 3;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            self.segmentedControl.selectedSegment = ctrl;
            [self reloadActionButton];
        });
    }]];
    
    [self rac_addDeallocDisposable:[[RACAbleWithStart(self.cursor.representations) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSOrderedSet *reps) {
        @strongify(self);
        NSSize baseSize = NSMakeSize(self.cursor.size.width, self.cursor.size.height * self.cursor.frameCount);
        
        [self.segmentedControl.cell setImage:nil forSegment:0];
        [self.segmentedControl.cell setImage:nil forSegment:1];
        [self.segmentedControl.cell setImage:nil forSegment:2];
        [self.segmentedControl.cell setImage:nil forSegment:3];
        
        for (NSImageRep *rep in reps) {
            CGFloat scl = rep.pixelsWide / baseSize.width;
            NSUInteger ctrl = -1;
            if (scl == 1.0)
                ctrl = 0;
            else if (scl == 2)
                ctrl = 1;
            else if (scl == 5)
                ctrl = 2;
            else if (scl == 10)
                ctrl = 3;
            
            if (ctrl != -1)
                [self.segmentedControl.cell setImage:[NSImage imageNamed:NSImageNameMenuOnStateTemplate] forSegment:ctrl];
            [self reloadActionButton];
        }
    }]];
    
    RAC(self.imageView.image) = [RACAble(self.cursor.imageWithKeyReps) distinctUntilChanged];
    [self.imageView rac_bind:@"hotSpot" toObject:self withKeyPath:@"cursor.hotSpot"];
    [self.imageView rac_bind:@"sampleSize" toObject:self withKeyPath:@"cursor.size"];
    
    [self rac_addDeallocDisposable:[[RACAble(self.imageView.hotSpot) distinctUntilChanged] subscribeNext:^(NSValue *x) {
        @strongify(self);
        if (!NSEqualPoints(x.pointValue, self.cursor.hotSpot))
            self.cursor.hotSpot = x.pointValue;
    }]];
    
    [self.typeButton removeAllItems];
    
    NSDictionary *cursorMap = MCCursorLibrary.cursorMap;
    NSArray *titles = [cursorMap.allValues sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [self.typeButton addItemWithTitle:@"Unknown"];
    [[self.typeButton itemAtIndex:0] setTag:-1];
    
    [self.typeButton.menu addItem:[NSMenuItem separatorItem]];
    
    [self.typeButton addItemsWithTitles:titles];
    
    [RACAbleWithStart(self.cursor.identifier) subscribeNext:^(NSString *x) {
        @strongify(self);
        NSDictionary *map = MCCursorLibrary.cursorMap;
        if (map[x])
            [self.typeButton selectItemWithTitle:map[x]];
        else
            [self.typeButton selectItemWithTag:-1];
    }];
    
    [self.undoManager enableUndoRegistration];
}

- (NSUndoManager *)undoManager {
    return self.view.window.undoManager;
}

#pragma mark - Actions

- (void)reloadActionButton {
    if ([self.cursor representationWithScale:[self.segmentedControl.cell tagForSegment:self.segmentedControl.selectedSegment]]) {
        [self.actionButton setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
        [self.actionButton setTag: 1];
        
        self.imageView.shouldDragToRemove = YES;
    } else {
        [self.actionButton setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
        [self.actionButton setTag:0];
        
        self.imageView.shouldDragToRemove = NO;
    }
}

- (IBAction)segment:(NSSegmentedControl *)sender {
    // In IB the tags are set to the scale value
    self.imageView.scale = [sender.cell tagForSegment:sender.selectedSegment];
}

- (IBAction)actionButton:(NSButton *)sender {
    if (sender.tag == 0) {
        // Add
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        panel.allowedFileTypes = [NSImage imageFileTypes];
        panel.message = [NSString stringWithFormat:@"Set %ldx cursor representation", (long)[self.segmentedControl.cell tagForSegment:self.segmentedControl.selectedSegment]];
        panel.allowsMultipleSelection = NO;
        @weakify(self);
        [panel beginWithCompletionHandler:^(NSInteger result) {
            @strongify(self);
            [self setCurrentImageToFileAtURL:panel.URL];
        }];
    } else {
        // Remove
        [self.cursor removeRepresentation:[self.cursor representationWithScale:[self.segmentedControl.cell tagForSegment:self.segmentedControl.selectedSegment]]];
        
    }
    
    [self reloadActionButton];
}

- (void)setCurrentImageToFileAtURL:(NSURL *)url {
    if (!url)
        return;
    
    NSImageRep *rep = [NSImageRep imageRepWithContentsOfURL:url];
    [self setCurrentImageToImageRep:rep];
}

- (void)setCurrentImageToImageRep:(NSImageRep *)rep {
    NSInteger multiplier = [self.segmentedControl.cell tagForSegment:self.segmentedControl.selectedSegment];
    NSSize size = NSMakeSize(rep.pixelsWide / multiplier, rep.pixelsHigh / multiplier / self.cursor.frameCount);
    
    // If there are no other reps, change the size
    // If there are reps, then scale down the pixel size of the new one and check to see if it is equal
    // to the actual image size
    if (self.cursor.representations.count) {
        // Validate size
        if (size.width != self.cursor.size.width || size.height != self.cursor.size.height) {
            // Invalid size
            NSLog(@"Bad cursor size");
            return;
        }
    } else {
        self.cursor.size = size;
    }
    
    [self.cursor addRepresentation:rep];
}

- (IBAction)changeType:(NSPopUpButton *)sender {
    if (sender.selectedTag == -1) {
        self.cursor.identifier = @"";
        return;
    }
    
    NSString *title = sender.selectedItem.title;
    NSArray *keys  = [MCCursorLibrary.cursorMap allKeysForObject:title];
    
    if (keys.count) {
        self.cursor.identifier = keys[0];
    }
}

#pragma mark - NSDraggingDestination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if ([NSImageRep canInitWithPasteboard:sender.draggingPasteboard] &&
        ![self.cursor representationWithScale:[self.segmentedControl.cell tagForSegment:self.segmentedControl.selectedSegment]])
        return NSDragOperationCopy;
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    return [self draggingEntered:sender];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    return YES;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSArray *reps = [NSImageRep imageRepsWithPasteboard:sender.draggingPasteboard];
    
    if (!reps.count || reps.count > 1)
        return NO;

    NSImageRep *rep = reps[0];
    [self setCurrentImageToImageRep:rep];
    return YES;
}

@end
