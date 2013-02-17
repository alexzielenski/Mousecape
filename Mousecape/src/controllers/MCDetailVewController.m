//
//  MCDetailVewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/11/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCDetailVewController.h"
#import "MCCloakController.h"
#import "CGSCursor.h"

@interface MCDetailVewController ()

@end

@implementation MCDetailVewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self addObserver:self forKeyPath:@"currentLibrary" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self addObserver:self forKeyPath:@"currentLibrary" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}
- (void)dealloc {
    [self removeObserver:self forKeyPath:@"currentLibrary"];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"currentLibrary"]) {
        
        if (self.currentLibrary) {
            self.titleLabel.stringValue = self.currentLibrary.name;
            self.authorLabel.stringValue = self.currentLibrary.author;
            self.versionLabel.stringValue = [NSString stringWithFormat:@"%.01f", self.currentLibrary.version.floatValue];
        } else {
            self.titleLabel.stringValue = @"No Cursor Selected";
            self.authorLabel.stringValue = @"";
            self.versionLabel.stringValue = @"";
        }
    }
}
- (IBAction)apply:(id)sender {
    if (!self.currentLibrary)
        return;
    
    __block MCDetailVewController *blockSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[MCCloakController sharedCloakController] applyCape:blockSelf.currentLibrary];
    });
}
- (IBAction)restore:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[MCCloakController sharedCloakController] restoreDefaults];
    });
}
- (IBAction)update:(id)sender {
    
}

@end
