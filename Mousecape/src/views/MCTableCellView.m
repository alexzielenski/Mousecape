//
//  MCTableCellView.m
//  ;
//
//  Created by Alex Zielenski on 2/10/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCTableCellView.h"
#import "MCCursorDocument.h"

@interface MCTableCellView ()
- (void)_initialize;
@end

@implementation MCTableCellView
- (void)_initialize {
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

- (void)viewDidMoveToWindow {
    @weakify(self);
    
    RAC(self.cursorLine.dataSource) = [RACSignal return:self];
    [self.textField rac_bind:NSValueBinding toObject:self withKeyPath:@"objectValue.library.name"];
    [[RACAble(self.backgroundStyle) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        if (self.backgroundStyle == NSBackgroundStyleDark)
            self.hdView.image = [NSImage imageNamed:@"HD-alt"];
        else
            self.hdView.image = [NSImage imageNamed:@"HD"];
    }];
    
}

- (void)layout {
#define SIDESPACING 14.0
#define ITEMSPACING 8.0
    
    if (self.hdView.isHidden) {
        NSRect frame = self.appliedView.frame;
        frame.origin.x = self.frame.size.width - SIDESPACING - frame.size.width;
        
        self.appliedView.frame = frame;
    } else {
        NSRect frame = self.appliedView.frame;
        NSRect hdFrame = self.hdView.frame;
        
        hdFrame.origin.x = self.frame.size.width - SIDESPACING - hdFrame.size.width;
        frame.origin.x   = hdFrame.origin.x - ITEMSPACING - frame.size.width;
        
        self.hdView.frame = hdFrame;
        self.appliedView.frame = frame;
    }
    
    [super layout];
    
}

#pragma mark - MCCursorLineDataSource
- (NSUInteger)numberOfCursorsInLine:(MCCursorLine *)cursorLine {
    return [[self.objectValue valueForKeyPath:@"cursors"] count];
}

- (MCCursor *)cursorLine:(MCCursorLine *)cursorLine cursorAtIndex:(NSUInteger)index {
    //!TODO: Sort somewhere else
    return [[[self.objectValue valueForKey:@"cursors"] allValues] objectAtIndex:index];
//    return [[[[self.objectValue valueForKeyPath:@"cursors"] allValues] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"prettyName" ascending:YES selector:@selector(caseInsensitiveCompare:)]]] objectAtIndex:index];
}

@end
