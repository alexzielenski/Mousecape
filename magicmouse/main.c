//
//  main.c
//  magicmouse
//
//  Created by Alex Zielenski on 2/20/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

/*! Perhaps it would be a good idea to store the original cursor under a different identifier
 while hooking the cursors so that we don't have a need to store them in the file or even use the one in the file. 
 We can wheck to see if the cursor is registered first and if not, register the original cursor and leave it be afterwards. 
 Then, it would be trivial to reset the cursors and a lot safer. The problem here is using NSCursor methods to get cursors that aren't
 registered at login (instead are registered only when used). eg. Dragging Copy. There might be a possibility the login window wouldn't let us
 use these methods since we aren't allowed a GUI there. But we would get a retry at that once the user logs in so it might not be a problem. 
 This fix would of course involve changing the extension of this file to .m and embedding Objective-C. */

#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>
#include <Accelerate/Accelerate.h>
#include "MMDefs.h"

#include "CGSCursor.h"
#include "CGSAccessibility.h"

// Macro to quickly create a mutable dictionary for CF types
#define CFMutableDictionaryCreateEmpty() CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)

// Function prototypes
CFStringRef tableIdentifierFromInt(int x);
CFStringRef nameFromInt(int x);
CFStringRef cursorIdentifierFromInt(int x);
CFStringRef createBackupIdentifierForIdentifier(CFStringRef ident);

// Method I used for debugging
static void CGImageWriteToFile(CGImageRef image, CFStringRef path) {
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, path , kCFURLPOSIXPathStyle, false);
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
	CFRelease(url);
	
    CGImageDestinationAddImage(destination, image, nil);
	
    bool success = CGImageDestinationFinalize(destination);
    if (!success) {
        MMLog("Failed to write image.\n");
    }
	
    CFRelease(destination);
}

// This method gets the name for the cursor plist dump in the identifiers dictionary
CFStringRef nameFromInt(int x) {
	CFStringRef rtn = CFSTR("");
	switch (x) {
		case 0:
			rtn = CFSTR("Arrow");
			break;
		case 1:
			rtn = CFSTR("I-Beam");
			break;
		case 2:
			rtn = CFSTR("I-Beam (XOR)");
			break;
		case 3:
			rtn = CFSTR("Alias");
			break;
		case 4:
			rtn = CFSTR("Small Copy");
			break;
		case 5:
			rtn = CFSTR("Small Move");
			break;
		case 6:
			rtn = CFSTR("Arrow (Context)");
			break;
		case 7:
			rtn = CFSTR("Wait");
			break;
		case 8:
			rtn = CFSTR("Empty");
			break;
		case 9:
			rtn = CFSTR("Big Alias");
			break;
		case 10:
			rtn = CFSTR("Forbidden");
			break;
		case 11:
			rtn = CFSTR("Big Copy");
			break;
	}
	return rtn;
}
// Links a certain cursor to a specific table column. Used by the prefpane
CFStringRef tableIdentifierFromInt(int x) {
	CFStringRef rtn = CFSTR("");
	switch (x) {
		case 0:
			rtn = CFSTR("Global.Identifiers.Arrow");
			break;
		case 1:
			rtn = CFSTR("Global.Identifiers.I-Beam");
			break;
		case 2:
			rtn = CFSTR("Global.Identifiers.I-Beam (XOR)");
			break;
		case 3:
			rtn = CFSTR("Global.Identifiers.Small Alias");
			break;
		case 4:
			rtn = CFSTR("Global.Identifiers.Small Copy");
			break;
		case 5:
			rtn = CFSTR("Global.Identifiers.Small Move");
			break;
		case 6:
			rtn = CFSTR("Global.Identifiers.Arrow (Context)");
			break;
		case 7:
			rtn = CFSTR("Global.Identifiers.Wait");
			break;
		case 8:
			rtn = CFSTR("Global.Identifiers.Empty");
			break;
		case 9:
			rtn = CFSTR("Global.Identifiers.Big Alias");
			break;
		case 10:
			rtn = CFSTR("Global.Identifiers.Forbidden");
			break;
		case 11:
			rtn = CFSTR("Global.Identifiers.Big Copy");
			break;
	}
	return rtn;
}
// Cursor reverse-dns identifier to override with out cursor image.
// these are pre-registered cursors by apple
CFStringRef cursorIdentifierFromInt(int x) {
	// System Defined
	// com.apple.coregraphics.Arrow    = 0
	// com.apple.coregraphics.IBeam    = 1
	// com.apple.coregraphics.IBeamXOR = 2
	// com.apple.coregraphics.Alias    = 3
	// com.apple.coregraphics.Copy     = 4
	// com.apple.coregraphics.Move     = 5
	// com.apple.coregraphics.ArrowCtx = 6
	// com.apple.coregraphics.Wait     = 7
	// com.apple.coregraphics.Empty    = 8
	
	// Not system defined?
	// com.apple.cursor.2              = Large Alias
	// com.apple.cursor.3              = Unavailable/Forbidden
	// com.apple.cursor.5              = Large Copy
	CFStringRef rtn = CFSTR("");
	switch (x) {
		case 0:
			rtn = CFSTR("com.apple.coregraphics.Arrow");
			break;
		case 1:
			rtn = CFSTR("com.apple.coregraphics.IBeam");
			break;
		case 2:
			rtn = CFSTR("com.apple.coregraphics.IBeamXOR");
			break;
		case 3:
			rtn = CFSTR("com.apple.coregraphics.Alias");
			break;
		case 4:
			rtn = CFSTR("com.apple.coregraphics.Copy");
			break;
		case 5:
			rtn = CFSTR("com.apple.coregraphics.Move");
			break;
		case 6:
			rtn = CFSTR("com.apple.coregraphics.ArrowCtx");
			break;
		case 7:
			rtn = CFSTR("com.apple.coregraphics.Wait");
			break;
		case 8:
			rtn = CFSTR("com.apple.coregraphics.Empty");
			break;
		case 9:
			rtn = CFSTR("com.apple.cursor.2");
			break;
		case 10:
			rtn = CFSTR("com.apple.cursor.3");
			break;
		case 11:
			rtn = CFSTR("com.apple.cursor.5");
			break;
	}	
	return rtn;
}


