//
//  MCCursor.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCCursor.h"
#import "MCCursorLibrary.h"

// Required cursors for cape format 2.0
static const NSString *MCCursorDictionaryFrameCountKey      = @"FrameCount";
static const NSString *MCCursorDictionaryFrameDuratiomKey   = @"FrameDuration";
//static const NSString *MCCursorDictionaryRepeatCountKey     = @"RepeatCount";
static const NSString *MCCursorDictionaryHotSpotXKey        = @"HotSpotX";
static const NSString *MCCursorDictionaryHotSpotYKey        = @"HotSpotY";
static const NSString *MCCursorDictionaryPointsWideKey      = @"PointsWide";
static const NSString *MCCursorDictionaryPointsHighKey      = @"PointsHigh";
static const NSString *MCCursorDictionaryRepresentationsKey = @"Representations";

@interface MCCursor ()
@property (readwrite, strong) NSMutableArray *representations;
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary ofVersion:(CGFloat)version;
@end

@implementation MCCursor
@dynamic identifier;

+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version {
    return [[self alloc] initWithCursorDictionary:dict ofVersion:version];
}

- (id)init {
    if ((self = [super init])) {
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
    //!TODO: Decide if we want to copy these images
    cursor.representations = self.representations.copy;
    cursor.hotSpot         = self.hotSpot;
    
    return cursor;
}

- (BOOL)_readFromDictionary:(NSDictionary *)dictionary ofVersion:(CGFloat)version {
    NSNumber *frameCount    = [dictionary objectForKey:MCCursorDictionaryFrameCountKey];
    NSNumber *frameDuration = [dictionary objectForKey:MCCursorDictionaryFrameDuratiomKey];
//    NSNumber *repeatCount   = dictionary[MCCursorDictionaryRepeatCountKey];
    NSNumber *hotSpotX      = [dictionary objectForKey:MCCursorDictionaryHotSpotXKey];
    NSNumber *hotSpotY      = [dictionary objectForKey:MCCursorDictionaryHotSpotYKey];
    NSNumber *pointsWide    = [dictionary objectForKey:MCCursorDictionaryPointsWideKey];
    NSNumber *pointsHigh    = [dictionary objectForKey:MCCursorDictionaryPointsHighKey];
    NSArray *reps           = [dictionary objectForKey:MCCursorDictionaryRepresentationsKey];
    
    // we only take version 2.0 documents.
    if (version == 2.0) {
        if (frameCount && frameDuration && hotSpotX && hotSpotY && pointsWide && pointsHigh && reps && reps.count > 0) {
            
            self.frameCount    = frameCount.unsignedIntegerValue;
            self.frameDuration = frameDuration.doubleValue;
            self.hotSpot       = NSMakePoint(hotSpotX.doubleValue, hotSpotY.doubleValue);
            self.size          =  NSMakeSize(pointsWide.doubleValue, pointsHigh.doubleValue);
//            self.repeatCount   = repeatCount.unsignedIntegerValue;
            
            NSMutableArray *bitmaps = [NSMutableArray array];
            
            for (NSData *data in reps) {
                // data in v2.0 documents are saved as PNGs
                NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:data];
                rep.size = NSMakeSize(self.size.width, self.size.height * self.frameCount);
                [bitmaps addObject:rep];
            }
            if (bitmaps.count == 0)
                return NO;
            
            self.representations = bitmaps;
            
            return YES;
        }
        
    }
    
    return NO;
}

- (NSImage *)imageWithAllReps {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(self.size.width, self.size.height * self.frameCount)];
    [image addRepresentations:self.representations];
    
    image.matchesOnMultipleResolution  = YES;
        
    return image;
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
    for (NSBitmapImageRep *rep in self.representations) {
        pngs[pngs.count] = [rep representationUsingType:NSPNGFileType properties:nil];
    }
    
    drep[MCCursorDictionaryRepresentationsKey] = pngs;
    
    return drep;
}

- (NSString *)identifier {
    return [self.parentLibrary identifierForCursor:self];
}

- (void)setIdentifier:(NSString *)identifier {
    [self.parentLibrary moveCursor:self toIdentifier:identifier];
}

- (NSString *)prettyName {
    NSString *name = [MCCursorLibrary.cursorMap objectForKey:self.identifier];
    return name ? name : @"Unknown";
}

- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString:@"hotSpot"]) {
        return [NSValue valueWithPoint:self.hotSpot];
    }
    
    if ([key isEqualToString:@"size"]) {
        return [NSValue valueWithSize:self.size];
    }
    
    return [super valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"hotSpot"]) {
        self.hotSpot = [value pointValue];
        return;
    }
    
    if ([key isEqualToString:@"size"]) {
        self.size = [value sizeValue];
        return;
    }
    
    [super setValue:value forKey:key];
}

- (void)addRepresentation:(NSBitmapImageRep *)imageRep {
    if (![self.representations containsObject:imageRep]) {
        NSIndexSet *iset = [NSIndexSet indexSetWithIndex:self.representations.count];

        [self willChangeValueForKey:@"imageWithAllReps"];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:iset forKey:@"representations"];
        
        [self.representations addObject:imageRep];
        
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:iset forKey:@"representations"];
        [self didChangeValueForKey:@"imageWithAllReps"];
    }
}

- (void)removeRepresentation:(NSBitmapImageRep *)imageRep {
    if ([self.representations containsObject:imageRep]) {
        NSIndexSet *iset = [NSIndexSet indexSetWithIndex:[self.representations indexOfObject:imageRep]];
        
        [self willChangeValueForKey:@"imageWithAllReps"];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:iset forKey:@"representations"];
        
        [self.representations removeObject:imageRep];
        
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:iset forKey:@"representations"];
        [self didChangeValueForKey:@"imageWithAllReps"];
    }
}

@end
