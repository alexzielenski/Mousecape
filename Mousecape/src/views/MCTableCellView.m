//
//  MCTableCellView.m
//  ;
//
//  Created by Alex Zielenski on 2/10/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCTableCellView.h"

@interface MCTableCellView ()
- (void)_initialize;
@end

@implementation MCTableCellView
- (void)_initialize {
    [self addObserver:self forKeyPath:@"objectValue" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"cursorLine" options:NSKeyValueObservingOptionOld context:nil];
}

- (id)init {
    if ((self = [super init])) {
        [self _initialize];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _initialize];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self _initialize];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"objectValue"]) {
        id oldValue = [change valueForKey:NSKeyValueChangeOldKey];
        if (oldValue && ![oldValue isKindOfClass:[NSNull class]])
            [oldValue removeObserver:self forKeyPath:@"applied"];
        
        [self.objectValue addObserver:self forKeyPath:@"applied" options:NSKeyValueObservingOptionOld context:nil];        
        [self.cursorLine reloadData];
        
    } else if ([keyPath isEqualToString:@"cursorLine"]) {
        MCCursorLine *line = [change valueForKey:NSKeyValueChangeOldKey];
        if (line && ![line isKindOfClass:[NSNull class]] && line.dataSource == self)
            line.dataSource = nil;
        
        self.cursorLine.dataSource = self;
        
    } else if ([keyPath isEqualToString:@"applied"]) {
        BOOL applied = [[self.objectValue valueForKeyPath:@"applied"] boolValue];
        NSNumber *oldValue = [change valueForKey:NSKeyValueChangeOldKey];
        
        // dont dirty the layout if nothing happened
        if (oldValue && ![oldValue isKindOfClass:[NSNull class]]) {
            if (oldValue.boolValue == applied) {
                return;
            }
        }
        
        [self layout];
    }
}

- (void)layout {
    [super layout];
    
    BOOL applied = [[self.objectValue valueForKeyPath:@"applied"] boolValue];
    
    if (!applied) {
        self.hdView.frame = NSMakeRect(self.bounds.size.width - self.hdView.frame.size.width - (self.bounds.size.width - self.appliedView.frame.origin.x - self.appliedView.frame.size.width), self.hdView.frame.origin.y, self.hdView.frame.size.width, self.hdView.frame.size.height);
    } else {
        self.hdView.frame = NSMakeRect(self.bounds.size.width - self.hdView.frame.size.width - (self.bounds.size.width - self.appliedView.frame.origin.x - self.appliedView.frame.size.width) - 8 - self.appliedView.frame.size.width, self.hdView.frame.origin.y, self.hdView.frame.size.width, self.hdView.frame.size.height);
    }
    
    //!TODO After I layer backed the scroll view the apply checkbox stopped re-displaying
}
- (void)dealloc {
    [self.objectValue removeObserver:self forKeyPath:@"applied"];
    [self removeObserver:self forKeyPath:@"objectValue"];
    [self removeObserver:self forKeyPath:@"cursorLine"];
}

#pragma mark - MCCursorLineDataSource
- (NSUInteger)numberOfCursorsInLine:(MCCursorLine *)cursorLine {
    return [[self.objectValue valueForKeyPath:@"cursors"] count];
}

- (MCCursor *)cursorLine:(MCCursorLine *)cursorLine cursorAtIndex:(NSUInteger)index {
    //!TODO: Sort somewhere else
    return [[[[self.objectValue valueForKeyPath:@"cursors"] allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"prettyName" ascending:YES selector:@selector(caseInsensitiveCompare:)]]] objectAtIndex:index];
//    return [[[self.objectValue valueForKeyPath:@"cursors"] allValues] objectAtIndex:index];
}

@end
