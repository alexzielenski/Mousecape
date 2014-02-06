//
//  MCEditCapeController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/3/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCEditCapeController.h"

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
    
#warning TODO: check if library has this identifier
    NSLog(@"validate %@", inKeyPath);
    return YES;
}

@end
