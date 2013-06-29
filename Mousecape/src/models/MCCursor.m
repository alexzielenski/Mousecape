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
@property (readwrite, strong) NSMutableOrderedSet *representations;
@property (copy) NSString *prettyName;
@property (strong) NSArray *keyReps;
@property (strong) NSImage *imageWithAllReps;
@property (strong) NSImage *imageWithKeyReps;
- (NSArray *)keyScales;
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary ofVersion:(CGFloat)version;
@end

@implementation MCCursor
+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version {
    return [[self alloc] initWithCursorDictionary:dict ofVersion:version];
}

- (id)init {
    if ((self = [super init])) {
        self.prettyName = @"Unknown";
        
        @weakify(self);
        [self rac_addDeallocDisposable:[self rac_deriveProperty:@"prettyName" from:[RACAble(self.identifier) map:^NSString *(NSString *ident) {
            NSString *name = nil;
            if (ident)
                name = [MCCursorLibrary.cursorMap objectForKey:ident];
            return name ? name : @"Unknown";
        }]]];
        
        [self rac_addDeallocDisposable:[self rac_deriveProperty:@"keyReps" from:[RACAble(self.representations) map:^NSArray *(NSOrderedSet *value) {
            @strongify(self);
            
            NSMutableArray *ar = [NSMutableArray array];
            
            for (NSNumber *scale in self.keyScales) {
                CGFloat scl = scale.doubleValue;
                NSImageRep *rep = [self representationWithScale:scl];
                rep.size = NSMakeSize(self.size.width, self.size.height * self.frameCount);
                
                if (rep)
                    [ar addObject:rep];
                
            }
            return ar;
            
        }]]];
        
        [self rac_addDeallocDisposable:[self rac_deriveProperty:@"imageWithKeyReps" from:[RACAble(self.keyReps) map:^NSImage *(NSArray *value) {
            @strongify(self);
            NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(self.size.width, self.size.height * self.frameCount)];
            image.matchesOnMultipleResolution = YES;
            [image addRepresentations:value];
            return image;
        }]]];
        
        [self rac_addDeallocDisposable:[self rac_deriveProperty:@"imageWithAllReps" from:[RACAble(self.representations) map:^NSImage *(NSOrderedSet *value) {
            @strongify(self);
            NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(self.size.width, self.size.height * self.frameCount)];
            [image addRepresentations:value.array];
            image.matchesOnMultipleResolution  = YES;
            
            return image;
        }]]];
        
        self.frameCount = 1;
        self.frameDuration = 1.0;
        self.size = NSZeroSize;
        self.hotSpot = NSZeroPoint;
        self.representations = [NSMutableOrderedSet orderedSet];
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
    
    return cursor;
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
    if (version == 2.0) {
        if (frameCount && frameDuration && hotSpotX && hotSpotY && pointsWide && pointsHigh && reps && reps.count > 0) {
            
            self.frameCount    = frameCount.unsignedIntegerValue;
            self.frameDuration = frameDuration.doubleValue;
            self.hotSpot       = NSMakePoint(hotSpotX.doubleValue, hotSpotY.doubleValue);
            self.size          =  NSMakeSize(pointsWide.doubleValue, pointsHigh.doubleValue);
//            self.repeatCount   = repeatCount.unsignedIntegerValue;
            
            NSMutableOrderedSet *bitmaps = [NSMutableOrderedSet orderedSet];
            
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

- (void)addRepresentation:(NSImageRep *)imageRep {
    if (![self.representations containsObject:imageRep]) {
        NSIndexSet *iset = [NSIndexSet indexSetWithIndex:self.representations.count];

        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:iset forKey:@"representations"];
        [self.representations addObject:imageRep];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:iset forKey:@"representations"];
    }
}

- (void)removeRepresentation:(NSImageRep *)imageRep {
    if ([self.representations containsObject:imageRep]) {
        NSIndexSet *iset = [NSIndexSet indexSetWithIndex:[self.representations indexOfObject:imageRep]];
        
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:iset forKey:@"representations"];
        [self.representations removeObject:imageRep];
        
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:iset forKey:@"representations"];
    }
}

- (NSImageRep *)representationWithScale:(CGFloat)scale {
    CGFloat destW = self.size.width * scale;
    CGFloat destH = self.size.height * scale * self.frameCount;
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"pixelsWide == %f && pixelsHigh == %f", destW, destH];
    NSSet *filtered = [self.representations.set filteredSetUsingPredicate:pred];
    return filtered.anyObject;
}

- (NSImageRep *)smallestRepresentationWithScale:(CGFloat *)scale {
    NSArray *scales = self.keyScales;
    for (NSNumber *sc in scales) {
        CGFloat currentScale = sc.doubleValue;
        NSImageRep *rep = [self representationWithScale:currentScale];
        if (rep) {
            if (*scale)
                *scale = currentScale;
            return rep;
        }
    }
    
    return nil;
}

- (NSArray *)keyScales {
   return  @[ @1, @2, @5, @10 ];
}

- (BOOL)isEqualTo:(MCCursor *)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
   BOOL props =  (object.frameCount == self.frameCount &&
                  object.frameDuration == self.frameDuration &&
                  NSEqualSizes(object.size, self.size) &&
                  NSEqualPoints(object.hotSpot, self.hotSpot) &&
                  [object.identifier isEqualToString:self.identifier] &&
                  object.parentLibrary == self.parentLibrary);
    
    props = ([self.representations isEqualToOrderedSet:object.representations]);
    
    return props;
}

@end