CFStringRef createBackupIdentifierForIdentifier(CFStringRef ident) {
	// Just take all the items after the first two and append them to com.alexzielenski.magicmouse
	return CFStringCreateWithFormat(0, NULL, CFSTR("com.alexzielenski.magicmouse.%@"), ident);
}

//! Gets data from one cursor and sets it to another. Though both co-exist
static void ReplaceCursorWithName(CFStringRef originalName, CFStringRef destinationName) {
	CFIndex bufferLength = CFStringGetMaximumSizeForEncoding(CFStringGetLength(originalName), kCFStringEncodingUTF8) + 1;
	
	char *CKey = (char*)malloc(bufferLength);
	CFStringGetCString(originalName, CKey, bufferLength, kCFStringEncodingUTF8);
	
	size_t dataSize;
	CGSGetRegisteredCursorDataSize(CGSMainConnectionID(), 
								   CKey, 
								   &dataSize);
	if (dataSize <= 0) {
		MMLog("Cannot swap cursors. Original one (%s) is nonexistant\n", CKey);
		free(CKey);
		return;
	}
	
	
	// Get the name we are going to register the new cursor under
	bufferLength = CFStringGetMaximumSizeForEncoding(CFStringGetLength(destinationName), kCFStringEncodingUTF8);
	char *BKey = (char*)malloc(bufferLength);
	
	CFStringGetCString(destinationName, BKey, bufferLength, kCFStringEncodingUTF8);
		
	
	void *data = malloc(dataSize);
	CGSize imageSize, cursorSize;
	CGPoint hotSpot;
	int bpp, bps, bpr, frameCount, spp;
	float frameDuration;
	
	// Get the original data
	CGSGetRegisteredCursorData2(CGSMainConnectionID(), 
								CKey, 
								data, 
								&dataSize,
								&bpr,
								&imageSize,
								&cursorSize,
								&hotSpot,
								&bpp,
								&spp,
								&bps,
								&frameCount,
								&frameDuration);
	
	if (imageSize.width == 0 || imageSize.height == 0) {
		MMLog("Cannot swap cursors. Original one (%s) is nonexistant\n", CKey);
		free(CKey);
		free(BKey);
		return;
	}
	
	CFDataRef dt = CFDataCreate(0, (UInt8*)data, dataSize);
	CGDataProviderRef provider = CGDataProviderCreateWithCFData(dt);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	
	CGImageRef originalCursor = CGImageCreate(imageSize.width, imageSize.height,
											  bps, bpp, bpr, colorspace, kCGBitmapByteOrder32Little | kCGImageAlphaFirst, 
											  provider, NULL, false32b, kCGRenderingIntentDefault);
	
	int seed;
	void *originalValues[1] = { originalCursor };
	CFArrayRef originalArray = CFArrayCreate(0, (const void**)originalValues, 1, NULL);
	
	// Register the original cursor under a different name
	CGError err = CGSRegisterCursorWithImages(CGSMainConnectionID(), 
											  BKey, 
											  true, false, 
											  frameCount, 
											  originalArray,
											  cursorSize,
											  hotSpot,
											  &seed, 
											  CGRectMake(0, 0, imageSize.width, imageSize.height),
											  frameDuration, 0);
	
	if (err != kCGErrorSuccess) {
		MMLog("Recieved error (%i) while swapping cursor. (%s)\n", err, CKey);
	}
	
	free(CKey);
	free(BKey);
	CFRelease(dt);
	CGImageRelease(originalCursor);
	CGDataProviderRelease(provider);
	CGColorSpaceRelease(colorspace);
}

