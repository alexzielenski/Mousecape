//
//  MCCursorLine.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCCursorLine.h"
#import "MMAnimatingImageView.h"

@interface MCCursorView : NSView
@property (strong) MCCursor *cursor;
@property (strong) NSTextField *textField;
@property (strong) MMAnimatingImageView *imageView;
@property (weak)   MCCursorLine *parentLine;
@property (assign, getter = isSelected) BOOL selected;
@end

@interface MCCursorLine ()
@property (strong) NSMutableArray *cursorViews;
@property (readwrite, strong) NSMutableIndexSet *selectedCursorIndices;

- (void)_initialize;
- (NSRect)frameForCursorAtIndex:(NSUInteger)index;
- (void)cursorView:(MCCursorView *)cv selected:(BOOL)selected;
- (MCCursorView *)_dequeueCursorViewForIndex:(NSUInteger)index;
- (NSUInteger)limitedItemCount;

@end

@implementation MCCursorView

- (id)init {
    if ((self = [super init])) {
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;

        if (!self.textField) {
            NSTextField *tf = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 14)];
            self.textField = tf;
            self.textField.stringValue     = @"Unknown";
//            self.textField.font            = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize] - 1];
            self.textField.bezeled         = NO;
            self.textField.drawsBackground = NO;
            self.textField.editable        = NO;
            self.textField.selectable      = NO;
            self.textField.alignment       = NSCenterTextAlignment;
            ((NSTextFieldCell *)self.textField.cell).lineBreakMode = NSLineBreakByTruncatingTail;
        }
        
        if (!self.imageView) {
            MMAnimatingImageView *im = [[MMAnimatingImageView alloc] init];
            self.imageView = im;
        }

        @weakify(self);
        
        RAC(self.imageView.shouldAnimate) = RACAble(self.parentLine.animationsEnabled);
        RAC(self.textField.stringValue)   = RACAble(self.cursor.prettyName);
        RAC(self.imageView.frameDuration) = RACAble(self.cursor.frameDuration);
        RAC(self.imageView.frameCount)    = RACAble(self.cursor.frameCount);
        RAC(self.imageView.image)         = RACAble(self.cursor.imageWithAllReps);
        
        [RACAble(self.selected) subscribeNext:^(NSNumber *selected) {
            @strongify(self);
            [self.parentLine cursorView:self selected:selected.boolValue];
        }];
    }
    return self;
}

- (void)viewDidMoveToWindow {
    self.imageView.frame = NSMakeRect(8.0f, 16.0f, 48.0f, 48.0f);
    self.textField.frame = NSMakeRect(0, 2.0f, 64.0f, 14.0f);
    
    MMAnimatingImageView *imageView = self.imageView;
    NSTextField *textField = self.textField;
    
    [self addSubview:self.imageView];
    [self addSubview:self.textField];
    
    [textField setFrame:NSMakeRect(0, 2, self.bounds.size.width, 14.0)];
    [imageView setFrame:NSMakeRect(NSMidX(self.bounds) - NSMidX(imageView.bounds), NSMaxY(textField.frame), 48, 48)];
    
    
    // auto layout causes issues with View-Based Table Views
    /*
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(8)-[imageView(==48)]-(8)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(imageView)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(3)-[textField]-(3)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(textField)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView][textField(==14)]-(2)-|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(imageView, textField)]];
     */

}

- (void)drawRect:(NSRect)rect {
    [super drawRect:rect];
    
    if (self.isSelected && self.parentLine.shouldAllowSelection) {
        [self.parentLine.highlightColor set];
        NSRectFillUsingOperation(rect, NSCompositeSourceOver);
        
        // draw separators
        NSUInteger myIndex = [self.parentLine.cursorViews indexOfObject:self];
        NSUInteger leftIndex = myIndex - 1;
        NSUInteger rightIndex = myIndex + 1;
        
        NSIndexSet *indices = [self.parentLine selectedCursorIndices];
        
        NSColor *sepColor =  [NSColor colorWithDeviceWhite:0.0 alpha:0.2];
        [sepColor set];
        
        if (![indices containsIndex:rightIndex] || myIndex < rightIndex) {
            // right separator
            NSRectFillUsingOperation(NSMakeRect(NSMaxX(self.bounds) - 1, 0, 1.0, NSHeight(self.bounds)), NSCompositeSourceOver);
        }
        if (myIndex == 0 || (![indices containsIndex:leftIndex])) {
            // left separator
            NSRectFillUsingOperation(NSMakeRect(0.0, 0, 1.0, NSHeight(self.bounds)), NSCompositeSourceOver);
        }
    }
    
}

