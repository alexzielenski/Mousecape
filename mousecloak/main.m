//
//  main.m
//  mousecloak
//
//  Created by Alex Zielenski on 2/11/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCDefs.h"
#import "CGSCursor.h"
#import "CGSAccessibility.h"
#import <GBCLi/GBSettings.h>
#import <GBCLi/GBOptionsHelper.h>
#import <GBCli/GBCommandLineParser.h>
#import "NSCursor_Private.h"

#define RESET   "\033[0m"
#define BLACK   "\033[30m"      /* Black */
#define RED     "\033[31m"      /* Red */
#define GREEN   "\033[32m"      /* Green */
#define YELLOW  "\033[33m"      /* Yellow */
#define BLUE    "\033[34m"      /* Blue */
#define MAGENTA "\033[35m"      /* Magenta */
#define CYAN    "\033[36m"      /* Cyan */
#define WHITE   "\033[37m"      /* White */
#define BOLD    "\033[1m"

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

static const NSArray *defaultCursors = nil;

@interface GBOptionsHelper (Helper)
- (void)replacePlaceholdersAndPrintStringFromBlock:(GBOptionStringBlock)block;
@end

void CGImageWriteToFile(CGImageRef image, CFStringRef path) {
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, path , kCFURLPOSIXPathStyle, false);
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
	CFRelease(url);
	
    CGImageDestinationAddImage(destination, image, nil);
    
    bool success = CGImageDestinationFinalize(destination);
    if (!success) {
        NSLog(@"Failed to write image to %@", path);
    }
    
    CFRelease(destination);
}
NSData *pngDataForImage(id image) {
    if ([image isKindOfClass:[NSBitmapImageRep class]]) {
        return [(NSBitmapImageRep *)image representationUsingType:NSPNGFileType properties:nil];
    }
    
    // CGImage
    CGImageRef obj = (__bridge CGImageRef)image;
    CFMutableDataRef mutableData = CFDataCreateMutable(kCFAllocatorDefault, 0);
    CGImageDestinationRef dest = CGImageDestinationCreateWithData(mutableData, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(dest, obj, NULL);
    CGImageDestinationFinalize(dest);
    
    CFRelease(dest);
    
    return (__bridge NSData *)(mutableData);
}

NSString *MMGet(NSString *prompt) {
    MMLog("%s", prompt.UTF8String);
    MMLog(": ");
    
    char get[255] = {0};
    
    fgets(get, 256, stdin);
    
    // remove \n
    char *pos;
    if ((pos=strchr(get, '\n')) != NULL)
        *pos = '\0';
    
    return @(get);
}

NSString *backupStringForIdentifier(NSString *identifier) {
    return [NSString stringWithFormat:@"com.alexzielenski.mousecape.%@", identifier];
}

NSString *restoreStringForIdentifier(NSString *identifier) {
    return [identifier substringFromIndex:28];
}

NSDictionary *capeWithIdentifier(NSString *identifier) {
    
    NSUInteger frameCount;
    CGFloat frameDuration;
    CGPoint hotSpot;
    CGSize size;
    CFArrayRef representations;
    
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

NSDictionary *processedCapeWithIdentifier(NSString *identifier) {
    NSMutableDictionary *dict = capeWithIdentifier(identifier).mutableCopy;
    if (!dict)
        return nil;
    
    NSDictionary *cursors = dict[MCCursorDictionaryRepresentationsKey];
    NSMutableArray *reps = [NSMutableArray array];
    
    for (id image in cursors) {
        
        reps[reps.count] = pngDataForImage(image);
        
    }
    
    dict[MCCursorDictionaryRepresentationsKey] = reps;
    return dict;
}

BOOL applyCursorForIdentifier(CFIndex frameCount, CGFloat frameDuration, CGPoint hotSpot, CGSize size, NSArray *images, NSString *ident, NSUInteger repeatCount) {
    if (frameCount > 24 || frameCount < 1) {
        MMLog(BOLD RED "Frame count of %s out of range [1...24]\n", ident.UTF8String);
        return YES;
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

void restoreCursorForIdentifier(NSString *ident) {
    bool registered = false;
    CGSIsCursorRegistered(CGSMainConnectionID(), (char *)ident.UTF8String, &registered);
    
    // dont try to backup a nonexistant cursor
    if (!registered)
        return;
    
    NSString *restoreIdent = restoreStringForIdentifier(ident);
    NSDictionary *cape = capeWithIdentifier(ident);
        
    MMLog("Restoring cursor %s from %s\n", restoreIdent.UTF8String, ident.UTF8String);
    BOOL x = applyCapeForIdentifier(cape, restoreIdent);
    (void)x;
}

void resetAllCursors() {
    MMLog("Restoring cursors...\n");
    
    // Backup main cursors first
    for (NSString *key in defaultCursors) {
        restoreCursorForIdentifier(backupStringForIdentifier(key));
    }
    
    // Backup auxiliary cursors
    MMLog("Restoring core cursors...\n");
    if (CoreCursorUnregisterAll(CGSMainConnectionID()) == 0) {
        MMLog(BOLD GREEN "Successfully restored all cursors.\n" RESET);
    } else
        MMLog(BOLD RED "Received an error while restoring core cursors.\n" RESET);
}

void backupCursorForIdentifier(NSString *ident) {
    bool registered = false;
    CGSIsCursorRegistered(CGSMainConnectionID(), (char *)ident.UTF8String, &registered);
    
    // dont try to backup a nonexistant cursor
    if (!registered)
        return;
    
    NSString *backupIdent = backupStringForIdentifier(ident);
    CGSIsCursorRegistered(CGSMainConnectionID(), (char *)backupIdent.UTF8String, &registered);
    
    // don't re-back it up
    if (registered)
        return;
    
    NSDictionary *cape = capeWithIdentifier(ident);
    (void)applyCapeForIdentifier(cape, backupIdent);
    
}

void backupAllCursors() {
    bool arrowRegistered = false;
    CGSIsCursorRegistered(CGSMainConnectionID(), (char *)backupStringForIdentifier(@"com.apple.coregraphics.Arrow").UTF8String, &arrowRegistered);
    
    if (arrowRegistered) {
        // we are already backed up
        return;
    }
    // Backup main cursors first
    for (NSString *key in defaultCursors) {
        backupCursorForIdentifier(key);
    }
    
    // no need to backup core cursors
    
}

BOOL applyCape(NSDictionary *dictionary) {
    
    NSDictionary *cursors = dictionary[MCCursorDictionaryCursorsKey];
    NSString *name = dictionary[MCCursorDictionaryCapeNameKey];
    NSNumber *version = dictionary[MCCursorDictionaryCapeVersionKey];

    backupAllCursors();
    resetAllCursors();
    
    MMLog("\nApplying cape: %s %.02f\n", name.UTF8String, version.floatValue);
    
    for (NSString *key in cursors) {
        NSDictionary *cape = cursors[key];
        MMLog("Hooking for %s\n", key.UTF8String);
        
        BOOL success = applyCapeForIdentifier(cape, key);
        if (!success) {
            MMLog(BOLD RED "Failed to hook identifier %s for some unknown reason. Bailing out...\n" RESET, key.UTF8String);
            return NO;
        }
    }
    
    MMLog(BOLD GREEN "Applied %s successfully!\n" RESET, name.UTF8String);
    
    return YES;
}

NSDictionary *createCapeFromDirectory(NSString *path) {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    BOOL isDir;
    BOOL exists = [manager fileExistsAtPath:path isDirectory:&isDir];
    
    if (!exists || !isDir)
        return nil;
    
    NSArray *contents = [manager contentsOfDirectoryAtPath:path error:nil];
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:@(MCCursorCreatorVersion) forKey:MCCursorDictionaryVersionKey];
    [dictionary setObject:@(MCCursorParserVersion) forKey:MCCursorDictionaryMinimumVersionKey];
    
    CGFloat version = 0.0;
    
    MMLog(BOLD "Enter metadata for cape:\n" RESET);
    NSString *author = MMGet(@"Author");
    NSString *identifier = MMGet(@"Identifier");
    NSString *name = MMGet(@"Cape Name");
    MMLog("Cape Version: ");
    scanf("%lf", &version);
    NSString *hidpi = MMGet(@"HiDPI? (y/n)");
    
    MMLog("\n");
    
    BOOL HiDPI = [hidpi isEqualToString:@"y"];
    
    [dictionary setObject:author forKey:MCCursorDictionaryAuthorKey];
    [dictionary setObject:identifier forKey:MCCursorDictionaryIdentifierKey];
    [dictionary setObject:name forKey:MCCursorDictionaryCapeNameKey];
    [dictionary setObject:@(version) forKey:MCCursorDictionaryCapeVersionKey];
    [dictionary setObject:@NO forKey:MCCursorDictionaryCloudKey];
    [dictionary setObject:@(HiDPI) forKey:MCCursorDictionaryHiDPIKey];
    
    NSMutableDictionary *cursors = [NSMutableDictionary dictionary];
    
    for (NSString *subpath in contents) {
        NSString *fullPath = [path stringByAppendingPathComponent:subpath];
        
        BOOL isDir;
        [manager fileExistsAtPath:fullPath isDirectory:&isDir];
        
        if (!isDir)
            continue;
        
        NSString *identifier = subpath;
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        NSUInteger fC;
        CGFloat hotX, hotY, pW, pH, fD;
        printf(BOLD "Need metadata for %s.\n" RESET, [identifier cStringUsingEncoding:NSUTF8StringEncoding]);
        printf("X Hotspot: ");
        scanf("%lf", &hotX);
        printf("Y Hotspot: ");
        scanf("%lf", &hotY);
        printf("Points Wide: ");
        scanf("%lf", &pW);
        printf("Points High: ");
        scanf("%lf", &pH);
        printf("Frame Count: ");
        scanf("%lu", &fC);
        printf("Frame Duration: ");
        scanf("%lf", &fD);
        
        NSMutableArray *representations = [NSMutableArray array];
        NSArray *repNames = [manager contentsOfDirectoryAtPath:fullPath error:nil];
        for (NSString *rep in repNames) {
            NSString *repPath = [fullPath stringByAppendingPathComponent:rep];
            
            [manager fileExistsAtPath:repPath isDirectory:&isDir];
            if (isDir || [rep isEqualToString:@".DS_Store"])
                continue;
            
            NSBitmapImageRep *image = [NSBitmapImageRep imageRepWithData:[NSData dataWithContentsOfFile:repPath]];
            
            if (image) {
                NSData *pngData = [image representationUsingType:NSPNGFileType properties:nil];
                [representations addObject:pngData];
            }
            
        }
        
        [data setObject:@(hotX) forKey:MCCursorDictionaryHotSpotXKey];
        [data setObject:@(hotY) forKey:MCCursorDictionaryHotSpotYKey];
        [data setObject:@(pW) forKey:MCCursorDictionaryPointsWideKey];
        [data setObject:@(pH) forKey:MCCursorDictionaryPointsHighKey];
        [data setObject:@(fC) forKey:MCCursorDictionaryFrameCountKey];
        [data setObject:@(fD) forKey:MCCursorDictionaryFrameDuratiomKey];
        
        [data setObject:representations forKey:MCCursorDictionaryRepresentationsKey];
        [cursors setObject:data forKey:identifier];
    }
    
    if (cursors.count == 0)
        return nil;
    
    [dictionary setObject:cursors forKey:MCCursorDictionaryCursorsKey];
    
    return dictionary;
}

NSDictionary *createCapeFromMightyMouse(NSDictionary *mightyMouse) {
    if (!mightyMouse)
        return nil;
    
    NSDictionary *cursors    = mightyMouse[@"Cursors"];
    NSDictionary *global     = cursors[@"Global"];
    NSDictionary *cursorData = cursors[@"Cursor Data"];
    NSDictionary *identifiers = global[@"Identifiers"];
    
    if (!cursors || !global || !identifiers || !cursorData) {
        MMLog(BOLD RED "Mighty Mouse format either invalid or unrecognized.\n" RESET);
        return nil;
    }
    
    NSMutableDictionary *convertedCursors = [NSMutableDictionary dictionary];
    
    for (NSString *key in identifiers) {
        MMLog("Converting cursor: %s\n", key.UTF8String);
        
        NSMutableDictionary *currentCursor = [NSMutableDictionary dictionary];
        
        NSDictionary *info = identifiers[key];
        NSString *customKey = info[@"Custom Key"];
        
        NSDictionary *data = cursorData[customKey];
        
        NSNumber *bpp   = data[@"BitsPerPixel"];
        NSNumber *bps   = data[@"BitsPerSample"];
        NSNumber *bpr   = data[@"BytesPerRow"];
        NSData *rawData = data[@"CursorData"];
        NSNumber *spp   = data[@"SamplesPerPixel"];
        
        NSNumber *fc    = data[@"FrameCount"];
        NSNumber *fd    = data[@"FrameDuration"];
        NSNumber *hotX  = data[@"HotspotX"];
        NSNumber *hotY  = data[@"HotspotY"];
        NSNumber *wide  = data[@"PixelsWide"];
        NSNumber *high  = data[@"PixelsHigh"];
        
        unsigned char *bytes = (unsigned char*)rawData.bytes;
        
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&bytes
                                                                        pixelsWide:wide.doubleValue
                                                                        pixelsHigh:high.doubleValue * fc.integerValue
                                                                     bitsPerSample:bps.integerValue
                                                                   samplesPerPixel:spp.integerValue
                                                                          hasAlpha:YES
                                                                          isPlanar:NO
                                                                    colorSpaceName:NSDeviceRGBColorSpace
                                                                      bitmapFormat:NSAlphaFirstBitmapFormat | kCGBitmapByteOrder32Big
                                                                       bytesPerRow:bpr.integerValue
                                                                      bitsPerPixel:bpp.integerValue];
        
        currentCursor[MCCursorDictionaryRepresentationsKey] = @[ [rep representationUsingType:NSPNGFileType properties:nil] ];
        currentCursor[MCCursorDictionaryPointsWideKey]      = wide;
        currentCursor[MCCursorDictionaryPointsHighKey]      = high;
        currentCursor[MCCursorDictionaryHotSpotXKey]        = hotX;
        currentCursor[MCCursorDictionaryHotSpotYKey]        = hotY;
        currentCursor[MCCursorDictionaryFrameCountKey]      = fc;
        currentCursor[MCCursorDictionaryFrameDuratiomKey]   = fd;
        
        convertedCursors[key] = currentCursor;
    }
    
    if (convertedCursors.count == 0) {
        MMLog(BOLD RED "No cursors to convert in file.\n" RESET);
        return nil;
    }
    
    NSMutableDictionary *totalDict = [NSMutableDictionary dictionary];
    
    totalDict[MCCursorDictionaryCursorsKey]        = convertedCursors;
    totalDict[MCCursorDictionaryVersionKey]        = @(MCCursorCreatorVersion);
    totalDict[MCCursorDictionaryMinimumVersionKey] = @(MCCursorParserVersion);
    totalDict[MCCursorDictionaryHiDPIKey]          = @NO;
    totalDict[MCCursorDictionaryCloudKey]          = @NO;
    
    CGFloat version = 0.0;
    
    MMLog(BOLD "\nEnter metadata for cape:\n" RESET);
    NSString *author = MMGet(@"Author");
    NSString *identifier = MMGet(@"Identifier");
    NSString *name = MMGet(@"Cape Name");
    MMLog("Cape Version: ");
    scanf("%lf", &version);
    
    totalDict[MCCursorDictionaryAuthorKey] = author;
    totalDict[MCCursorDictionaryCapeNameKey] = name;
    totalDict[MCCursorDictionaryCapeVersionKey] = @(version);
    totalDict[MCCursorDictionaryIdentifierKey] = identifier;
    
    return totalDict;
}

void dumpCursorsToFile(NSString *path) {
    MMLog("\nDumping cursors...\n");
    
    float originalScale;
    CGSGetCursorScale(CGSMainConnectionID(), &originalScale);
    
    CGSSetCursorScale(CGSMainConnectionID(), 16.0);
    CGSHideCursor(CGSMainConnectionID());
    
    NSMutableDictionary *cursors = [NSMutableDictionary dictionary];
    
    for (NSString *key in defaultCursors) {
        MMLog("Gathering data for %s\n", key.UTF8String);
        cursors[key] = processedCapeWithIdentifier(key);
    }
    
    for (int x = 3; x < 50; x++) {
        NSString *key = [@"com.apple.cursor." stringByAppendingFormat:@"%d", x];
        NSDictionary *cape = processedCapeWithIdentifier(key);
        if (!cape)
            continue;
        
        MMLog("Gathering data for %s\n", key.UTF8String);
        
        cursors[key] = cape;
    }
    
    NSMutableDictionary *cape = [NSMutableDictionary dictionary];
    cape[MCCursorDictionaryAuthorKey] = @"Apple, Inc.";
    cape[MCCursorDictionaryCapeNameKey] = @"Cursor Dump";
    cape[MCCursorDictionaryCapeVersionKey] = @1.0;
    cape[MCCursorDictionaryCloudKey] = @NO;
    cape[MCCursorDictionaryCursorsKey] = cursors;
    cape[MCCursorDictionaryHiDPIKey] = @YES;
    cape[MCCursorDictionaryIdentifierKey] = [NSString stringWithFormat:@"com.alexzielenski.mousecape.dump"];
    cape[MCCursorDictionaryVersionKey] = @(MCCursorCreatorVersion);
    cape[MCCursorDictionaryMinimumVersionKey] = @(MCCursorParserVersion);
    
    CGSSetCursorScale(CGSMainConnectionID(), originalScale);
    CGSShowCursor(CGSMainConnectionID());
    
    [cape writeToFile:path atomically:NO];
}

int main(int argc, char * argv[])
{
    @autoreleasepool {        
        /*NSFileManager *man = [NSFileManager defaultManager];
         
         CGSSetCursorScale(CGSMainConnectionID(), 8.0);
         
         for (int x = 0; x < 100; x++) {
         CFArrayRef images;
         CGPoint hp;
         CGSize size;
         CFIndex fc;
         CGFloat duration;
         
         CoreCursorCopyImages(CGSMainConnectionID(), x, &images, &size, &hp, &fc, &duration);
         
         NSArray *reps = (__bridge NSArray *)images;
         
         if (reps.count == 0)
         continue;
         
         NSString *dir = [NSString stringWithFormat:@"/Users/Alex/Desktop/dump/com.apple.cursor.%d", x];
         [man createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
         
         for (NSUInteger idx = 0; idx < reps.count; idx++) {
         CGImageRef image = (__bridge CGImageRef)reps[idx];
         
         CGImageWriteToFile(image, (__bridge CFStringRef)[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld.png", idx]]);
         
         }
         
         }
         
         NSMutableDictionary *d = capeWithIdentifier(@"com.apple.cursor.16").mutableCopy;
         d[@"FrameDuration"] = @(.1f);
         applyCapeForIdentifier(d, @"com.apple.coregraphics.Arrow");
         
         NSLog(@"%@", capeWithIdentifier(@"com.apple.cursor.16"));
         CoreCursorUnregisterAll(CGSMainConnectionID());
         NSLog(@"%@", capeWithIdentifier(@"com.apple.cursor.5"));
         CGSSetCursorScale(CGSMainConnectionID(), 1.0);
         return 0;
         */
        
        defaultCursors = @[
        @"com.apple.coregraphics.Arrow",
        @"com.apple.coregraphics.IBeam",
        @"com.apple.coregraphics.IBeamXOR",
        @"com.apple.coregraphics.Alias",
        @"com.apple.coregraphics.Copy",
        @"com.apple.coregraphics.Move",
        @"com.apple.coregraphics.ArrowCtx",
        @"com.apple.coregraphics.Wait",
        @"com.apple.coregraphics.Empty"];

        GBSettings *settings = [GBSettings settingsWithName:@"mousecape" parent:nil];
        
        GBOptionsHelper *options = [[GBOptionsHelper alloc] init];
        [options registerSeparator:@"APPLYING CAPES"];
        [options registerOption:'a' long:@"apply" description:@"Apply a cape" flags:GBValueRequired];
        [options registerOption:'r' long:@"reset" description:@"Reset to the default OSX cursors" flags:GBValueNone];
        [options registerSeparator:@"CREATING CAPES"];
        [options registerOption:'c' long:@"create"
                    description:
         @"Create a cursor from a folder. Default output is to a new file of the same name. Directory must use the format:\n"
         "\t\t├── com.apple.coregraphics.Arrow\n"
         "\t\t│   ├── 0.png\n"
         "\t\t│   ├── 1.png\n"
         "\t\t│   ├── 2.png\n"
         "\t\t│   └── 3.png\n"
         "\t\t├── com.apple.coregraphics.Wait\n"
         "\t\t│   ├── 0.png\n"
         "\t\t│   ├── 1.png\n"
         "\t\t│   └── 2.png\n"
         "\t\t├── com.apple.cursor.3\n"
         "\t\t│   ├── 0.png\n"
         "\t\t│   ├── 1.png\n"
         "\t\t│   ├── 2.png\n"
         "\t\t│   └── 3.png\n"
         "\t\t└── com.apple.cursor.5\n"
         "\t\t    ├── 0.png\n"
         "\t\t    ├── 1.png\n"
         "\t\t    ├── 2.png\n"
         "\t\t    └── 3.png\n"
                          flags:GBValueRequired];
        [options registerOption:'d' long:@"dump" description:@"Dumps the currently applied cursors to a file." flags:GBValueRequired];
        [options registerSeparator:@"CONVERTING MIGHTYMOUSE TO CAPE"];
        [options registerOption:'x' long:@"convert" description:@"Convert a .MightyMouse file to cape. Default output is to a new file of the same name" flags:GBValueRequired];
        [options registerSeparator:@"MISCELLANEOUS"];
        [options registerOption:'?' long:@"help" description:@"Display this help and exit" flags:GBValueNone];
        [options registerOption:'o' long:@"output" description:@"Use this option to tell where an output file goes. (For convert and create)" flags:GBValueRequired];
        [options registerOption:0 long:@"suppressCopyright" description:@"Suppress Copyright info" flags:GBValueNone | GBOptionNoHelp | GBOptionNoPrint];
        [options registerOption:'s' long:@"scale" description:@"Scale the cursor to obscene multipliers or get the current scale" flags:GBValueOptional];
        
        options.applicationName = ^{ return @"mousecloak"; };
        options.applicationVersion = ^{ return @"2.0"; };
        options.applicationBuild = ^{ return @""; };
        options.printHelpHeader = ^{ return [NSString stringWithUTF8String:BOLD WHITE "\n%APPNAME v%APPVERSION" RESET]; };
        options.printHelpFooter = ^{ return [NSString stringWithUTF8String:BOLD WHITE "\nCopyright © 2013 Alex Zielenski\n" RESET]; };
                
        GBCommandLineParser *parser = [[GBCommandLineParser alloc] init];
        [options registerOptionsToCommandLineParser:parser];
        [parser parseOptionsWithArguments:argv count:argc block:^(GBParseFlags flags, NSString *option, id value, BOOL *stop) {
            switch (flags) {
                case GBParseFlagUnknownOption:
                    printf(BOLD RED "Unknown command line option %s, try --help!\n" RESET, option.UTF8String);
                    break;
                case GBParseFlagMissingValue:
                    printf(BOLD RED "Missing value for command line option %s, try --help!\n" RESET, option.UTF8String);
                    break;
                case GBParseFlagArgument:
                    [settings addArgument:value];
                    break;
                case GBParseFlagOption:
                    [settings setObject:value forKey:option];
                    break;
            }
        }];
        
        if ([settings boolForKey:@"help"] || argc == 1) {
            [options printHelp];
            return 0;
        }
        
        BOOL suppressCopyright = [settings boolForKey:@"suppressCopyright"];
        
        if (!suppressCopyright)
            [options replacePlaceholdersAndPrintStringFromBlock:options.printHelpHeader];
        
        if ([settings boolForKey:@"reset"]) {
            // reset to default cursors
            resetAllCursors();
            
            if (!suppressCopyright)
                [options replacePlaceholdersAndPrintStringFromBlock:options.printHelpFooter];
            return 0;
        }
        
        BOOL convert = [settings isKeyPresentAtThisLevel:@"convert"];
        BOOL apply   = [settings isKeyPresentAtThisLevel:@"apply"];
        BOOL create  = [settings isKeyPresentAtThisLevel:@"create"];
        BOOL dump    = [settings isKeyPresentAtThisLevel:@"dump"];
        BOOL scale   = [settings isKeyPresentAtThisLevel:@"scale"];
        int amt = 0;
        
        if (convert) amt++;
        if (apply) amt++;
        if (create) amt++;
        if (dump) amt++;
        if (scale) amt++;
        
        if (amt > 1) {
            printf(BOLD RED "One command at a time, son!\n" RESET);
            
            if (!suppressCopyright)
                [options replacePlaceholdersAndPrintStringFromBlock:options.printHelpFooter];
            return 0;
        }
        
        NSFileManager *manager = [NSFileManager defaultManager];
        
        if (apply) {
            // Apply a cape at a given path
            NSString *path = [settings objectForKey:@"apply"];
            NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
            
            BOOL isDir = NO;
            BOOL fileExists = [manager fileExistsAtPath:path];
            
            if (!fileExists || isDir) {
                MMLog(BOLD RED "Invalid cursor file or bad path given: %s\n" RESET, path.UTF8String);
                goto fin;
            }
            
            if (dict)
                applyCape(dict);
            
        } else if (create) {
            NSString *path = [settings objectForKey:@"create"];
            NSDictionary *cape = createCapeFromDirectory(path);
            
            if (!cape) {
                MMLog(BOLD RED "Unable to create a cape from the directory specified\n" RESET);
                goto fin;
            }
            
            NSString *output = [settings isKeyPresentAtThisLevel:@"output"] ? [settings objectForKey:@"output"] : path.stringByDeletingLastPathComponent;
            BOOL isDir;
            BOOL exists = [manager fileExistsAtPath:output isDirectory:&isDir];
            if (isDir)
                output = [[output stringByAppendingPathComponent:path.lastPathComponent.stringByDeletingPathExtension] stringByAppendingPathExtension:@"cape"];
            
            if (!isDir && exists) {
                MMLog("File exists at specified output: %s\n", output.UTF8String);
                goto fin;
            }
            
            if (![cape writeToFile:output atomically:NO])
                MMLog(BOLD RED "Failed to write to %s\n" RESET, output.UTF8String);
            else
                MMLog(BOLD GREEN "Cape successfully written to %s\n" RESET, output.UTF8String);
            
        } else if (convert) {
            NSString *path = [settings objectForKey:@"convert"];
            
            NSDictionary *MM = [NSDictionary dictionaryWithContentsOfFile:path];
            NSDictionary *cape = createCapeFromMightyMouse(MM);
            
            if (!cape) {
                MMLog(BOLD RED "Unable to create a cape from the file specified\n" RESET);
                goto fin;
            }
            
            
            NSString *output = [settings isKeyPresentAtThisLevel:@"output"] ? [settings objectForKey:@"output"] : path.stringByDeletingLastPathComponent;
            BOOL isDir;
            BOOL exists = [manager fileExistsAtPath:output isDirectory:&isDir];
            if (isDir)
                output = [[output stringByAppendingPathComponent:path.lastPathComponent.stringByDeletingPathExtension] stringByAppendingPathExtension:@"cape"];
            
            if (!isDir && exists) {
                MMLog(BOLD RED "File exists at specified output: %s\n" RESET, output.UTF8String);
                goto fin;
            }
            
            if (![cape writeToFile:output atomically:NO])
                MMLog(BOLD RED "Unable to write to %s\n" RESET, output.UTF8String);
            else
                MMLog(BOLD GREEN "Cape successfully written to %s\n" RESET, output.UTF8String);
            
        } else if (dump) {
            NSString *path = [settings objectForKey:@"dump"];
            dumpCursorsToFile(path);
            
        } else if (scale) {
            NSNumber *number = [settings objectForKey:@"scale"];
            
            if (argc == 2) {
                
                float value;
                CGSGetCursorScale(CGSMainConnectionID(), &value);
                
                MMLog("\n%f\n", value);
                
            } else {
                    
                float dbl = number.floatValue;
                
                if (dbl > 32) {
                    MMLog("Not a good idea...\n");
                } else if (CGSSetCursorScale(CGSMainConnectionID(), dbl) == noErr) {
                    MMLog("Successfully set cursor scale!\n");
                } else {
                    MMLog("Somehow failed to set cursor scale!\n");
                }
            }            
            goto fin;
        }
        
    fin:
        if (!suppressCopyright)
            [options replacePlaceholdersAndPrintStringFromBlock:options.printHelpFooter];
        
    }
    return 0;
}