//!******************************************************************************************************************************************************************/
//! This function gets the registered data for an original cursor before magic mouse replaces it and registers it under a different name that would never be used. **/
//! This is a safe & necessary way to backup the cursor locally without distributing it with every theme.                                                          **/
//!******************************************************************************************************************************************************************/
static void BackupCursor(CFStringRef originalIdentifier) {
	// Get the name we are going to register the new cursor under
	CFStringRef backupIdentifier = createBackupIdentifierForIdentifier(originalIdentifier);
	CFIndex bufferLength = CFStringGetMaximumSizeForEncoding(CFStringGetLength(backupIdentifier), kCFStringEncodingUTF8) + 1;
	
	char *CKey = (char*)malloc(bufferLength);
	CFStringGetCString(backupIdentifier, CKey, bufferLength, kCFStringEncodingUTF8);
	
	int dataSize = 1;
	CGSGetRegisteredCursorDataSize(CGSMainConnectionID(), 
								   CKey, 
								   &dataSize);
	
	// We don't want to back up the cursor if it has already been backed up.
	if (dataSize > 4) {
		MMLog("Cursor already backed up (size %i)\n", dataSize);
		free(CKey);
		CFRelease(backupIdentifier);
		return;
	}
	
	MMLog("Backing up cursor to %s\n", CKey);
	ReplaceCursorWithName(originalIdentifier, backupIdentifier);
	CFRelease(backupIdentifier);
}

// bool used if the '-r' option is specified which uses the default cursor key rather than the custom one
// from the plist file.
static bool useDefault = false;

