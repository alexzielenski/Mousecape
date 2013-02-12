//
//  MCAppDelegate.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCAppDelegate.h"
#import "NSFileManager+DirectoryLocations.h"
#import "MCCursorLibrary.h"

@interface MCAppDelegate ()

@end

@implementation MCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.window.contentView invalidateIntrinsicContentSize];
    [self.window.contentView setNeedsLayout:YES];

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
    NSString *appSupport = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSString *capesPath  = [appSupport stringByAppendingPathComponent:@"capes"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:capesPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    [self.libraryController loadLibraryAtPath:capesPath];
    
    [self.detailController bind:@"currentLibrary" toObject:self.libraryController withKeyPath:@"selectedLibrary" options:nil];
    
}
- (void)applicationWillTerminate:(NSNotification *)notification {
    [self.detailController unbind:@"currentLibrary"];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    if (![filename.pathExtension.lowercaseString isEqualToString:@"cape"])
        return NO;
    
    // add to library
    NSError *err = [self.libraryController addToLibrary:filename];
    if (err) {
        NSRunAlertPanel(@"Could not add cursor to library", err.localizedDescription ? err.localizedDescription : @"These are not the droids you are looking for", @"Crap", nil,  nil);
    }
    
    return YES;
}

@end
