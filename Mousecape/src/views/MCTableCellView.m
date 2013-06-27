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
@property (nonatomic, strong) NSArray *sortedValues;
@end

@implementation MCTableCellView
- (void)viewDidMoveToWindow {
    @weakify(self);
    
    [RACAbleWithStart(self.cursorLine) subscribeNext:^(MCCursorLine *cursorLine) {
        @strongify(self);
        cursorLine.dataSource = self;
    }];
    
    [self.textField rac_bind:NSValueBinding toObject:self withKeyPath:@"objectValue.library.name"];
    [[RACAbleWithStart(self.backgroundStyle) deliverOn:[RACScheduler mainThreadScheduler]] subscribeNext:^(id x) {
        @strongify(self);
        if (self.backgroundStyle == NSBackgroundStyleDark)
            self.hdView.image = [NSImage imageNamed:@"HD-alt"];
        else
            self.hdView.image = [NSImage imageNamed:@"HD"];
    }];
    
    [RACAbleWithStart(self.objectValue.library.cursors) subscribeNext:^(NSSet *cursors) {
        @strongify(self);
        self.sortedValues = [cursors sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"prettyName" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
        [self.cursorLine reloadData];
    }];
    
}

- (MCCursorDocument *)objectValue {
    return (MCCursorDocument *)[super objectValue];
}

- (void)layout {
#define SIDESPACING 14.0
#define ITEMSPACING 8.0
    
    [super layout];
    
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
}

#pragma mark - MCCursorLineDataSource
- (NSUInteger)numberOfCursorsInLine:(MCCursorLine *)cursorLine {
    return self.sortedValues.count;
}

- (MCCursor *)cursorLine:(MCCursorLine *)cursorLine cursorAtIndex:(NSUInteger)index {
    return [self.sortedValues objectAtIndex:index];
}

@end
