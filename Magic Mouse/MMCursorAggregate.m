//
//  MMCursorAggregate.m
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/25/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import "MMCursorAggregate.h"
#import "MMDefs.h"

#import <Accelerate/Accelerate.h>

@implementation MMCursorAggregate
@synthesize cursors = _cursors;
- (id)init {
	if ((self = [super init])) {
		_cursors = [NSMutableDictionary dictionary];
	}
	return self;
}
- (void)dealloc {
	self.cursors = nil;
	[super dealloc];
}
- (void)setCursor:(MMCursor *)cursor forDomain:(NSString *)domain {
	if (!domain||!cursor)
		return;
	[_cursors setObject:cursor forKey:domain];
}
- (void)removeCursorForDomain:(NSString *)domain {
	if (!domain)
		return;
	[_cursors removeObjectForKey:domain];
}
- (NSDictionary*)dictionaryRepresentation {
	NSMutableDictionary *root        = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *cursors     = [[NSMutableDictionary alloc] initWithCapacity:2];
	NSMutableDictionary *cursorData  = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *global      = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *identifiers = [[NSMutableDictionary alloc] init];
	
	for (NSString *key in self.cursors) {
		MMCursor *cursor = [self.cursors objectForKey:key];
		[identifiers setObject:cursor.infoDictionary forKey:key];
		[cursorData  setObject:cursor.cursorDictionary forKey:cursor.customKey];
	}
	
	[global  setObject:identifiers            forKey:(NSString *)kCursorInfoIdentifiersKey];
	[cursors setObject:cursorData             forKey:(NSString *)kCursorDataKey];
	[cursors setObject:global                 forKey:(NSString *)kCursorInfoKey];
	
	[root    setObject:cursors                forKey:(NSString *)kCursorsKey];
	[root    setObject:(NSString *)kMMVersion forKey:(NSString *)kMinimumVersionKey];
	[root    setObject:(NSString *)kMMVersion forKey:(NSString *)kCreatorVersionKey];
	
	[identifiers release];
	[cursorData  release];
	[global      release];
	[cursors     release];
	
	return [root autorelease];
}
@end

@implementation MMCursor
@synthesize image           = _image;
@synthesize frameCount      = _frameCount;
@synthesize frameDuration   = _frameDuration;
@synthesize size            = _size;
@synthesize hotSpot         = _hotSpot;
@synthesize tableIdentifier = _tableIdentifier;
@synthesize defaultKey      = _defaultKey;
@synthesize customKey       = _customKey;
@synthesize name            = _name;

+ (MMCursor*)cursorWithDictionary:(NSDictionary *)dict {
	return [[[self alloc] initWithCursorDictionary:dict] autorelease];
}

- (id)init {
	if ((self = [super init])) {
		// Some default values
		self.name            = @"";
		self.customKey       = @"";
		self.defaultKey      = @"";
		self.tableIdentifier = @"";
		self.frameCount      = 1;
		self.frameDuration   = 0.0299999993294477;
	}
	return self;
}

- (id)initWithCursorDictionary:(NSDictionary *)dict {
	if ((self = [self init])) {
		NSData *rawData           = [dict objectForKey:(NSString *)kCursorDataDataKey];
		NSNumber *width           = [dict objectForKey:(NSString *)kCursorDataPixelsWideKey];
		NSNumber *height          = [dict objectForKey:(NSString *)kCursorDataPixelsHighKey];
		NSNumber *hotSpotX        = [dict objectForKey:(NSString *)kCursorDataHotspotXKey];
		NSNumber *hotSpotY        = [dict objectForKey:(NSString *)kCursorDataHotspotYKey];
		NSNumber *bytesPerRow     = [dict objectForKey:(NSString *)kCursorDataBytesPerRowKey];
		NSNumber *bitsPerSample   = [dict objectForKey:(NSString *)kCursorDataBitsPerSampleKey];
		NSNumber *bitsPerPixel    = [dict objectForKey:(NSString *)kCursorDataBitsPerPixelKey];
		NSNumber *samplesPerPixel = [dict objectForKey:(NSString *)kCursorDataSamplesPerPixelKey];
		NSNumber *frameCount      = [dict objectForKey:(NSString *)kCursorDataFrameCountKey];
		NSNumber *frameDuration   = [dict objectForKey:(NSString *)kCursorDataFrameDurationKey];
		
		self.frameCount           = frameCount.integerValue;
		self.frameDuration        = frameDuration.doubleValue;
		self.size                 = NSMakeSize(width.integerValue, height.integerValue);
		self.hotSpot              = NSMakePoint(hotSpotX.floatValue, hotSpotY.floatValue);
		
		// Convert the raw data into a presentable format
		NSBitmapImageRep *rep     = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:(void*)rawData.bytes 
																		pixelsWide:self.size.width
																		pixelsHigh:self.size.height
																	 bitsPerSample:bitsPerSample.integerValue
																   samplesPerPixel:samplesPerPixel.integerValue 
																		  hasAlpha:YES 
																		  isPlanar:NO
																	colorSpaceName:NSDeviceRGBColorSpace 
																	  bitmapFormat:NSAlphaNonpremultipliedBitmapFormat | NSAlphaFirstBitmapFormat | kCGBitmapByteOrder32Big
																	   bytesPerRow:bytesPerRow.integerValue
																	  bitsPerPixel:bitsPerPixel.integerValue];
		self.image                = rep;
		[rep release];
		
	}
	return self;
}

