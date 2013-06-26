//
//  MCDetailVewController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/11/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCDetailVewController.h"
#import "MCCloakController.h"
#import "MCLibraryWindowController.h"
#import "CGSCursor.h"

@interface MCDetailVewController ()
- (void)_commonInit;
@end

@implementation MCDetailVewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self _commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    RAC(self.titleLabel.stringValue) = [RACAble(self.windowController.currentCursor.library.name) map:^NSString *(NSString *value) {
        return (value) ? value : NSLocalizedString(@"No Cursor Selected", @"Detail pane, no selection");
    }];
    RAC(self.authorLabel.stringValue) = [RACAble(self.windowController.currentCursor.library.author) map:^(NSString *value) {
        return (value) ? value : @"";
    }];
    RAC(self.versionLabel.objectValue) = [RACAble(self.windowController.currentCursor.library.version) map:^(NSNumber *value) {
        return [NSString stringWithFormat:@"%.01f", value.floatValue];
    }];
}

- (IBAction)update:(id)sender {
    
}

@end