//!*******************************************************************************************************************************/
//! Registers out cursors over Apple's. This function is called while looping through the identifiers dictionary                **/
//!    so 'cci' is the dictionary for the key 'k' and 'cd' is userInfo passed which is in this case the cursor data dictionary. **/
//!*******************************************************************************************************************************/
static void HookCursor(const void* k, const void* cci, void* cd) {
	// Let the compiler know the types of our variables
	CFStringRef key = (CFStringRef)k;	
	CFDictionaryRef currentCursorInfo = (CFDictionaryRef)cci;
	CFDictionaryRef cursorData = (CFDictionaryRef)cd;

	
	CFIndex bufferLength = CFStringGetMaximumSizeForEncoding(CFStringGetLength(key), kCFStringEncodingUTF8) + 1;
	
	char *CKey = (char*)malloc(bufferLength);
	CFStringGetCString(key, CKey, bufferLength, kCFStringEncodingUTF8);
	
	
	if (useDefault) {
		CFStringRef backupIdentifier = createBackupIdentifierForIdentifier(key);
		MMLog("Resetting cursor: %s\n", CKey);
		ReplaceCursorWithName(backupIdentifier, key);
		CFRelease(backupIdentifier);
		free(CKey);
		return;
	}
	
	/*! Get down to the cursor data in the dictionary structure. */
	// Get the key for our cursor data
	CFStringRef cursorKey             = (CFStringRef)CFDictionaryGetValue(currentCursorInfo, kCursorInfoCustomKey);
	// Dictionary that holds our cursor data
	CFDictionaryRef currentCursorData = (CFDictionaryRef)CFDictionaryGetValue(cursorData, cursorKey);
	
	// Get all of our required data to build an image representation
	CFDataRef imageData               = (CFDataRef)CFDictionaryGetValue(currentCursorData, kCursorDataDataKey);
	CFNumberRef nbpp                  = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataBitsPerPixelKey);
	CFNumberRef nbps                  = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataBitsPerSampleKey);
	CFNumberRef nbpr                  = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataBytesPerRowKey);       
	CFNumberRef nframeCount           = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataFrameCountKey);
	CFNumberRef nframeDuration        = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataFrameDurationKey);
	CFNumberRef nhotSpotX             = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataHotspotXKey);
	CFNumberRef nhotSpotY             = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataHotspotYKey);
	CFNumberRef nwidth                = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataPixelsWideKey);
	CFNumberRef nheight               = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataPixelsHighKey);
	CFNumberRef nspp                  = (CFNumberRef)CFDictionaryGetValue(currentCursorData, kCursorDataSamplesPerPixelKey);
	
	/*! Turn the CFNumbers into primitive types to use in the initialization of the image */
	int bpp, bps, bpr, frameCount, spp;
	CGFloat frameDuration, hotSpotX, hotSpotY, width, height;
	
	CFNumberGetValue(nbpp,           kCFNumberIntType, &bpp);
	CFNumberGetValue(nbps,           kCFNumberIntType, &bps);
	CFNumberGetValue(nbpr,           kCFNumberIntType, &bpr);
	CFNumberGetValue(nframeCount,    kCFNumberIntType, &frameCount);
	CFNumberGetValue(nframeDuration, kCFNumberCGFloatType, &frameDuration);
	CFNumberGetValue(nhotSpotX,      kCFNumberCGFloatType, &hotSpotX);
	CFNumberGetValue(nhotSpotY,      kCFNumberCGFloatType, &hotSpotY);
	CFNumberGetValue(nwidth,         kCFNumberCGFloatType, &width);
	CFNumberGetValue(nheight,        kCFNumberCGFloatType, &height);
	CFNumberGetValue(nspp,           kCFNumberIntType, &spp);
	
	// We need to backup the original cursor
	BackupCursor(key);
	
	// The dictionary does not hold the actual height of the image. Since the animations are the cursor height multiplied
	// by the frame count. We can assume that this is how high the image will be
	CGFloat animationHeight           = height*frameCount;
	
	// Create the image for replacing
	CGDataProviderRef dataProvider    = CGDataProviderCreateWithCFData(imageData);
	CGColorSpaceRef colorspace        = CGColorSpaceCreateDeviceRGB();
	CGImageRef cursorImage            = CGImageCreate(width, animationHeight, bps, bpp, bpr, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaFirst, dataProvider, NULL, false, kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorspace);
	CGDataProviderRelease(dataProvider);
	
	if (cursorImage == NULL) {
		MMLog("Invalid cursor image for %s. Skipping...\n", CKey);
		return;
	}
	
	// We need to turn it into an array for use in the CoreGraphics function to register the cursor
	void *arrayValues[1];
	arrayValues[0] = cursorImage;	
	CFArrayRef ar  = CFArrayCreate(NULL, (const void**)arrayValues, 1, NULL);	
	
	
	MMLog("Hooking cursor: %s\n", CKey);
	
	// This is a cursor seed returned when our function comes back. It doesn't really have much uses to us.
	int seed;
	// Perform our replacement of Apple's cursors
	CGError err    = CGSRegisterCursorWithImages(CGSMainConnectionID(), CKey, true, true, frameCount, ar, CGSizeMake(width, height), CGPointMake(hotSpotX, hotSpotY), &seed, CGRectMake(hotSpotX,hotSpotY,width,height), frameDuration, 0);
	
	if (err != kCGErrorSuccess) {
		MMLog("Error number %i while hooking cursor %s", err, CKey);
	}
	
	// Prevent some leaks
	CGImageRelease(cursorImage);
	CFRelease(ar);
	free(CKey);
}
/*! This method retrieves Apple's data and information about several cursors and saves
    then to the exportPath */
