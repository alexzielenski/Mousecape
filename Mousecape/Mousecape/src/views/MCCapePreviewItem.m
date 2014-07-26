//
//  MCCapePreviewItem.m
//  Mousecape
//
//  Created by Alex Zielenski on 3/10/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCCapePreviewItem.h"

@interface MCCapePreviewItem ()

@end

@implementation MCCapePreviewItem

- (id)init {
    if ((self = [super init])) {
        self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 40, 40)];

        MMAnimatingImageView *im = [[MMAnimatingImageView alloc] initWithFrame:self.view.frame];
        self.animatingImageView  = im;
        self.animatingImageView.shouldAllowDragging = NO;
        [self.view addSubview:im];

        [self.animatingImageView bind:@"image" toObject:self withKeyPath:@"representedObject.imageWithAllReps" options:nil];
        [self.animatingImageView bind:@"frameCount" toObject:self withKeyPath:@"representedObject.frameCount" options:nil];
        [self.animatingImageView bind:@"frameDuration" toObject:self withKeyPath:@"representedObject.frameDuration" options:nil];
        [self.animatingImageView bind:@"shouldFlipHorizontally"
                             toObject:[NSUserDefaults standardUserDefaults]
                          withKeyPath:MCPreferencesHandednessKey
                              options:nil];
    }

    return self;
}

- (void)dealloc {
    [self.animatingImageView unbind:@"shouldFlipHorizontally"];
    [self.animatingImageView unbind:@"image"];
    [self.animatingImageView unbind:@"frameCount"];
    [self.animatingImageView unbind:@"frameDuration"];
}

@end
