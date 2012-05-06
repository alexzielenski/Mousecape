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

@interface MMCursorAggregate ()
@property (nonatomic, copy, readwrite) NSString *path;
@end

@implementation MMCursorAggregate
@synthesize path           = _path;
@synthesize cursors        = _cursors;
@synthesize minimumVersion = _minimumVersion;
@synthesize creatorVersion = _creatorVersion;

// creating an aggregate from a file
+ (MMCursorAggregate *)aggregateWithContentsOfFile:(NSString *)path
{
	return [[[self alloc] initWithContentsOfFile:path] autorelease];
}

- (id)initWithContentsOfFile:(NSString *)path
{
	if ((self = [self initWithAggregateDictionary:[NSDictionary dictionaryWithContentsOfFile:path]]))
		self.path = path;
	
	return self;
}

+ (MMCursorAggregate *)aggregateWithDictionary:(NSDictionary *)dict {
	return [[[self alloc] initWithAggregateDictionary:dict] autorelease];
}
//!*****************************************************************************************************************************************//
//!** The cursor files are merely plists. They have a root dict with a minimum version, and creator version, and a child dictionary with  **//
//!** an Identifiers dictionary and a Cursor data dictionary. each contain neccssary information to override the internal system cursors. **//
//!*****************************************************************************************************************************************//
- (id)initWithAggregateDictionary:(NSDictionary *)dict {
	if ((self = [self init])) {
		NSDictionary *cursors       = [dict objectForKey:(NSString *)kCursorsKey];
		NSDictionary *cursorData    = [cursors objectForKey:(NSString *)kCursorDataKey];
		
		NSDictionary *global        = [cursors objectForKey:(NSString *)kCursorInfoKey];
		NSDictionary *identifiers   = [global objectForKey:(NSString *)kCursorInfoIdentifiersKey];
		
		for (NSString *key in identifiers) {
			NSDictionary *info      = [identifiers objectForKey:key];
			NSDictionary *data      = [cursorData objectForKey:[info objectForKey:(NSString *)kCursorInfoCustomKey]];
			
			MMCursor *cursor        = [MMCursor cursorWithDictionary:data];
			cursor.cursorIdentifier = key;
			cursor.defaultKey       = [info objectForKey:(NSString *)kCursorInfoDefaultKey];
			cursor.customKey        = [info objectForKey:(NSString *)kCursorInfoCustomKey];
			cursor.name             = [info objectForKey:(NSString *)kCursorInfoNameKey];
			cursor.tableIdentifier  = [info objectForKey:(NSString *)kCursorInfoTableIdentifierKey];
			
			[self setCursor:cursor forDomain:key];
		}
		
		self.minimumVersion = [dict objectForKey:(NSString *)kMinimumVersionKey];
		self.creatorVersion = [dict objectForKey:(NSString *)kCreatorVersionKey];
	}
	return self;
}

