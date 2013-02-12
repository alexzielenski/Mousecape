//
//  MCTableCellView.m
//  ;
//
//  Created by Alex Zielenski on 2/10/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCTableCellView.h"

@implementation MCTableCellView

- (id)init {
    if ((self = [super init])) {
    }
    return self;
}
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addObserver:self forKeyPath:@"objectValue" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"cursorLine" options:NSKeyValueObservingOptionOld context:nil];
    }
    
    return self;
}
- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self addObserver:self forKeyPath:@"objectValue" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"cursorLine" options:NSKeyValueObservingOptionOld context:nil];
    }
    return self;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"objectValue"]) {
        self.textField.stringValue = [self.objectValue valueForKey:@"name"];
        [self.cursorLine reloadData];
        
    } else if ([keyPath isEqualToString:@"cursorLine"]) {
        MCCursorLine *line = [change valueForKey:NSKeyValueChangeOldKey];
        if (line && ![line isKindOfClass:[NSNull class]] && line.dataSource == self)
            line.dataSource = nil;
        self.cursorLine.dataSource = self;
        
    }
}
- (void)viewDidMoveToWindow {

}
- (void)dealloc {
    [self removeObserver:self forKeyPath:@"objectValue"];
    [self removeObserver:self forKeyPath:@"cursorLine"];
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
