//
//  MCCursor.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCCursor.h"

MCCursorScale cursorScaleForScale(CGFloat scale) {
    if (scale < 0.0)
        return MCCursorScaleNone;
    
    return (MCCursorScale)((NSInteger)scale * 100);
}

@interface MCCursor ()
@property (readwrite, strong) NSMutableDictionary *representations;
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary ofVersion:(CGFloat)version;
@end

@implementation MCCursor
@dynamic name;

+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version {
    return [[self alloc] initWithCursorDictionary:dict ofVersion:version];
}

- (id)init {
    if ((self = [super init])) {
        self.frameCount      = 1;
        self.frameDuration   = 1.0;
        self.size            = NSZeroSize;
        self.hotSpot         = NSZeroPoint;
        self.identifier      = [UUID() stringByReplacingOccurrencesOfString:@"-" withString:@""];
        self.representations = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithCursorDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version {
    if ((self = [self init])) {
        
        if (![self _readFromDictionary:dict ofVersion:version])
            return nil;
        
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MCCursor *cursor = [[MCCursor allocWithZone:zone] init];
    
    cursor.frameCount      = self.frameCount;
    cursor.frameDuration   = self.frameDuration;
    cursor.size            = self.size;
    cursor.representations = self.representations.mutableCopy;
    cursor.hotSpot         = self.hotSpot;
    cursor.identifier      = self.identifier;
    
    return cursor;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {    
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"imageWithAllReps"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[ @"representations" ]];
    } else if ([key isEqualToString:@"name"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[ @"identifier" ]];
    } else if ([key hasPrefix:@"cursorImage"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[ [key stringByReplacingCharactersInRange:NSMakeRange(6, 5) withString:@"Rep"] ]];
    }
    
    return keyPaths;
}

- (BOOL)_readFromDictionary:(NSDictionary *)dictionary ofVersion:(CGFloat)version {
    if (!dictionary || !dictionary.count)
        return NO;
    
    NSNumber *frameCount    = [dictionary objectForKey:MCCursorDictionaryFrameCountKey];
    NSNumber *frameDuration = [dictionary objectForKey:MCCursorDictionaryFrameDuratiomKey];
    //    NSNumber *repeatCount   = dictionary[MCCursorDictionaryRepeatCountKey];
    NSNumber *hotSpotX      = [dictionary objectForKey:MCCursorDictionaryHotSpotXKey];
    NSNumber *hotSpotY      = [dictionary objectForKey:MCCursorDictionaryHotSpotYKey];
    NSNumber *pointsWide    = [dictionary objectForKey:MCCursorDictionaryPointsWideKey];
    NSNumber *pointsHigh    = [dictionary objectForKey:MCCursorDictionaryPointsHighKey];
    NSArray *reps           = [dictionary objectForKey:MCCursorDictionaryRepresentationsKey];
    
    // we only take version 2.0 documents.
    if (version >=  2.0) {
        if (frameCount && frameDuration && hotSpotX && hotSpotY && pointsWide && pointsHigh) {
            
            self.frameCount    = frameCount.unsignedIntegerValue;
            self.frameDuration = frameDuration.doubleValue;
            self.hotSpot       = NSMakePoint(hotSpotX.doubleValue, hotSpotY.doubleValue);
            self.size          = NSMakeSize(pointsWide.doubleValue, pointsHigh.doubleValue);
            //            self.repeatCount   = repeatCount.unsignedIntegerValue;
            
            for (NSData *data in reps) {
                // data in v2.0 documents are saved as PNGs
                NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:data];
                rep.size = NSMakeSize(self.size.width, self.size.height * self.frameCount);
                [self setRepresentation:rep forScale:cursorScaleForScale(rep.pixelsWide / self.size.width)];
            }
            
            return YES;
        }
    }

    return NO;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *drep = [NSMutableDictionary dictionary];
    drep[MCCursorDictionaryFrameCountKey]    = @(self.frameCount);
    drep[MCCursorDictionaryFrameDuratiomKey] = @(self.frameDuration);
    drep[MCCursorDictionaryHotSpotXKey]      = @(self.hotSpot.x);
    drep[MCCursorDictionaryHotSpotYKey]      = @(self.hotSpot.y);
    drep[MCCursorDictionaryPointsWideKey]    = @(self.size.width);
    drep[MCCursorDictionaryPointsHighKey]    = @(self.size.height);
    
    NSMutableArray *pngs = [NSMutableArray array];
    for (NSString *key in self.representations) {
        NSBitmapImageRep *rep = self.representations[key];
        pngs[pngs.count] = [rep representationUsingType:NSPNGFileType properties:nil];
    }
    
    drep[MCCursorDictionaryRepresentationsKey] = pngs;
    
    return drep;
}

- (id)valueForUndefinedKey:(NSString *)key {
    // Special KVC for observers to be able to watch each scale
    if ([key hasPrefix:@"cursorRep"] || [key hasPrefix:@"cursorImage"]) {
        NSString *prefix = [key hasPrefix:@"cursorRep"] ? @"cursorRep" : @"cursorImage";

        NSString *scaleString = [key substringFromIndex:prefix.length];
        CGFloat scale = [scaleString doubleValue] / 100;
        
        if ([key hasPrefix:@"cursorRep"])
            return [self representationForScale:cursorScaleForScale(scale)];
        else {
            NSImageRep *rep = [self representationForScale:cursorScaleForScale(scale)];
            if (rep) {
                NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(rep.pixelsWide / scale, rep.pixelsHigh / scale)];
                [image addRepresentation:rep];
                return image;
            }
            return nil;
        }
    }
    
    return [super valueForUndefinedKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // Special KVC for observers to be able to watch each scale
    if ([key hasPrefix:@"cursorRep"] || [key hasPrefix:@"cursorImage"]) {
        NSString *prefix = [key hasPrefix:@"cursorRep"] ? @"cursorRep" : @"cursorImage";
        NSString *scaleString = [key substringFromIndex:prefix.length];
        CGFloat scale = [scaleString doubleValue] / 100;
        
        if ([key hasPrefix:@"cursorImage"]) {
            value = [(NSImage *)value representations][0];
        }
        
        [self setRepresentation:value forScale:cursorScaleForScale(scale)];
        return;
    }
    
    [super setValue:value forUndefinedKey:key];
}

- (void)setRepresentation:(NSImageRep *)imageRep forScale:(MCCursorScale)scale {
    [self willChangeValueForKey:@"representations"];
    
    NSString *key = [@"cursorRep" stringByAppendingFormat:@"%lu", scale];
    [self willChangeValueForKey:key];
    if (imageRep)
        [self.representations setObject:imageRep forKey:@(scale)];
    else
        [self.representations removeObjectForKey:@(scale)];
    [self didChangeValueForKey:key];
    [self didChangeValueForKey:@"representations"];
}

- (void)removeRepresentationForScale:(MCCursorScale)scale {
    [self setRepresentation:Nil forScale:scale];
}

- (NSImageRep *)representationForScale:(MCCursorScale)scale {
    return self.representations[@(scale)];
}

- (NSImageRep *)representationWithScale:(CGFloat)scale {
    return [self representationForScale:cursorScaleForScale(scale)];
}

- (NSImage *)imageWithAllReps {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(self.size.width, self.size.height * self.frameCount)];
    image.matchesOnMultipleResolution  = YES;
    [image addRepresentations:self.representations.allValues];
    return image;
}

- (NSString *)name {
    return nameForCursorIdentifier(self.identifier);
}

- (BOOL)isEqualTo:(MCCursor *)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    BOOL props =  (object.frameCount == self.frameCount &&
                   object.frameDuration == self.frameDuration &&
                   NSEqualSizes(object.size, self.size) &&
                   NSEqualPoints(object.hotSpot, self.hotSpot) &&
                   [object.identifier isEqualToString:self.identifier]);

//    props = (props && [self.representations isEqualToDictionary:object.representations]);
    
    return props;
}

- (BOOL)isEqual:(id)object {
    return [self isEqualTo:object];
}

@end
