//
//  MCCursor.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/8/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCCursor.h"

// Required cursors for cape format 2.0
static const NSString *MCCursorDictionaryFrameCountKey      = @"FrameCount";
static const NSString *MCCursorDictionaryFrameDuratiomKey   = @"FrameDuration";
static const NSString *MCCursorDictionaryHotSpotXKey        = @"HotSpotX";
static const NSString *MCCursorDictionaryHotSpotYKey        = @"HotSpotY";
static const NSString *MCCursorDictionaryPointsWideKey      = @"PointsWide";
static const NSString *MCCursorDictionaryPointsHighKey      = @"PointsHigh";
static const NSString *MCCursorDictionaryRepresentationsKey = @"Representations";

@interface MCCursor ()
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary ofVersion:(CGFloat)version;
@end

@implementation MCCursor

+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version
{
    return [[self alloc] initWithCursorDictionary:dict ofVersion:version];
}

- (id)init {
    if ((self = [super init])) {
        self.name = @"Unknown";
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

- (BOOL)_readFromDictionary:(NSDictionary *)dictionary ofVersion:(CGFloat)version
{
    NSNumber *frameCount    = [dictionary objectForKey:MCCursorDictionaryFrameCountKey];
    NSNumber *frameDuration = [dictionary objectForKey:MCCursorDictionaryFrameDuratiomKey];
    NSNumber *hotSpotX      = [dictionary objectForKey:MCCursorDictionaryHotSpotXKey];
    NSNumber *hotSpotY      = [dictionary objectForKey:MCCursorDictionaryHotSpotYKey];
    NSNumber *pointsWide    = [dictionary objectForKey:MCCursorDictionaryPointsWideKey];
    NSNumber *pointsHigh    = [dictionary objectForKey:MCCursorDictionaryPointsHighKey];
    NSArray *reps           = [dictionary objectForKey:MCCursorDictionaryRepresentationsKey];
    
    // we only take version 2.0 documents.
    if (version == 2.0) {
        if (frameCount && frameDuration && hotSpotX && hotSpotY && pointsWide && pointsHigh && reps && reps.count > 0) {
            self.frameCount = frameCount.unsignedIntegerValue;
            self.frameDuration = frameDuration.doubleValue;
            self.hotSpot = NSMakePoint(hotSpotX.doubleValue, hotSpotY.doubleValue);
            self.size = NSMakeSize(pointsWide.doubleValue, pointsHigh.doubleValue);
            
            NSMutableArray *bitmaps = [NSMutableArray array];
            
            for (NSData *data in reps) {
                // data in v2.0 documents are saved as PNGs
                NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:data];
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
    NSArray *sorted = [self.representations sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"pixelsWide" ascending:YES]]];
  
    [image addRepresentations:sorted];
    
    return image;
}

@end