- (id)init {
	if ((self = [super init])) {
		_cursors = [NSMutableDictionary dictionary];
		self.minimumVersion = @"1.02";
		self.creatorVersion = @"1.02";
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

- (MMCursor *)cursorForTableIdentifier:(NSString *)identifier {
	NSArray *ar = [self.cursors.allValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"tableIdentifier == %@", identifier]];
	if (ar.count>0)
		return [ar objectAtIndex:0];
	return nil;
}

- (NSDictionary *)dictionaryRepresentation {
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
	[root    setObject:self.minimumVersion    forKey:(NSString *)kMinimumVersionKey];
	[root    setObject:self.creatorVersion    forKey:(NSString *)kCreatorVersionKey];
	
	[identifiers release];
	[cursorData  release];
	[global      release];
	[cursors     release];
	
	return [root autorelease];
}

@end

@implementation MMCursor
@synthesize image            = _image;
@synthesize frameCount       = _frameCount;
@synthesize frameDuration    = _frameDuration;
@synthesize size             = _size;
@synthesize hotSpot          = _hotSpot;
@synthesize tableIdentifier  = _tableIdentifier;
@synthesize defaultKey       = _defaultKey;
@synthesize customKey        = _customKey;
@synthesize name             = _name;
@synthesize cursorIdentifier = _cursorIdentifier;

+ (MMCursor *)cursorWithDictionary:(NSDictionary *)dict {
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

- (void)dealloc {
	self.image            = nil;
	self.tableIdentifier  = nil;
	self.defaultKey       = nil;
	self.customKey        = nil;
	self.name             = nil;
	self.cursorIdentifier = nil;
	
	[super dealloc];
}

//!*******************************************************************************************************************************************//
//!** The dictionary passed would be one of the subdictionaries in the cursor data field. This method retrieves all the required info for   **//
//!** creating a bitmap from keys in this dictionary. Other values from the identifiers dictionary are added in the parent cursor aggregate.**//
//!*******************************************************************************************************************************************//

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
//		NSNumber *samplesPerPixel = [dict objectForKey:(NSString *)kCursorDataSamplesPerPixelKey]; // This key is not needed
		NSNumber *frameCount      = [dict objectForKey:(NSString *)kCursorDataFrameCountKey];
		NSNumber *frameDuration   = [dict objectForKey:(NSString *)kCursorDataFrameDurationKey];
		
		self.frameCount           = frameCount.integerValue;
		self.frameDuration        = frameDuration.doubleValue;
		self.size                 = NSMakeSize(width.integerValue, height.integerValue);
		self.hotSpot              = NSMakePoint(hotSpotX.floatValue, hotSpotY.floatValue);
		
		// Convert the raw data into a presentable format.
		
		// For some crazy reason, It won't let me create the image straight using the NSBitmapImageRep. (32big & Alpha first). 
		// I will use  CGimage and convert it for now
		CGDataProviderRef dataProvider    = CGDataProviderCreateWithCFData((CFDataRef)rawData);
		CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
		CGImageRef cursorImage = CGImageCreate(self.size.width,
											   self.size.height * self.frameCount, 
											   bitsPerSample.intValue, 
											   bitsPerPixel.intValue, 
											   bytesPerRow.intValue, 
											   colorspace, 
											   kCGBitmapByteOrder32Big | kCGImageAlphaFirst, 
											   dataProvider, NULL, false, kCGRenderingIntentDefault);
		CGColorSpaceRelease(colorspace);
		CGDataProviderRelease(dataProvider);
		
		NSBitmapImageRep *rep     = [[NSBitmapImageRep alloc] initWithCGImage:cursorImage];
		self.image                = rep;
		CGImageRelease(cursorImage);
		[rep release];
	}
	return self;
}

//!*****************************************************************************************************************************************//
//!** In this method the values are taken from the MMCursor properties and converted for use in the plist. Specifically, the raw pixel    **//
//!** data gets reformatted to ARGB 32-big pixel format to ensure consistency among all of the cursors so that magic mouse can read it.   **//
//!*****************************************************************************************************************************************//

- (NSDictionary *)cursorDictionary {
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
	
	//! Arrange the bytes to 32 big order and alpha non-premultiplied first. It is imperative that all of tha raw data follows the same format
	//! (ARGB, 32-big byte order) otherwise consequences will ensue.
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
	// Permute the data using the "scramble" values above
	vImagePermuteChannels_ARGB8888(&src, &src, permuteMap, 0);
	
	if (premultiplied) {
		// The final data must also remain unpremultiplied, so undo this if the image is unpremultiplied.
		vImageUnpremultiplyData_ARGB8888(&src, &src, 0);
	}
	
	// Finally set the values to their appropriate key.
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

//!*****************************************************************************************************************************************//
//!** This method creates the dictionary for use in the Identifiers dictionary. (As opposed to cursor data above). These values are       **//
//!** assigned during initialization in the cursor aggregate and are used to see which cursor image replaces what and where to display it **//
//!*****************************************************************************************************************************************//

- (NSDictionary *)infoDictionary {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			self.defaultKey, (NSString *)kCursorInfoDefaultKey, 
			self.customKey, (NSString*)kCursorInfoCustomKey, 
			self.name, (NSString *)kCursorInfoNameKey, 
			self.tableIdentifier, (NSString*)kCursorInfoTableIdentifierKey, nil];
}

@end