- (void)mouseDown:(NSEvent *)event {
    if ((event.modifierFlags & self.parentLine.selectionKeyMask) == self.parentLine.selectionKeyMask || event.clickCount >= 2) {
        if (event.clickCount == 2)
            self.selected = !self.isSelected;
    } else {
        [super mouseDown:event];
    }
}

@end

@implementation MCCursorLine
- (void)_initialize {
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;

    self.animationsEnabled = YES;
    self.wellWidth = 64.0f;
    self.cursorViews = [NSMutableArray array];
    self.shouldAllowSelection = YES;
    self.highlightColor = [NSColor colorWithDeviceRed:0.71 green:0.843 blue:1.0 alpha:1.0];
    self.selectedCursorIndices = [NSMutableIndexSet indexSet];
    self.selectionKeyMask = NSCommandKeyMask;
    self.shouldLimitToBounds = YES;
    
    __weak MCCursorLine *weakSelf = self;
    [RACAble(self.dataSource) subscribeNext:^(id x) {
        [weakSelf reloadData];
    }];
    
    [RACAble(self.shouldAllowSelection) subscribeNext:^(NSNumber *x) {
        if (!x.boolValue)
            [weakSelf deselectAll];
    }];
    
}

- (id)init {
    if ((self = [super init])) {
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

- (id)initWithFrame:(NSRect)frame {

    self = [super initWithFrame:frame];
    if (self) {
        [self _initialize];
    }
    
    return self;
}

- (void)reloadData {    
    NSUInteger itemCount = [self.dataSource numberOfCursorsInLine:self];
    NSUInteger limitedItemCount = self.limitedItemCount;
    
    if (self.shouldLimitToBounds)
        itemCount = MIN(itemCount, limitedItemCount);
    
    while (self.cursorViews.count > itemCount) {
        if (self.cursorViews.count > itemCount) {
            [[self.cursorViews lastObject] removeFromSuperview];
            [self.cursorViews removeLastObject];
        }
    }
    
    for (NSUInteger idx = 0; idx < itemCount; idx++) {
        MCCursor *currentCursor = [self.dataSource cursorLine:self cursorAtIndex:idx];
        MCCursorView *cursorView = [self _dequeueCursorViewForIndex:idx];
        cursorView.parentLine = self;
        cursorView.selected   = NO;
        
        cursorView.frame = [self frameForCursorAtIndex:idx];
        [self addSubview:cursorView];
        
        cursorView.cursor = currentCursor;
    }
    
    // resize us to fit
    self.frame = NSMakeRect(self.frame.origin.x, self.frame.origin.y, itemCount * self.wellWidth, self.frame.size.height);
}

- (NSUInteger)limitedItemCount {
    return floor(self.enclosingScrollView.documentVisibleRect.size.width / self.wellWidth);
}

- (MCCursorView *)_dequeueCursorViewForIndex:(NSUInteger)index {
    if (self.cursorViews.count > index) {
        return self.cursorViews[index];
    }
    
    if (index != self.cursorViews.count)
        return nil;
    
    self.cursorViews[index] = [[MCCursorView alloc] init];
    return self.cursorViews[index];
}

- (NSRect)frameForCursorAtIndex:(NSUInteger)index {
    return NSMakeRect(index * self.wellWidth, 0, self.wellWidth, self.frame.size.height);
}

- (void)cursorView:(MCCursorView *)cv selected:(BOOL)selected {
    if (self.shouldAllowSelection && selected) {
        [self.selectedCursorIndices addIndex:[self.cursorViews indexOfObject:cv]];
    } else {
        [self.selectedCursorIndices removeIndex:[self.cursorViews indexOfObject:cv]];
    }
    
    [self.cursorViews makeObjectsPerformSelector:@selector(display)];
}

- (void)deselectAll {
    self.selectedCursorIndices = [NSMutableIndexSet indexSet];
    
    for (MCCursorView *view in self.cursorViews) {
        view.selected = NO;
    }
}

@end
