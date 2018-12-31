//
//  MCDefs.c
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#include "MCDefs.h"
#import "CGSCursor.h"
//NSArray *defaultCursors = nil;

NSString *defaultCursors[] = {
    @"com.apple.coregraphics.Arrow",
    @"com.apple.coregraphics.IBeam",
    @"com.apple.coregraphics.IBeamXOR",
    @"com.apple.coregraphics.Alias",
    @"com.apple.coregraphics.Copy",
    @"com.apple.coregraphics.Move",
    @"com.apple.coregraphics.ArrowCtx",
    @"com.apple.coregraphics.Wait",
    @"com.apple.coregraphics.Empty",
    nil };

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

NSString *UUID() {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *)string autorelease];
}

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
        return [(NSBitmapImageRep *)image representationUsingType:NSPNGFileType properties:@{}];
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
    
    MCIsCursorRegistered(CGSMainConnectionID(), (char *)identifier.UTF8String, &registered);
    if (!registered)
        return nil;

    CGError error = 0;
    if (![identifier hasPrefix:@"com.apple.cursor"]) {
        error = CGSCopyRegisteredCursorImages(CGSMainConnectionID(), (char*)identifier.UTF8String, &size, &hotSpot, &frameCount, &frameDuration, &representations);
    } else {
        error = CoreCursorCopyImages(CGSMainConnectionID(), [[identifier pathExtension] intValue], &representations, &size, &hotSpot, &frameCount, &frameDuration);
    }
    
    if (error || !representations || !CFArrayGetCount(representations))
        return nil;
    
    NSDictionary *dict = @{MCCursorDictionaryFrameCountKey: @(frameCount), MCCursorDictionaryFrameDuratiomKey: @(frameDuration), MCCursorDictionaryHotSpotXKey: @(hotSpot.x), MCCursorDictionaryHotSpotYKey: @(hotSpot.y), MCCursorDictionaryPointsWideKey: @(size.width), MCCursorDictionaryPointsHighKey: @(size.height), MCCursorDictionaryRepresentationsKey: (__bridge NSArray *)representations};
    
    CFRelease(representations);
    
    return dict;
}

extern NSDictionary *cursorMap() {
    static NSDictionary *cursorNameMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cursorNameMap = [[NSDictionary dictionaryWithObjectsAndKeys:
                          @"Resize N-S", @"com.apple.cursor.23",
                          @"Camera 2", @"com.apple.cursor.9",
                          @"IBeam H.", @"com.apple.cursor.26",
                          @"Window NE", @"com.apple.cursor.29",
                          @"Busy", @"com.apple.cursor.4",
                          @"Ctx Arrow", @"com.apple.coregraphics.ArrowCtx",
                          @"Open", @"com.apple.cursor.12",
                          @"Window N-S", @"com.apple.cursor.32",
                          @"Window SE", @"com.apple.cursor.35",
                          @"Counting Down", @"com.apple.cursor.15",
                          @"Window W", @"com.apple.cursor.38",
                          @"Resize E", @"com.apple.cursor.18",
                          @"Cell", @"com.apple.cursor.41",
                          @"Resize N", @"com.apple.cursor.21",
                          @"Copy Drag", @"com.apple.cursor.5",
                          @"Ctx Menu", @"com.apple.cursor.24",
                          @"Window E", @"com.apple.cursor.27",
                          @"Window NE-SW", @"com.apple.cursor.30",
                          @"Camera", @"com.apple.cursor.10",
                          @"Window NW", @"com.apple.cursor.33",
                          @"Pointing", @"com.apple.cursor.13",
                          @"IBeamXOR", @"com.apple.coregraphics.IBeamXOR",
                          @"Copy", @"com.apple.coregraphics.Copy",
                          @"Arrow", @"com.apple.coregraphics.Arrow",
                          @"Counting Up/Down", @"com.apple.cursor.16",
                          @"Window S", @"com.apple.cursor.36",
                          @"Resize Square", @"com.apple.cursor.39",
                          @"Resize W-E", @"com.apple.cursor.19",
                          @"Zoom In", @"com.apple.cursor.42",
                          @"Resize S", @"com.apple.cursor.22",
                          @"IBeam", @"com.apple.coregraphics.IBeam",
                          @"Move", @"com.apple.coregraphics.Move",
                          @"Crosshair", @"com.apple.cursor.7",
                          @"Poof", @"com.apple.cursor.25",
                          @"Wait", @"com.apple.coregraphics.Wait",
                          @"Link", @"com.apple.cursor.2",
                          @"Window E-W", @"com.apple.cursor.28",
                          @"Window N", @"com.apple.cursor.31",
                          @"Closed", @"com.apple.cursor.11",
                          @"Alias", @"com.apple.coregraphics.Alias",
                          @"Empty", @"com.apple.coregraphics.Empty",
                          @"Counting Up", @"com.apple.cursor.14",
                          @"Window NW-SE", @"com.apple.cursor.34",
                          @"Crosshair 2", @"com.apple.cursor.8",
                          @"Window SW", @"com.apple.cursor.37",
                          @"Resize W", @"com.apple.cursor.17",
                          @"Help", @"com.apple.cursor.40",
                          @"Forbidden", @"com.apple.cursor.3",
                          @"Cell XOR", @"com.apple.cursor.20",
                          @"Zoom Out", @"com.apple.cursor.43", nil] retain];
    });
    
    return cursorNameMap;
}

NSString *nameForCursorIdentifier(NSString *identifier) {
    NSString *name = cursorMap()[identifier];
    return name ?: @"Unknown";
}

NSString *cursorIdentifierForName(NSString *name) {
    NSArray *keys = [cursorMap() allKeysForObject:name];
    if (keys.count)
        return keys[0];
    return UUID();
}

CGError MCIsCursorRegistered(CGSConnectionID cid, char *cursorName, bool *registered) {
//    if (CGSIsCursorRegistered != NULL) {
//        return CGSIsCursorRegistered(cid, cursorName, registered);
//    }
    
    size_t size = 0;
    CGError err = 0;
    err = CGSGetRegisteredCursorDataSize(cid, cursorName, &size);
    
    *registered = !((BOOL)err) && size > 0;
    
    return err;
}

BOOL MCCursorIsPointer(NSString *identifier) {
    static NSArray *pointers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *c = cursorMap();
        pointers = [@[ [c allKeysForObject:@"Alias"][0], [c allKeysForObject:@"Arrow"][0], [c allKeysForObject:@"Busy"][0], [c allKeysForObject:@"Closed"][0], [c allKeysForObject:@"Copy Drag"][0], [c allKeysForObject:@"Counting Down"][0], [c allKeysForObject:@"Counting Up"][0], [c allKeysForObject:@"Counting Up/Down"][0], [c allKeysForObject:@"Ctx Menu"][0], [c allKeysForObject:@"Forbidden"][0], [c allKeysForObject:@"Link"][0], [c allKeysForObject:@"Move"][0], [c allKeysForObject:@"Open"][0], [c allKeysForObject:@"Pointing"][0], [c allKeysForObject:@"Poof"][0], [c allKeysForObject:@"Wait"][0], [c allKeysForObject:@"Zoom In"][0], [c allKeysForObject:@"Zoom Out"] ] retain];
    });

    return [pointers containsObject:identifier];
}