- (NSDictionary*)cursorDictionary {
	// Creates and returns a dictionary representation for use with magic mouse
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:11];
	
	// Convert the image to raw data
	unsigned char *bytePtr    = [self.image bitmapData];
	BOOL alphaFirst           = (self.image.bitmapFormat & NSAlphaFirstBitmapFormat)            == NSAlphaFirstBitmapFormat;
	BOOL premultiplied        = (self.image.bitmapFormat & NSAlphaNonpremultipliedBitmapFormat) == NSAlphaNonpremultipliedBitmapFormat;
	BOOL littleByteOrder      = (self.image.bitmapFormat & kCGBitmapByteOrder32Little)          == kCGBitmapByteOrder32Little;
	
	vImage_Buffer src;
	src.data     = (void*)bytePtr;
	src.rowBytes = self.image.bytesPerRow;
	src.width    = self.image.size.width;
	src.height   = self.image.size.height;
	
	uint8_t permuteMap[4];
	
	// Arrange the bytes to 32 big order and alpha non-premultiplied first
	if (alphaFirst) {
		if (littleByteOrder) {
			// BGRA to ARGB
			permuteMap[0] = 3;
			permuteMap[1] = 2;
			permuteMap[2] = 1;
			permuteMap[3] = 0;
		} else {
			// ARGB to ARGB
			permuteMap[0] = 0;
			permuteMap[1] = 1;
			permuteMap[2] = 2;
			permuteMap[3] = 3;
		}
		
	} else {
		if (littleByteOrder) {
			// ABGR to ARGB
			permuteMap[0] = 0;
			permuteMap[1] = 3;
			permuteMap[2] = 2;
			permuteMap[3] = 1;
		} else {
			// RGBA to ARGB
			permuteMap[0] = 3;
			permuteMap[1] = 0;
			permuteMap[2] = 1;
			permuteMap[3] = 2;
		}
	}
	vImagePermuteChannels_ARGB8888(&src, &src, permuteMap, 0);
	
	if (premultiplied) {
		vImageUnpremultiplyData_ARGB8888(&src, &src, 0);
	}
	
	// Finally set the values
	NSData *rawData = [NSData dataWithBytes:src.data length:src.rowBytes * src.height];
	[dict setObject:rawData                                                 forKey:(NSString *)kCursorDataDataKey];
	[dict setObject:[NSNumber numberWithInteger:self.image.bytesPerRow]     forKey:(NSString *)kCursorDataBytesPerRowKey];
	[dict setObject:[NSNumber numberWithInteger:self.image.samplesPerPixel] forKey:(NSString *)kCursorDataSamplesPerPixelKey];
	[dict setObject:[NSNumber numberWithInteger:self.image.bitsPerPixel]    forKey:(NSString *)kCursorDataBitsPerPixelKey];
	[dict setObject:[NSNumber numberWithInteger:self.image.bitsPerSample]   forKey:(NSString *)kCursorDataBitsPerSampleKey];
	[dict setObject:[NSNumber numberWithFloat:self.frameDuration]           forKey:(NSString *)kCursorDataFrameDurationKey];
	[dict setObject:[NSNumber numberWithInteger:self.frameCount]            forKey:(NSString *)kCursorDataFrameCountKey];
	[dict setObject:[NSNumber numberWithInteger:self.size.width]            forKey:(NSString *)kCursorDataPixelsWideKey];
	[dict setObject:[NSNumber numberWithInteger:self.size.height]           forKey:(NSString *)kCursorDataPixelsHighKey];
	[dict setObject:[NSNumber numberWithInteger:self.hotSpot.x]             forKey:(NSString *)kCursorDataHotspotXKey];
	[dict setObject:[NSNumber numberWithInteger:self.hotSpot.y]             forKey:(NSString *)kCursorDataHotspotYKey];
	
	return dict;
}

- (NSDictionary*)infoDictionary {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			self.defaultKey, (NSString *)kCursorInfoDefaultKey, 
			self.customKey, (NSString*)kCursorInfoCustomKey, 
			self.name, (NSString *)kCursorInfoNameKey, 
			self.tableIdentifier, (NSString*)kCursorInfoTableIdentifierKey, nil];
}

@end