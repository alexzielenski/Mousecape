//
//  MCGeneralPreferencesController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/9/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCGeneralPreferencesController.h"
#import "scale.h"

@interface MCGeneralPreferencesController ()

@end

@implementation MCGeneralPreferencesController
@dynamic cursorScale;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {

    }
    
    return self;
}

- (id)init {
    return [self initWithNibName:@"GeneralPreferences" bundle:nil];
}

#pragma mark - Accessors
- (float)cursorScale {
    return cursorScale();
}

- (void)setCursorScale:(float)cursorScale {
    [self willChangeValueForKey:@"cursorScale"];
    setCursorScale(cursorScale);
    [[NSUserDefaults standardUserDefaults] setFloat:cursorScale forKey:MCPreferencesCursorScaleKey];
    [self didChangeValueForKey:@"cursorScale"];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier {
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage {
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel {
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

@end
