//
//  MCEditCapeController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/3/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCEditCapeController.h"
#import "MCLibraryController.h"

@interface MCEditCapeController ()

@end

@implementation MCEditCapeController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)validateValue:(inout __autoreleasing id *)ioValue forKeyPath:(NSString *)inKeyPath error:(out NSError *__autoreleasing *)outError {
    if ([inKeyPath isEqualToString:@"cursorLibrary.identifier"]) {
        BOOL valid = [self.cursorLibrary.library capesWithIdentifier:*ioValue].count == 0;
        if (!valid) {
            *outError = [NSError errorWithDomain:MCErrorDomain code:MCErrorMultipleCursorIdentifiersCode userInfo:@{ NSLocalizedDescriptionKey: @"A cape with this identifier already exists" }];
        }
        return valid;
    }
    
    return YES;
}


@end
