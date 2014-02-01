//
//  MCDefs.c
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#include "MCDefs.h"
#import "CGSCursor.h"
NSArray *defaultCursors = nil;
NSString *MCErrorDomain = @"com.alexzielenski.mousecape.error";

const CGFloat   MCCursorCreatorVersion               = 2.0;
const CGFloat   MCCursorParserVersion                = 2.0;

const NSString *MCCursorDictionaryMinimumVersionKey  = @"MinimumVersion";
const NSString *MCCursorDictionaryVersionKey         = @"Version";
const NSString *MCCursorDictionaryCursorsKey         = @"Cursors";
const NSString *MCCursorDictionaryAuthorKey          = @"Author";
const NSString *MCCursorDictionaryCloudKey           = @"Cloud";
const NSString *MCCursorDictionaryHiDPIKey           = @"HiDPI";
const NSString *MCCursorDictionaryIdentifierKey      = @"Identifier";
const NSString *MCCursorDictionaryCapeNameKey        = @"CapeName";
const NSString *MCCursorDictionaryCapeVersionKey     = @"CapeVersion";

const NSString *MCCursorDictionaryFrameCountKey      = @"FrameCount";
const NSString *MCCursorDictionaryFrameDuratiomKey   = @"FrameDuration";
//const NSString *MCCursorDictionaryRepeatCountKey     = @"RepeatCount";
const NSString *MCCursorDictionaryHotSpotXKey        = @"HotSpotX";
const NSString *MCCursorDictionaryHotSpotYKey        = @"HotSpotY";
const NSString *MCCursorDictionaryPointsWideKey      = @"PointsWide";
const NSString *MCCursorDictionaryPointsHighKey      = @"PointsHigh";
const NSString *MCCursorDictionaryRepresentationsKey = @"Representations";

NSString *MMGet(NSString *prompt) {
    MMOut("%s: ", prompt.UTF8String);
    
    char get[255] = {0};
    
    fgets(get, 256, stdin);
    
    // remove newline
    char *pos;
    if ((pos = strchr(get, '\n')) != NULL)
        *pos = '\0';
    
    return @(get);
}

void CGImageWriteToFile(CGImageRef image, CFStringRef path) {
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, path , kCFURLPOSIXPathStyle, false);
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
	CFRelease(url);
	
    CGImageDestinationAddImage(destination, image, nil);
    
    bool success = CGImageDestinationFinalize(destination);
    if (!success) {
        MMLog("Failed to write image to %s", [(__bridge NSString *)path UTF8String]);
    }
    
    CFRelease(destination);
}

NSData *pngDataForImage(id image) {
    if ([image isKindOfClass:[NSBitmapImageRep class]]) {
        return [(NSBitmapImageRep *)image representationUsingType:NSPNGFileType properties:nil];
    }
    
    // CGImage
    CGImageRef obj = (CGImageRef)image;
    CFMutableDataRef mutableData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CGImageDestinationRef dest = CGImageDestinationCreateWithData(mutableData, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(dest, obj, NULL);
    CGImageDestinationFinalize(dest);
    
    CFRelease(dest);
    
    return [(NSData *)mutableData autorelease];
}

NSDictionary *capeWithIdentifier(NSString *identifier) {
    
    NSUInteger frameCount;
    CGFloat frameDuration;
    CGPoint hotSpot;
    CGSize size;
    CFArrayRef representations;
    bool registered = false;
    
    CGSIsCursorRegistered(CGSMainConnectionID(), (char *)identifier.UTF8String, &registered);
    if (!registered)
        return nil;
    
    if (![identifier hasPrefix:@"com.apple.cursor"]) {
        CGSCopyRegisteredCursorImages(CGSMainConnectionID(), (char*)identifier.UTF8String, &size, &hotSpot, &frameCount, &frameDuration, &representations);
    } else {
        CoreCursorCopyImages(CGSMainConnectionID(), [[identifier pathExtension] intValue], &representations, &size, &hotSpot, &frameCount, &frameDuration);
    }
    
    if (!representations)
        return nil;
    
    NSDictionary *dict = @{MCCursorDictionaryFrameCountKey: @(frameCount), MCCursorDictionaryFrameDuratiomKey: @(frameDuration), MCCursorDictionaryHotSpotXKey: @(hotSpot.x), MCCursorDictionaryHotSpotYKey: @(hotSpot.y), MCCursorDictionaryPointsWideKey: @(size.width), MCCursorDictionaryPointsHighKey: @(size.height), MCCursorDictionaryRepresentationsKey: (__bridge NSArray *)representations};
    
    CFRelease(representations);
    
    return dict;
}
