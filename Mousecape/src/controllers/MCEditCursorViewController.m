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
@dynamic hotSpotValue, sizeValue;

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

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"cursor"];
}

- (void)_commonInit {
    [self addObserver:self forKeyPath:@"cursor" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior context:nil];
    [self addObserver:self forKeyPath:@"cursor.identifier" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"cursor.frameDuration" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"cursor.frameCount" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"cursor.size" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"cursor.hotSpot" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"cursor"]) {
        BOOL isPrior = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
        if (isPrior) {
            [self.undoManager disableUndoRegistration];
            
        } else {
            self.imageView.image      = self.cursor.imageWithAllReps;
            self.imageView.sampleSize = self.cursor.size;
            self.imageView.hotSpot    = self.cursor.hotSpot;
            
            [self willChangeValueForKey:@"hotSpotValue"];
            [self willChangeValueForKey:@"sizeValue"];
            [self didChangeValueForKey:@"hotSpotValue"];
            [self didChangeValueForKey:@"sizeValue"];
            
            [self.undoManager enableUndoRegistration];
        }
    } else {
        if ([change objectForKey:NSKeyValueChangeOldKey] == [change objectForKey:NSKeyValueChangeNewKey])
            return;
        
        if (![[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue]) {
            if ([keyPath isEqualToString:@"cursor.hotSpot"] || [keyPath isEqualToString:@"cursor.size"]) {
                
                self.imageView.sampleSize = self.cursor.size;
                self.imageView.hotSpot    = self.cursor.hotSpot;
                
                [self didChangeValueForKey:@"hotSpotValue"];
                [self didChangeValueForKey:@"sizeValue"];
            }    
            return;
        }
        
        if (!self.cursor)
            return;
        
        if ([keyPath isEqualToString:@"cursor.hotSpot"] || [keyPath isEqualToString:@"cursor.size"]) {
            [self willChangeValueForKey:@"hotSpotValue"];
            [self willChangeValueForKey:@"sizeValue"];
        }
        
        [[self.undoManager prepareWithInvocationTarget:self.cursor] setValue:[change objectForKey:NSKeyValueChangeOldKey] forKey:keyPath.pathExtension];
        NSString *title   = [NSString stringWithFormat:@"Change %@", [keyPath.pathExtension capitalizedString]];
        [self.undoManager setActionName:NSLocalizedString(title, @"Undo")];
    }
}

- (NSUndoManager *)undoManager {
    return self.view.window.undoManager;
}

- (NSValue *)hotSpotValue {
    if (self.cursor)
        return [NSValue valueWithPoint:self.cursor.hotSpot];
    return [NSValue valueWithPoint:NSZeroPoint];
}

- (void)setHotSpotValue:(NSValue *)hotSpotValue {
    self.cursor.hotSpot = hotSpotValue.pointValue;
}

- (NSValue *)sizeValue {
    if (self.cursor)
        return [NSValue valueWithSize:self.cursor.size];
    return [NSValue valueWithSize:NSZeroSize];
}

- (void)setSizeValue:(NSValue *)sizeValue {
    self.cursor.size = sizeValue.sizeValue;
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
