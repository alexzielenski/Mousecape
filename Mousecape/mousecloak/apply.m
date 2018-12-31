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
#import "MCPrefs.h"
#import "NSBitmapImageRep+ColorSpace.h"

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

BOOL applyCapeForIdentifier(NSDictionary *cursor, NSString *identifier, BOOL restore) {
    if (!cursor || !identifier) {
        NSLog(@"bad seed");
        return NO;
    }

    BOOL lefty = MCFlag(MCPreferencesHandednessKey);
    BOOL pointer = MCCursorIsPointer(identifier);
    NSNumber *frameCount    = cursor[MCCursorDictionaryFrameCountKey];
    NSNumber *frameDuration = cursor[MCCursorDictionaryFrameDuratiomKey];
    //    NSNumber *repeatCount   = cursor[MCCursorDictionaryRepeatCountKey];
    
    CGPoint hotSpot         = CGPointMake([cursor[MCCursorDictionaryHotSpotXKey] doubleValue],
                                          [cursor[MCCursorDictionaryHotSpotYKey] doubleValue]);
    CGSize size             = CGSizeMake([cursor[MCCursorDictionaryPointsWideKey] doubleValue],
                                         [cursor[MCCursorDictionaryPointsHighKey] doubleValue]);
    NSArray *reps           = cursor[MCCursorDictionaryRepresentationsKey];
    NSMutableArray *images  = [NSMutableArray array];

    if (lefty && !restore && pointer) {
        MMLog("Lefty mode for %s", identifier.UTF8String);
        hotSpot.x = size.width - hotSpot.x - 1;
    }

    for (id object in reps) {
        CFTypeID type = CFGetTypeID((__bridge CFTypeRef)object);
        NSBitmapImageRep *rep;
        if (type == CGImageGetTypeID()) {
            rep = [[NSBitmapImageRep alloc] initWithCGImage:(__bridge CGImageRef)object];
        } else {
            rep = [[NSBitmapImageRep alloc] initWithData:object];
        }
        if (!lefty || restore || !pointer) {
            // special case if array has a type of CGImage already there is no need to convert it
            if (type == CGImageGetTypeID()) {
                images[images.count] = object;
                continue;
            }
            
            images[images.count] = (__bridge id)[rep.ensuredSRGBSpace CGImage];
            
        } else {
            NSBitmapImageRep *newRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                               pixelsWide:rep.pixelsWide
                                                                               pixelsHigh:rep.pixelsHigh
                                                                            bitsPerSample:8
                                                                          samplesPerPixel:4
                                                                                 hasAlpha:YES
                                                                                 isPlanar:NO
                                                                           colorSpaceName:NSCalibratedRGBColorSpace
                                                                              bytesPerRow:4 * rep.pixelsWide
                                                                             bitsPerPixel:32];
            NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep:newRep];
            [NSGraphicsContext saveGraphicsState];
            [NSGraphicsContext setCurrentContext:ctx];
            NSAffineTransform *transform = [NSAffineTransform transform];
            [transform translateXBy:rep.pixelsWide yBy:0];
            [transform scaleXBy:-1 yBy:1];
            [transform concat];

            [rep drawInRect:NSMakeRect(0, 0, rep.pixelsWide, rep.pixelsHigh)
                   fromRect:NSZeroRect
                  operation:NSCompositingOperationSourceOver
                   fraction:1.0
             respectFlipped:NO
                      hints:nil];
            [NSGraphicsContext restoreGraphicsState];
            images[images.count] = (__bridge id)[newRep.ensuredSRGBSpace CGImage];
        }
    }
    
    return applyCursorForIdentifier(frameCount.unsignedIntegerValue, frameDuration.doubleValue, hotSpot, size, images, identifier, 0);
}

BOOL applyCape(NSDictionary *dictionary) {
    @autoreleasepool {
        NSDictionary *cursors = dictionary[MCCursorDictionaryCursorsKey];
        NSString *name = dictionary[MCCursorDictionaryCapeNameKey];
        NSNumber *version = dictionary[MCCursorDictionaryCapeVersionKey];
        
        resetAllCursors();
        backupAllCursors();
        
        MMLog("Applying cape: %s %.02f", name.UTF8String, version.floatValue);
        
        for (NSString *key in cursors) {
            NSDictionary *cape = cursors[key];
            MMLog("Hooking for %s", key.UTF8String);
            
            BOOL success = applyCapeForIdentifier(cape, key, NO);
            if (!success) {
                MMLog(BOLD RED "Failed to hook identifier %s for some unknown reason. Bailing out..." RESET, key.UTF8String);
                return NO;
            }
        }
        
        MCSetDefault(dictionary[MCCursorDictionaryIdentifierKey], MCPreferencesAppliedCursorKey);
        
        MMLog(BOLD GREEN "Applied %s successfully!" RESET, name.UTF8String);
        
        return YES;
    }
}

BOOL applyCapeAtPath(NSString *path) {
    NSDictionary *cape = [NSDictionary dictionaryWithContentsOfFile:path];
    if (cape)
        return applyCape(cape);
    MMLog(BOLD RED "Could not find valid file at %s to apply" RESET, path.UTF8String);
    return NO;
}
