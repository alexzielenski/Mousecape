//
//  MCEditCursorViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCEditCursorViewController.h"
#import "MCCursorLibrary.h"

@interface MCEditCursorViewController ()
- (void)_commonInit;
@end

@implementation MCEditCursorViewController

- (id)init {
    if ((self = [super init])) {
        [self _commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self _commonInit];
    }
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        [self _commonInit];
    }
    
    return self;
}

- (void)_commonInit {
    
}

- (void)loadView {
    [super loadView];
    
    RAC(self.imageView.image) = [RACAble(self.cursor.imageWithAllReps) distinctUntilChanged];
    
    [self.identifierField rac_bind:NSValueBinding toObject:self withKeyPath:@"cursor.identifier"];
    [self.frameCountField rac_bind:NSValueBinding toObject:self withKeyPath:@"cursor.frameCount"];
    [self.frameDurationField rac_bind:NSValueBinding toObject:self withKeyPath:@"cursor.frameDuration"];
    [self.hotSpotField rac_bind:NSValueBinding toObject:self withKeyPath:@"cursor.hotSpot"];
    [self.sizeField rac_bind:NSValueBinding toObject:self withKeyPath:@"cursor.size"];
    
    [self.imageView rac_bind:@"hotSpot" toObject:self withKeyPath:@"cursor.hotSpot"];
    [self.imageView rac_bind:@"sampleSize" toObject:self withKeyPath:@"cursor.size"];
}

- (NSUndoManager *)undoManager {
    return self.view.window.undoManager;
}

#pragma mark - NSComboBoxDataSource

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index {
    return [MCCursorLibrary.cursorMap.allKeys objectAtIndex:index];
}

- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
    return MCCursorLibrary.cursorMap.count;
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString {
    NSArray *keys = MCCursorLibrary.cursorMap.allKeys;
    NSArray *vals = MCCursorLibrary.cursorMap.allValues;
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"self BEGINSWITH[cd] %@", uncompletedString];
    NSArray *autoCompletedKeys = [keys filteredArrayUsingPredicate:pred];
    NSArray *autoCompletedVals = [vals filteredArrayUsingPredicate:pred];
    
    BOOL wantsKey = [uncompletedString hasPrefix:@"com.apple"];
    
    if (wantsKey && autoCompletedKeys.count > 0)
        return autoCompletedKeys[0];
    
    if (autoCompletedVals.count > 0)
        return autoCompletedVals[0];
    
    return @"";
    
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString {
    if ([aString hasPrefix:@"com.apple"]) {
        NSArray *keys = MCCursorLibrary.cursorMap.allKeys;
        return [keys indexOfObject:aString];
    } else {
        NSArray *keys = [MCCursorLibrary.cursorMap allKeysForObject:aString];
        if (keys.count > 0){
            return [MCCursorLibrary.cursorMap.allKeys indexOfObject:keys[0]];
        }
    }
    
    return NSNotFound;
}

@end
