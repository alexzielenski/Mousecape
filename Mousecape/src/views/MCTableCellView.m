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
+ (void)initialize {
    [self exposeBinding:@"applied"];
}

- (void)_initialize {
    [self addObserver:self forKeyPath:@"objectValue" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"cursorLine" options:NSKeyValueObservingOptionOld context:nil];
    [self addObserver:self forKeyPath:@"appliedView" options:NSKeyValueObservingOptionOld context:nil];
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
        [self unbind:@"applied"];
        [self bind:@"applied" toObject:self.objectValue withKeyPath:@"applied" options:nil];
        
        self.textField.stringValue = [self.objectValue valueForKey:@"name"];
        [self.cursorLine reloadData];
        
    } else if ([keyPath isEqualToString:@"cursorLine"]) {
        MCCursorLine *line = [change valueForKey:NSKeyValueChangeOldKey];
        if (line && ![line isKindOfClass:[NSNull class]] && line.dataSource == self)
            line.dataSource = nil;
        self.cursorLine.dataSource = self;
        
    } else if ([keyPath isEqualToString:@"appliedView"]) {
        NSImageView *oldView = [change valueForKey:NSKeyValueChangeOldKey];
        if (oldView && ![oldView isKindOfClass:[NSNull class]])
            [oldView unbind:@"hidden"];
        
        [self.appliedView bind:@"hidden" toObject:self withKeyPath:@"applied" options:@{NSValueTransformerNameBindingOption: NSNegateBooleanTransformerName}];
    }
}
- (void)viewDidMoveToWindow {

}
- (void)dealloc {
    [self removeObserver:self forKeyPath:@"objectValue"];
    [self removeObserver:self forKeyPath:@"cursorLine"];
    [self removeObserver:self forKeyPath:@"appliedView"];
}
- (void)drawRect:(NSRect)dirtyRect {
    
}

#pragma mark - MCCursorLineDataSource
- (NSUInteger)numberOfCursorsInLine:(MCCursorLine *)cursorLine {
    return [[self.objectValue valueForKeyPath:@"cursors"] count];
}
- (MCCursor *)cursorLine:(MCCursorLine *)cursorLine cursorAtIndex:(NSUInteger)index {
    return [[[[self.objectValue valueForKeyPath:@"cursors"] allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]] objectAtIndex:index];
}

@end