static CGError dumpCursors(CFStringRef exportPath) {
	if (exportPath == NULL) {
		MMLog("No export path?\n");
		return kCGErrorIllegalArgument;
	}
	
	// CFMutableDictionaryCreateEmpty() is a quick macro defined at the top of this file
	// to quickly create a mutable CFDictionary.
	CFMutableDictionaryRef mouseFile   = CFMutableDictionaryCreateEmpty();
	CFMutableDictionaryRef cursors     = CFMutableDictionaryCreateEmpty();
	CFMutableDictionaryRef global      = CFMutableDictionaryCreateEmpty();
	CFMutableDictionaryRef identifiers = CFMutableDictionaryCreateEmpty();
	CFMutableDictionaryRef cursorData  = CFMutableDictionaryCreateEmpty();	
	
	// Return error
	CGError err = kCGErrorSuccess;
	
	// There are 12 pre-defined cursors to dump.
	for (int x = 0; x<=11; x++) {
		// Get the cursor 
		CFStringRef strIdent = cursorIdentifierFromInt(x);
		CFIndex bufferLength = CFStringGetMaximumSizeForEncoding(CFStringGetLength(strIdent), kCFStringEncodingUTF8) + 1;
		
		char *ident = malloc(bufferLength);
		CFStringGetCString(strIdent, ident, bufferLength, kCFStringEncodingUTF8);
		
		MMLog("Dumping %s\n", ident);
				
		// 2 Dictionaries. 1 for the identifiers & info (table id, data key, etc.) and one for the
		// actual effective image data.
		CFMutableDictionaryRef currentIdentifier = CFMutableDictionaryCreateEmpty();
		CFMutableDictionaryRef currentCursorData = CFMutableDictionaryCreateEmpty();
		
		// Get the name of the current cursor.
		CFStringRef name    = nameFromInt(x);
		// Make a key for the cursor data based on the name of the cursor
		CFStringRef dataKey = CFStringCreateWithFormat(NULL, NULL, CFSTR("Global.%@"), name);

		/*! Set the values for the info dictionary */
		CFDictionarySetValue(currentIdentifier, kCursorInfoNameKey, name);
		CFDictionarySetValue(currentIdentifier, kCursorInfoTableIdentifierKey, tableIdentifierFromInt(x));
		CFDictionarySetValue(currentIdentifier, kCursorInfoDefaultKey, dataKey);
		CFDictionarySetValue(currentIdentifier, kCursorInfoCustomKey, dataKey);
		
		// Get some data to put in the cursor data dictionary
		int bpr, bpp, bps, spp; 
		float fd;
		size_t size;
		int fc;
		
		CGSGetRegisteredCursorDataSize(CGSMainConnectionID(), ident, &size);

		// Sometimes cursors with the name like "com.apple.cursor.5" are not
		// registered unless they have been used. Here we skip them if so.
		if (size <= 0) {
			MMLog("Cursor not registered: %s. Skipping...\n", ident);
			
			// Release currently allocated variables
			free(ident);
			CFRelease(dataKey);
			CFRelease(currentCursorData);
			CFRelease(currentIdentifier);
			continue;
		}
		
		// Create some space in ram for the cursor image data
		void *data = malloc(size);
		
		if (!data) {
			MMLog("Error allocating space for image data in memory.\n");
			
			CFRelease(dataKey);
			CFRelease(currentCursorData);
			CFRelease(currentIdentifier);
			return kCGErrorFailure;
		}
		
		CGSize cursorSize;
		CGSize imageSize;
		CGPoint hotSpot;

		// Finally retrieve the cursor data and its information
		err = CGSGetRegisteredCursorData2(CGSMainConnectionID(),  // Connection
										  (char*)ident,           // Identifier we want to retrieve
										  data,                   // Previously allocated data pointer to store the raw cursor image in
										  &size,                  // Maybe the previous size was wrong?
										  &bpr,                   // Bytes per row
										  &imageSize,             // Size of the image. (Including its full height for the animation)
										  &cursorSize,            // Size of the cursor displayed ons creen
										  &hotSpot,               // Point where cursor has effective clicks
										  &bpp,                   // Bits per pixel (usually 32)
										  &spp,                   // Samples per pixel (almost definitely 4)
										  &bps,                   // Bits per sample (should be at least 8)
										  &fc,                    // Frame count
										  &fd);                   // Frame duration
				
		if (err != kCGErrorSuccess) {
			MMLog("Cursor dump received error code: %i on cursor: %s\n", err, ident);
			
			// If an error occurred and the cursor was registered, then we probably
			// don't want to continue.
			free(data);
			CFRelease(dataKey);
			CFRelease(currentCursorData);
			CFRelease(currentIdentifier);
			return err;
		}
		
		
		/*! We need to convert whatever data we got above from little to big endian.
		    We know it is currently little endian because Lion requires intel processors.
			It needs to be Big Endian because that is what the Mighty Mouse format originally supported
		    because it was made first for PPC computers which are big endian. */
		
		vImage_Buffer buffer;
		buffer.data     = data;
		buffer.width    = imageSize.width;
		buffer.height   = imageSize.height;
		buffer.rowBytes = bpr;
	
		
		// The conversion from little to big endian (or vice versa) is a matter of flipping the values
		uint8_t permuteMap[4] = {3,2,1,0};
		vImagePermuteChannels_ARGB8888(&buffer, 
									   &buffer, 
									   permuteMap, 
									   0);
		
		// Create a data reference
		CFDataRef imageData = CFDataCreate(0, (const UInt8*)data, size);
		
		// Get some quick primitives for the cursor info
		int wide = (int)cursorSize.width;
		int high = (int)cursorSize.height;
		int hx   = (int)hotSpot.x;
		int hy   = (int)hotSpot.y;
		
		// Create CFNumber instances from the above primitives
		CFNumberRef nbpp  = CFNumberCreate(0, kCFNumberIntType, &bpp);
		CFNumberRef nbps  = CFNumberCreate(0, kCFNumberIntType, &bps);
		CFNumberRef nbpr  = CFNumberCreate(0, kCFNumberIntType, &bpr);
		CFNumberRef nph   = CFNumberCreate(0, kCFNumberIntType, &high);
		CFNumberRef npw   = CFNumberCreate(0, kCFNumberIntType, &wide);
		CFNumberRef nspp  = CFNumberCreate(0, kCFNumberIntType, &spp);
		CFNumberRef nfd   = CFNumberCreate(0, kCFNumberFloatType, &fd);
		CFNumberRef nfc   = CFNumberCreate(0, kCFNumberIntType, &fc);
		CFNumberRef nhx   = CFNumberCreate(0, kCFNumberIntType, &hx);
		CFNumberRef nhy   = CFNumberCreate(0, kCFNumberIntType, &hy);
		
		/*! Finally, set the values in the cursor data dictionary to required cursor data which we previously retrieved */
		CFDictionarySetValue(currentCursorData, kCursorDataBitsPerPixelKey, nbpp);
		CFDictionarySetValue(currentCursorData, kCursorDataBitsPerSampleKey, nbps);
		CFDictionarySetValue(currentCursorData, kCursorDataBytesPerRowKey, nbpr);
		CFDictionarySetValue(currentCursorData, kCursorDataPixelsHighKey, nph);
		CFDictionarySetValue(currentCursorData, kCursorDataPixelsWideKey, npw);
		CFDictionarySetValue(currentCursorData, kCursorDataSamplesPerPixelKey, nspp);
		CFDictionarySetValue(currentCursorData, kCursorDataFrameDurationKey, nfd);
		CFDictionarySetValue(currentCursorData, kCursorDataFrameCountKey, nfc);
		CFDictionarySetValue(currentCursorData, kCursorDataHotspotXKey, nhx);
		CFDictionarySetValue(currentCursorData, kCursorDataHotspotYKey, nhy);
		CFDictionarySetValue(currentCursorData, kCursorDataDataKey, imageData);
		
		// Set the values into the big dictionaries.
		CFDictionarySetValue(cursorData, dataKey, currentCursorData);
		CFDictionarySetValue(identifiers, strIdent, currentIdentifier);
		
		// Prevent leakage
		free(data);
		free(ident);
		
		CFRelease(dataKey);
		CFRelease(imageData);
		CFRelease(nbpp);
		CFRelease(nbps);
		CFRelease(nbpr);
		CFRelease(nph);
		CFRelease(npw);
		CFRelease(nspp);
		CFRelease(nfd);
		CFRelease(nfc);
		CFRelease(nhx);
		CFRelease(nhy);
		
		CFRelease(currentCursorData);
		CFRelease(currentIdentifier);
	}
	
	// Put the cursor identifiers into its parent dictionary
	CFDictionarySetValue(global, kCursorInfoIdentifiersKey, identifiers);
	// and put the 2 parent dictionaries into the cursors dictionary
	CFDictionarySetValue(cursors, kCursorInfoKey, global);
	CFDictionarySetValue(cursors, kCursorDataKey, cursorData);
	
	// Version (1.02) to use for the minimum compatible Mighty Mouse version for this cursor dump
	CFStringRef version = kMMVersion;
	
	// Finally, put the cursors dictionary and version numbers into the root dictionary
	CFDictionarySetValue(mouseFile, kMinimumVersionKey, version);
	CFDictionarySetValue(mouseFile, kCreatorVersionKey, version);
	CFDictionarySetValue(mouseFile, kCursorsKey, cursors);
	
	CFErrorRef error = NULL;
	// Get XML data for our dictionaries
	CFDataRef plistData = CFPropertyListCreateData(kCFAllocatorDefault,
												   (CFPropertyListRef)mouseFile,
												   kCFPropertyListXMLFormat_v1_0, // xml, not binary
												   0,
												   &error);
	if (error != NULL) {
		MMLog("Error writing to path.\n");
		CFShow(error);
		
		// Errors follow the create rule
		CFRelease(error);
		
		// General failure
		err = kCGErrorFailure;
	}
	
	// Convert the path to a URL
	CFURLRef path = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, exportPath, kCFURLPOSIXPathStyle, false);
	// Write the XML data to a file
	CFURLWriteDataAndPropertiesToResource(path, plistData, 0, 0);
	
	// Prevent leakage
	CFRelease(path);
	CFRelease(cursorData);
	CFRelease(identifiers);
	CFRelease(global);
	CFRelease(cursors);
	CFRelease(mouseFile);
	
	if (plistData) // Perhaps the plistData initialization failed and we received an error...
		CFRelease(plistData);
	
	MMLog("---\nFin.\n");
	
	return err;
}
static void showUsage(void) {
	MMLog("Usage:\n\tmagicmouse cursor.plist\n\tmagicmouse -r cursorReset.plist\n\tmagicmouse -d dump.plist\n\tmagicmouse -s scaleFactor\n\tmagicmouse -p\n");
}
int main (int argc, const char * argv[]) {
	bool help;
	bool dump;
	bool scale;
	bool usePrefs;
	int c;
	
	// Check for what operation we'll be performing
	while ((c = getopt (argc, (char *const*)argv, "hhelpr:d:sp")) != -1) {
		switch (c) {
			case 'r':
				useDefault = true;
				break;
			case 'help':
			case 'h':
				help = true;
				break;
			case 'd':
				dump = true;
				break;
			case 's':
				scale = true;
				break;
			case 'p':
				usePrefs = true;
				break;
			default:
				break;
		}
	}
	
	if (argc < 2 || (dump && useDefault)) {
		MMLog("Invalid arguments.\n");
		showUsage();
		return kCGErrorIllegalArgument;
	}

	if (help) {
		showUsage();
		return 0;
	}
	
	if (scale) {
		if (argc == 2) { // If there are no arguments after '-s'. The user is retreiving the scale rather than setting it.
			float scale;
			CGSGetCursorScale(CGSMainConnectionID(), &scale);
			MMLog("%f\n", scale);
			return kCGErrorSuccess;
		}
		
		// Otherwise set the scale
		const char *cf = argv[argc-1];
		float factor = (float)atof(cf);
		MMLog("Scaling cursor to %.0f%%\n", factor*100);
		return (CGSSetCursorScale(CGSMainConnectionID(), factor) == kCGErrorSuccess);
	}
	
	MMLog("Magic Mouse Initialized.\n---\n");
	const char *plistLocation = argv[argc-1];
	
	
	CFStringRef path = CFStringCreateWithCString(kCFAllocatorDefault, plistLocation, kCFStringEncodingUTF8);
	
	if (dump) {
		CGError err = dumpCursors(path);
		CFRelease(path);
		return err;
	}
	
	/*! Here begins code that hooks the cursors if none of the above options were specified. */
	if (usePrefs) {
		// Read the prefs to find out the location of the plist
		CFDataRef prefsData;
		CFURLRef prefsURL = CFURLCreateWithFileSystemPath(0, kMMPrefsLocation, kCFURLPOSIXPathStyle, false);
		CFURLCreateDataAndPropertiesFromResource(0, 
												 prefsURL,
												 &prefsData,
												 NULL,
												 NULL,
												 NULL);
		if (!prefsData) {
			MMLog("Could not load preference file for Magic Mouse.\n");
			return kCGErrorFailure;
		}
		
		CFDictionaryRef prefsDict = (CFDictionaryRef)CFPropertyListCreateWithData(0,
																				  prefsData, 
																				  kCFPropertyListImmutable, 
																				  NULL,
																				  NULL);
		CFRelease(prefsData);
		
		// get the location of the cursor plist
		CFStringRef location = CFDictionaryGetValue(prefsDict, kMMPrefsThemeLocationKey);
		plistLocation = CFStringGetCStringPtr(location, kCFStringEncodingUTF8);
		CFRelease(location);
		
		// scale the cursor
		CFNumberRef scaleNumber = CFDictionaryGetValue(prefsDict, kMMPrefsCursorScaleKey);
		float scaleFactor;
		CFNumberGetValue(scaleNumber, kCFNumberFloatType, &scaleFactor);
		
		CGSSetCursorScale(CGSMainConnectionID(), scaleFactor);
	}
	
	CFURLRef cursorPlist = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, false);
	CFRelease(path);
	
	if (!path||!cursorPlist) {
		MMLog("Invalid or unspecified path to plist.\n");
		showUsage();
		return kCGErrorIllegalArgument;
	}
	
	CFDataRef cursorPlistData = NULL;
	bool success = CFURLCreateDataAndPropertiesFromResource(NULL, cursorPlist, &cursorPlistData, NULL, NULL, NULL);
	CFRelease(cursorPlist);
	
	if (success == false) {
		MMLog("Invalid cursor plist. (e1)\n");
		return kCGErrorFailure;
	}
	
	CFDictionaryRef rootDict = (CFDictionaryRef)CFPropertyListCreateWithData(NULL, cursorPlistData, kCFPropertyListImmutable, NULL, NULL);
	CFRelease(cursorPlistData);
	
	if (!rootDict) {
		MMLog("Invalid cursor plist. (e2)\n");
		return kCGErrorIllegalArgument;
	}
	
	CFDictionaryRef cursorDictionary = CFDictionaryCreateCopy(NULL, (CFDictionaryRef)CFDictionaryGetValue(rootDict, kCursorsKey));
	CFRelease(rootDict);
	
	CFDictionaryRef cursorData        = (CFDictionaryRef)CFDictionaryGetValue(cursorDictionary, kCursorDataKey);
	CFDictionaryRef cursorInfo        = (CFDictionaryRef)CFDictionaryGetValue(cursorDictionary, kCursorInfoKey);
	CFDictionaryRef cursorIdentifiers = (CFDictionaryRef)CFDictionaryGetValue(cursorInfo, kCursorInfoIdentifiersKey);
	// Loop through the identifiers dictionary for cursors to hook
	CFDictionaryApplyFunction(cursorIdentifiers, HookCursor, (void*)cursorData);
	CFRelease(cursorDictionary);
	
	MMLog("---\nFin.\n");

	return kCGErrorSuccess;
}

