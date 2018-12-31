//
//  create.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "create.h"
#import "NSCursor_Private.h"
#import "NSBitmapImageRep+ColorSpace.h"

NSError *createCape(NSString *input, NSString *output, BOOL convert) {
    NSDictionary *cape;
    if (convert)
        cape = createCapeFromMightyMouse([NSDictionary dictionaryWithContentsOfFile:input], nil);
    else
        cape = createCapeFromDirectory(input);
    
    if (!cape) {
        if (convert)
            return [NSError errorWithDomain:MCErrorDomain code:MCErrorInvalidCapeCode userInfo:@{
                                                                                                 NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to create cape file", nil),
                                                                                                 NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Unabled to create a cape from the file specified.", nil) }];
        else
            return [NSError errorWithDomain:MCErrorDomain code:MCErrorInvalidCapeCode userInfo:@{
                                                                                                 NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to create cape file", nil),
                                                                                                 NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Unabled to create a cape from the directory specified.", nil) }];
    }
    
    if (![cape writeToFile:output atomically:NO]) {
        return [NSError errorWithDomain:MCErrorDomain code:MCErrorWriteFailCode userInfo:@{
                                                                                           NSLocalizedDescriptionKey: NSLocalizedString(@"Failed to create cape file", nil),
                                                                                           NSLocalizedFailureReasonErrorKey: [NSString stringWithFormat: NSLocalizedString(@"The destination, %@, is not writable.", nil), output] }];
    }

    return nil;
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
    
    MMLog(BOLD "Enter metadata for cape:" RESET);
    NSString *author = MMGet(@"Author");
    NSString *identifier = MMGet(@"Identifier");
    NSString *name = MMGet(@"Cape Name");
    MMLog("Cape Version: ");
    scanf("%lf", &version);
    NSString *hidpi = MMGet(@"HiDPI? (y/n)");
    
    MMLog("");
    
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
        
        [manager fileExistsAtPath:fullPath isDirectory:&isDir];
        
        if (!isDir)
            continue;
        
        NSString *ident = subpath;
        NSMutableDictionary *data = [NSMutableDictionary dictionary];
        
        NSUInteger fC;
        CGFloat hotX, hotY, pW, pH, fD;
        printf(BOLD "Need metadata for %s." RESET, [ident cStringUsingEncoding:NSUTF8StringEncoding]);
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
                NSData *pngData = [image.ensuredSRGBSpace representationUsingType:NSPNGFileType properties:@{}];
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

NSDictionary *createCapeFromMightyMouse(NSDictionary *mightyMouse, NSDictionary *metadata) {
    if (!mightyMouse)
        return nil;
    
    NSDictionary *cursors    = mightyMouse[@"Cursors"];
    NSDictionary *global     = cursors[@"Global"];
    NSDictionary *cursorData = cursors[@"Cursor Data"];
    NSDictionary *identifiers = global[@"Identifiers"];
    
    if (!cursors || !global || !identifiers || !cursorData) {
        MMLog(BOLD RED "Mighty Mouse format either invalid or unrecognized." RESET);
        return nil;
    }
    
    NSMutableDictionary *convertedCursors = [NSMutableDictionary dictionary];
    
    for (NSString *key in identifiers) {
        MMLog("Converting cursor: %s", key.UTF8String);
        
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
                                                                        pixelsWide:wide.integerValue
                                                                        pixelsHigh:high.integerValue * fc.integerValue
                                                                     bitsPerSample:bps.integerValue
                                                                   samplesPerPixel:spp.integerValue
                                                                          hasAlpha:YES
                                                                          isPlanar:NO
                                                                    colorSpaceName:NSCalibratedRGBColorSpace
                                                                      bitmapFormat:NSAlphaFirstBitmapFormat | kCGBitmapByteOrder32Big
                                                                       bytesPerRow:bpr.integerValue
                                                                      bitsPerPixel:bpp.integerValue];
        
        currentCursor[MCCursorDictionaryRepresentationsKey] = @[ [rep representationUsingType:NSPNGFileType properties:@{}] ];
        currentCursor[MCCursorDictionaryPointsWideKey]      = wide;
        currentCursor[MCCursorDictionaryPointsHighKey]      = high;
        currentCursor[MCCursorDictionaryHotSpotXKey]        = hotX;
        currentCursor[MCCursorDictionaryHotSpotYKey]        = hotY;
        currentCursor[MCCursorDictionaryFrameCountKey]      = fc;
        currentCursor[MCCursorDictionaryFrameDuratiomKey]   = fd;
        
        convertedCursors[key] = currentCursor;
    }
    
    if (convertedCursors.count == 0) {
        MMLog(BOLD RED "No cursors to convert in file." RESET);
        return nil;
    }
    
    NSMutableDictionary *totalDict = [NSMutableDictionary dictionary];
    
    totalDict[MCCursorDictionaryCursorsKey]        = convertedCursors;
    totalDict[MCCursorDictionaryVersionKey]        = @(MCCursorCreatorVersion);
    totalDict[MCCursorDictionaryMinimumVersionKey] = @(MCCursorParserVersion);
    totalDict[MCCursorDictionaryHiDPIKey]          = @NO;
    totalDict[MCCursorDictionaryCloudKey]          = @NO;
    
    CGFloat version = 0.0;
    
    MMLog(BOLD "Enter metadata for cape:" RESET);
    NSString *author = metadata[@"author"] ?: MMGet(@"Author");
    NSString *identifier = metadata[@"identifier"] ?: MMGet(@"Identifier");
    NSString *name = metadata[@"name"] ?: MMGet(@"Cape Name");
    
    if (metadata[@"version"])
        version = [metadata[@"version"] doubleValue];
    else {
        MMLog("Cape Version: ");
        scanf("%lf", &version);
    }
    
    totalDict[MCCursorDictionaryAuthorKey]      = author;
    totalDict[MCCursorDictionaryCapeNameKey]    = name;
    totalDict[MCCursorDictionaryCapeVersionKey] = @(version);
    totalDict[MCCursorDictionaryIdentifierKey]  = identifier;
    
    return totalDict;
}

NSDictionary *processedCapeWithIdentifier(NSString *identifier) {
    NSMutableDictionary *dict = capeWithIdentifier(identifier).mutableCopy;
    if (!dict)
        return nil;
    
    NSDictionary *cursors = dict[MCCursorDictionaryRepresentationsKey];
    NSMutableArray *reps = [NSMutableArray array];
    
    for (id image in cursors) {
        CGImageRef im = (__bridge CGImageRef)image;
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:im];
    
        reps[reps.count] = pngDataForImage(rep.ensuredSRGBSpace);
    }
    
    dict[MCCursorDictionaryRepresentationsKey] = reps;
    return dict;
}

BOOL dumpCursorsToFile(NSString *path, BOOL (^progress)(NSUInteger current, NSUInteger total)) {
    MMLog("Dumping cursors...");
        
    float originalScale;
    CGSGetCursorScale(CGSMainConnectionID(), &originalScale);
    
    CGSSetCursorScale(CGSMainConnectionID(), 16.0);
    CGSHideCursor(CGSMainConnectionID());

    NSInteger total = 9 + 45;
    NSInteger current = 0;

    NSMutableDictionary *cursors = [NSMutableDictionary dictionary];
    NSUInteger i = 0;
    NSString *key = nil;
    while ((key = defaultCursors[i]) != nil) {
        if (progress) {
            current = i;

            if (!progress(current, total)) {
                return NO;
            }
        }
        MMLog("Gathering data for %s", key.UTF8String);
        cursors[key] = processedCapeWithIdentifier(key);
        i++;
    }
    
    for (int x = 0; x < 45; x++) {
        if (progress) {
            current = i + x;

            if (!progress(current, total)) {
                return NO;
            }
        }
        NSString *key = [@"com.apple.cursor." stringByAppendingFormat:@"%d", x];
        CoreCursorSet(CGSMainConnectionID(), x);

        NSDictionary *cape = processedCapeWithIdentifier(key);
        if (!cape)
            continue;
        
        MMLog("Gathering data for %s", key.UTF8String);
        
        cursors[key] = cape;
    }

    if (progress) {
        progress(total, total);
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
    
    return [cape writeToFile:path atomically:NO];
}

BOOL dumpCursorsToFolder(NSString *path, BOOL (^progress)(NSUInteger current, NSUInteger total)) {
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    
    MMLog("Dumping cursors...");
    
    float originalScale;
    CGSGetCursorScale(CGSMainConnectionID(), &originalScale);
    
    CGSSetCursorScale(CGSMainConnectionID(), 16.0);
    CGSHideCursor(CGSMainConnectionID());

    NSInteger total = 9 + 45;
    NSInteger current = 0;

    NSUInteger i = 0;
    NSString *key = nil;
    while ((key = defaultCursors[i]) != nil) {
        current = i;
        if (progress) {
            if (!progress(current, total)) {
                return NO;
            }
        }
        MMLog("Gathering data for %s", key.UTF8String);
        NSDictionary *cape = processedCapeWithIdentifier(key);
        
        [[cape[MCCursorDictionaryRepresentationsKey] lastObject] writeToFile:[[path stringByAppendingPathComponent:key] stringByAppendingPathExtension:@"png"] atomically: NO];
        i++;
    }
    
    for (int x = 0; x < 45; x++) {
        current = i + x;
        if (progress) {
            if (!progress(current, total)) {
                return NO;
            }
        }
        NSString *key = [@"com.apple.cursor." stringByAppendingFormat:@"%d", x];
        CoreCursorSet(CGSMainConnectionID(), x);
        
        NSDictionary *cape = processedCapeWithIdentifier(key);
        if (!cape)
            continue;
        
        MMLog("Gathering data for %s", key.UTF8String);
        
        [[cape[MCCursorDictionaryRepresentationsKey] lastObject] writeToFile:[[path stringByAppendingPathComponent:key] stringByAppendingPathExtension:@"png"] atomically:NO];
    }
    
    if (progress) {
        progress(total, total);
    }

    CGSSetCursorScale(CGSMainConnectionID(), originalScale);
    CGSShowCursor(CGSMainConnectionID());

    return YES;
}

extern void exportCape(NSDictionary *cape, NSString *destination) {
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:destination withIntermediateDirectories:YES attributes:nil error:nil];

    NSDictionary *cursors = cape[MCCursorDictionaryCursorsKey];
    for (NSString *key in cursors) {
        NSArray *reps = cursors[key][MCCursorDictionaryRepresentationsKey];
        for (NSUInteger idx = 0; idx < reps.count; idx++) {
            NSData *data = reps[idx];
            [data writeToFile:[destination stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%lu.png", key, (unsigned long)idx]] atomically:NO];
        }
    }
}
