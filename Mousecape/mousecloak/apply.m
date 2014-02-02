//
//  apply.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "create.h"
#import "backup.h"
#import "restore.h"

BOOL applyCursorForIdentifier(NSUInteger frameCount, CGFloat frameDuration, CGPoint hotSpot, CGSize size, NSArray *images, NSString *ident, NSUInteger repeatCount) {
    if (frameCount > 24 || frameCount < 1) {
        MMLog(BOLD RED "Frame count of %s out of range [1...24]", ident.UTF8String);
        return NO;
    }

    char *idenfifier = (char *)ident.UTF8String;
    int seed;
    CGError err = CGSRegisterCursorWithImages(CGSMainConnectionID(),
                                              idenfifier,
                                              true,
                                              true,
                                              frameCount,
                                              (__bridge CFArrayRef)images,
                                              size,
                                              hotSpot,
                                              &seed,
                                              CGRectMake(hotSpot.x, hotSpot.y, size.width, size.height),
                                              frameDuration,
                                              0);
    
    return (err == kCGErrorSuccess);
}

BOOL applyCapeForIdentifier(NSDictionary *cursor, NSString *identifier) {
    if (!cursor)
        return NO;
    
    NSNumber *frameCount    = cursor[MCCursorDictionaryFrameCountKey];
    NSNumber *frameDuration = cursor[MCCursorDictionaryFrameDuratiomKey];
    //    NSNumber *repeatCount   = cursor[MCCursorDictionaryRepeatCountKey];
    
    CGPoint hotSpot         = CGPointMake([cursor[MCCursorDictionaryHotSpotXKey] doubleValue],
                                          [cursor[MCCursorDictionaryHotSpotYKey] doubleValue]);
    CGSize size             = CGSizeMake([cursor[MCCursorDictionaryPointsWideKey] doubleValue],
                                         [cursor[MCCursorDictionaryPointsHighKey] doubleValue]);
    NSArray *reps           = cursor[MCCursorDictionaryRepresentationsKey];
    
    NSMutableArray *images  = [NSMutableArray array];
    
    for (id object in reps) {
        CFTypeID type = CFGetTypeID((__bridge CFTypeRef)object);
        
        // special case if array has a type of CGImage already there is no need to convert it
        if (type == CGImageGetTypeID()) {
            images[images.count] = object;
            continue;
        }
        
        CFDataRef pngData = (__bridge CFDataRef)object;
        
        CGDataProviderRef pngProvider = CGDataProviderCreateWithCFData(pngData);
        CGImageRef rep = CGImageCreateWithPNGDataProvider(pngProvider, NULL, false, kCGRenderingIntentDefault);
        CGDataProviderRelease(pngProvider);
        
        images[images.count] = (__bridge id)rep;
        
        CGImageRelease(rep);
        
    }
    
    return applyCursorForIdentifier(frameCount.unsignedIntegerValue, frameDuration.doubleValue, hotSpot, size, images, identifier, 0);
}

BOOL applyCape(NSDictionary *dictionary) {
    
    NSDictionary *cursors = dictionary[MCCursorDictionaryCursorsKey];
    NSString *name = dictionary[MCCursorDictionaryCapeNameKey];
    NSNumber *version = dictionary[MCCursorDictionaryCapeVersionKey];
    
    backupAllCursors();
    resetAllCursors();
    
    MMLog("Applying cape: %s %.02f", name.UTF8String, version.floatValue);
    
    for (NSString *key in cursors) {
        NSDictionary *cape = cursors[key];
        MMLog("Hooking for %s", key.UTF8String);
        
        BOOL success = applyCapeForIdentifier(cape, key);
        if (!success) {
            MMLog(BOLD RED "Failed to hook identifier %s for some unknown reason. Bailing out..." RESET, key.UTF8String);
            return NO;
        }
    }
    
    MMLog(BOLD GREEN "Applied %s successfully!" RESET, name.UTF8String);
    
    return YES;
}

BOOL applyCapeAtPath(NSString *path) {
    NSDictionary *cape = [NSDictionary dictionaryWithContentsOfFile:path];
    if (cape)
        return applyCape(cape);
    MMLog(BOLD RED "Could not find valid file at %s to apply" RESET, path.UTF8String);
    return NO;
}
