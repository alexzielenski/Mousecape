//
//  MCEditCursorViewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCEditCursorViewController.h"

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

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"cursor"];
}

- (void)_commonInit {
    [self addObserver:self forKeyPath:@"cursor" options:NSKeyValueObservingOptionOld context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    self.imageView.image = self.cursor.imageWithAllReps;
    self.imageView.sampleSize = self.cursor.size;
}

@end
