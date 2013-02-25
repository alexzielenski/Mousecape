//
//  MCCloakController.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/13/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCCloakController.h"
#import "CGSAccessibility.h"
#import "CGSCursor.h"

NSString *MCCloakControllerDidApplyCursorNotification    = @"MCCloakControllerDidApplyCursorNotification";
NSString *MCCloakControllerDidRestoreCursorNotification  = @"MCCloakControllerDidRestoreCursorNotification";
NSString *MCCloakControllerAppliedCursorKey              = @"MCCloakControllerAppliedCursor";

@interface MCCloakController ()
+ (NSString *)mousecloakPath;
@end

@implementation MCCloakController
@dynamic cursorScale;

+ (MCCloakController *)sharedCloakController {
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}
+ (NSString *)mousecloakPath {
    NSBundle *bndl = [NSBundle mainBundle];
    return [bndl pathForAuxiliaryExecutable:@"mousecloak"];
}
- (void)applyCape:(MCCursorLibrary *)cursor {
    NSString *cursorPath = cursor.originalURL.path;
    
    if (!cursor.originalURL ) {
        cursorPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:cursor.identifier] stringByAppendingPathExtension:@"cape"];
        
        if (![cursor writeToFile:cursorPath atomically:NO]) {
            NSLog(@"Failed to write cape to disk to apply");
            return;
        }
    }

    NSPipe *pipe = [NSPipe pipe];
    
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = self.class.mousecloakPath;
    task.arguments = @[ @"--apply",  cursorPath, @"--suppressCopyright"];
    [task setStandardOutput:pipe];
    
    pipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = handle.availableData;
        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"%@", str);
        (void)str;
    };
    
    [task launch];
    [task waitUntilExit];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [[NSCursor dragCopyCursor] set];
        [[NSCursor arrowCursor] push];
        
    });
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MCCloakControllerDidApplyCursorNotification
                                                        object:self
                                                      userInfo:@{ MCCloakControllerAppliedCursorKey: cursor }];
    
}
- (NSString *)convertMightyMouse:(NSString *)mightyMouse { // and add to library
    NSString *output  = [[NSTemporaryDirectory() stringByAppendingPathComponent:mightyMouse.lastPathComponent].stringByDeletingLastPathComponent stringByAppendingPathExtension:@"cape"];
    
    [[NSFileManager defaultManager] removeItemAtPath:output error:nil];
    
    NSTask *task = [[NSTask alloc] init];

    task.launchPath = self.class.mousecloakPath;
    task.arguments = @[ @"-x", mightyMouse, @"-o", output];
    task.standardInput = [NSPipe pipe];
    
    [task launch];
    
    NSData *breakData = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
    
    [[task.standardInput fileHandleForWriting] writeData:[@"Unknown" dataUsingEncoding:NSUTF8StringEncoding]];
    [[task.standardInput fileHandleForWriting] writeData:breakData];
    [[task.standardInput fileHandleForWriting] writeData:[[NSString stringWithFormat:@"%@.mightymouse.%@", NSBundle.mainBundle.bundleIdentifier, mightyMouse.lastPathComponent.stringByDeletingPathExtension] dataUsingEncoding:NSUTF8StringEncoding]];
    [[task.standardInput fileHandleForWriting] writeData:breakData];
    [[task.standardInput fileHandleForWriting] writeData:[mightyMouse.lastPathComponent.stringByDeletingPathExtension dataUsingEncoding:NSUTF8StringEncoding]];
    [[task.standardInput fileHandleForWriting] writeData:breakData];
    [[task.standardInput fileHandleForWriting] writeData:[@"1.0" dataUsingEncoding:NSUTF8StringEncoding]];
    [[task.standardInput fileHandleForWriting] writeData:breakData];

    [task waitUntilExit];

    return output;
    
}
- (void)restoreDefaults {
    NSTask *task = [NSTask launchedTaskWithLaunchPath:self.class.mousecloakPath arguments:@[ @"--reset", @"--suppressCopyright"]];
    [task waitUntilExit];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        [[NSCursor dragCopyCursor] set];
        [[NSCursor arrowCursor] push];
        
    });
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MCCloakControllerDidRestoreCursorNotification
                                                        object:self
                                                      userInfo:nil];
}
- (float)cursorScale {
    float scale;
    CGSGetCursorScale(CGSMainConnectionID(), &scale);
    return scale;
}
- (void)setCursorScale:(float)cursorScale {
    [self willChangeValueForKey:@"cursorScale"];
    CGSSetCursorScale(CGSMainConnectionID(), cursorScale);
    [self didChangeValueForKey:@"cursorScale"];
}

@end
