//
//  main.c
//  magicmouse
//
//  Created by Alex Zielenski on 2/20/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <ApplicationServices/ApplicationServices.h>
#include <Accelerate/Accelerate.h>
#include "MMDefs.h"

#include "CGSCursor.h"
#include "CGSAccessibility.h"

#define CFMutableDictionaryCreateEmpty() CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)

CFStringRef tableIdentifierFromInt(int x);
CFStringRef nameFromInt(int x);
const char *cursorIdentifierFromInt(int x);
void CGImageWriteToFile(CGImageRef image, CFStringRef path);

void CGImageWriteToFile(CGImageRef image, CFStringRef path) {
	CFURLRef url = CFURLCreateWithFileSystemPath(NULL, path , kCFURLPOSIXPathStyle, false);
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
	CFRelease(url);
	
    CGImageDestinationAddImage(destination, image, nil);
	
    bool success = CGImageDestinationFinalize(destination);
    if (!success) {
        MMLog("Failed to write image.");
    }
	
    CFRelease(destination);
}

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
		default:
			break;
	}
	return rtn;
}
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
			rtn = CFSTR("Global.Identifiers.Alias");
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
		default:
			break;
	}
	return rtn;
}
const char *cursorIdentifierFromInt(int x) {
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
	// com.apple.cursor.3              = Unavailable
	// com.apple.cursor.5              = Large Copy
	
	const char *rtn = NULL;
	switch (x) {
		case 0:
			rtn = "com.apple.coregraphics.Arrow";
			break;
		case 1:
			rtn = "com.apple.coregraphics.IBeam";
			break;
		case 2:
			rtn = "com.apple.coregraphics.IBeamXOR";
			break;
		case 3:
			rtn = "com.apple.coregraphics.Alias";
			break;
		case 4:
			rtn = "com.apple.coregraphics.Copy";
			break;
		case 5:
			rtn = "com.apple.coregraphics.Move";
			break;
		case 6:
			rtn = "com.apple.coregraphics.ArrowCtx";
			break;
		case 7:
			rtn = "com.apple.coregraphics.Wait";
			break;
		case 8:
			rtn = "com.apple.coregraphics.Empty";
			break;
		case 9:
			rtn = "com.apple.cursor.2";
			break;
		case 10:
			rtn = "com.apple.cursor.3";
			break;
		case 11:
			rtn = "com.apple.cursor.5";
			break;
		default:
			break;
	}
	return rtn;
}

static bool useDefault = false;
static void HookCursor(const void* k, const void* cci, void* cd) {
	CFStringRef key = (CFStringRef)k;	
	CFDictionaryRef currentCursorInfo = (CFDictionaryRef)cci;
	CFDictionaryRef cursorData = (CFDictionaryRef)cd;
	
	char *CKey = (char*)malloc(PATH_MAX);
	CFStringGetCString(key, CKey, PATH_MAX, kCFStringEncodingUTF8);
	
	CFStringRef cursorKey             = (CFStringRef)CFDictionaryGetValue(currentCursorInfo, (useDefault) ? kCursorInfoDefaultKey : kCursorInfoCustomKey);
	CFDictionaryRef currentCursorData = (CFDictionaryRef)CFDictionaryGetValue(cursorData, cursorKey);
	
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
	
	
	CGFloat animationHeight = height*frameCount;
	CGDataProviderRef dataProvider    = CGDataProviderCreateWithCFData(imageData);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGImageRef cursorImage = CGImageCreate(width, animationHeight, bps, bpp, bpr, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaFirst, dataProvider, NULL, false, kCGRenderingIntentDefault);
	CGColorSpaceRelease(colorspace);
	CGDataProviderRelease(dataProvider);
	
	if (cursorImage==NULL) {
		MMLog("Invalid cursor image for %s. Skipping...\n", CKey);
		return;
	}
	
	void *arrayValues[1];
	arrayValues[0] = cursorImage;	
	CFArrayRef ar = CFArrayCreate(NULL, (const void**)arrayValues, 1, NULL);	
	
	MMLog("Hooking cursor: %s\n", CKey);
	
	int seed;
	CGSRegisterCursorWithImages(CGSMainConnectionID(), CKey, true, true, frameCount, ar, CGSizeMake(width, height), CGPointMake(hotSpotX, hotSpotY), &seed, CGRectMake(hotSpotX,hotSpotY,width,height), frameDuration, 0);
	
	free(CKey);
	CGImageRelease(cursorImage);
	CFRelease(ar);
}
static CGError dumpCursors(CFStringRef exportPath) {
	CFMutableDictionaryRef mouseFile   = CFMutableDictionaryCreateEmpty();
	CFMutableDictionaryRef cursors     = CFMutableDictionaryCreateEmpty();
	CFMutableDictionaryRef global      = CFMutableDictionaryCreateEmpty();
	CFMutableDictionaryRef identifiers = CFMutableDictionaryCreateEmpty();
	CFMutableDictionaryRef cursorData  = CFMutableDictionaryCreateEmpty();	
	
	CGError err = kCGErrorSuccess;
	
	for (int x = 0; x<=11; x++) {
		const char *ident = cursorIdentifierFromInt(x);
		MMLog("Dumping %s\n", ident);
		
		CFStringRef strIdent = CFStringCreateWithCStringNoCopy(NULL, 
															   ident, 
															   kCFStringEncodingUTF8,
															   kCFAllocatorNull);
				
		CFMutableDictionaryRef currentIdentifier = CFMutableDictionaryCreateEmpty();
		CFMutableDictionaryRef currentCursorData = CFMutableDictionaryCreateEmpty();
		
		CFStringRef name    = nameFromInt(x);
		CFStringRef dataKey = CFStringCreateWithFormat(NULL, NULL, CFSTR("Global.%@"), name);

		// Info dictionary
		CFDictionarySetValue(currentIdentifier, kCursorInfoNameKey, name);
		CFDictionarySetValue(currentIdentifier, kCursorInfoTableIdentifierKey, tableIdentifierFromInt(x));
		CFDictionarySetValue(currentIdentifier, kCursorInfoDefaultKey, dataKey);
		CFDictionarySetValue(currentIdentifier, kCursorInfoCustomKey, dataKey);
		
		// Actual data
		int fc, bpr, bpp, bps, spp; 
		float fd;
		size_t size;
		
		CGSGetRegisteredCursorDataSize(CGSMainConnectionID(), (char*)ident, &size);
		
		if (size <= 0) { // cursor not registered
			MMLog("Cursor not registered: %s. Skipping...\n", ident);
			CFRelease(strIdent);
			CFRelease(dataKey);
			CFRelease(currentCursorData);
			CFRelease(currentIdentifier);
			continue;
		}
		
		void *data = malloc(size);
		CGSize cursorSize;
		CGSize imageSize;
		CGPoint hotSpot;

		err = CGSGetRegisteredCursorData2(CGSMainConnectionID(), 
										  (char*)ident, 
										  data, 
										  &size, 
										  &bpr, 
										  &imageSize, 
										  &cursorSize, 
										  &hotSpot, 
										  &bpp, 
										  &spp, 
										  &bps, 
										  &fc, 
										  &fd);
		
		if (err != kCGErrorSuccess) {
			MMLog("Cursor dump received error code: %i on cursor: %s\n", err, ident);
			return err;
		}
		
		
		// little to big endian
		vImage_Buffer buffer;
		buffer.data = data;
		buffer.width = imageSize.width;
		buffer.height = imageSize.height;
		buffer.rowBytes = bpr;
		
		uint8_t permuteMap[4] = {3,2,1,0};
		vImagePermuteChannels_ARGB8888(&buffer, 
									   &buffer, 
									   permuteMap, 
									   0);
		
		CFDataRef imageData = CFDataCreate(0, (const UInt8*)data, size);
				
		int wide = (int)cursorSize.width;
		int high = (int)cursorSize.height;
		int hx   = (int)hotSpot.x;
		int hy   = (int)hotSpot.y;
		
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
		
		// set the values into the big dictionaries		
		CFDictionarySetValue(cursorData, dataKey, currentCursorData);
		CFDictionarySetValue(identifiers, strIdent, currentIdentifier);
		
		free(data);
		
		CFRelease(dataKey);
		CFRelease(strIdent);
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
	CFDictionarySetValue(global, kCursorInfoIdentifiersKey, identifiers);
	CFDictionarySetValue(cursors, kCursorInfoKey, global);
	CFDictionarySetValue(cursors, kCursorDataKey, cursorData);
	
	CFStringRef version = CFSTR("3.0");
	
	CFDictionarySetValue(mouseFile, kMinimumVersionKey, version);
	CFDictionarySetValue(mouseFile, kCreatorVersionKey, version);
	CFDictionarySetValue(mouseFile, kCursorsKey, cursors);
	
	if (exportPath != NULL) {
		CFURLRef path = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, exportPath, kCFURLPOSIXPathStyle, false);
		CFErrorRef err = NULL;
		CFDataRef plistData = CFPropertyListCreateData(kCFAllocatorDefault,
													   (CFPropertyListRef)mouseFile,
													   kCFPropertyListXMLFormat_v1_0,
													   0,
													   &err);
		if (err != NULL) {
			MMLog("Error writing to path.\n");
			CFShow(err);
			CFRelease(err);
		}

		CFURLWriteDataAndPropertiesToResource(path, plistData, 0, 0);
		CFRelease(path);
	}
	
	CFRelease(cursorData);
	CFRelease(identifiers);
	CFRelease(global);
	CFRelease(cursors);
	CFRelease(mouseFile);
	
	return kCGErrorSuccess;
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
		if (argc == 2) {
			float scale;
			CGSGetCursorScale(CGSMainConnectionID(), &scale);
			MMLog("%f\n", scale);
			return kCGErrorSuccess;
		}
		
		const char *cf = argv[argc-1];
		float factor = (float)atof(cf);
		MMLog("Scaling cursor to %.0f%%\n", factor*100);
		return (CGSSetCursorScale(CGSMainConnectionID(), factor) == kCGErrorSuccess);
	}
	
	MMLog("Magic Mouse Initialized.\n---\n");
	const char *plistLocation = argv[argc-1];
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
	
	CFStringRef path = CFStringCreateWithCString(NULL, plistLocation, kCFStringEncodingUTF8);
	CFURLRef cursorPlist = CFURLCreateWithFileSystemPath(NULL, path, kCFURLPOSIXPathStyle, false);
	CFRelease(path);
	
	if (!path||!cursorPlist) {
		MMLog("Invalid or unspecified path to plist.\n");
		showUsage();
		return kCGErrorIllegalArgument;
	}
	
	if (dump) {
		CGError err = dumpCursors(path);
		CFRelease(cursorPlist);
		return err;
	}
	
	CFDataRef cursorPlistData = NULL;
	bool success = CFURLCreateDataAndPropertiesFromResource(NULL, cursorPlist, &cursorPlistData, NULL, NULL, NULL);
	CFRelease(cursorPlist);
	
	if (success == false) {
		MMLog("Invalid cursor plist.\n");
		return kCGErrorFailure;
	}
	
	CFDictionaryRef rootDict = (CFDictionaryRef)CFPropertyListCreateWithData(NULL, cursorPlistData, kCFPropertyListImmutable, NULL, NULL);
	CFRelease(cursorPlistData);
	
	if (!rootDict) {
		MMLog("Invalid cursor plist\n");
		return kCGErrorIllegalArgument;
	}
	
	CFDictionaryRef cursorDictionary = CFDictionaryCreateCopy(NULL, (CFDictionaryRef)CFDictionaryGetValue(rootDict, kCursorsKey));
	CFRelease(rootDict);
	
	CFDictionaryRef cursorData        = (CFDictionaryRef)CFDictionaryGetValue(cursorDictionary, kCursorDataKey);
	CFDictionaryRef cursorInfo        = (CFDictionaryRef)CFDictionaryGetValue(cursorDictionary, kCursorInfoKey);
	CFDictionaryRef cursorIdentifiers = (CFDictionaryRef)CFDictionaryGetValue(cursorInfo, kCursorInfoIdentifiersKey);
	CFDictionaryApplyFunction(cursorIdentifiers, HookCursor, (void*)cursorData);
	CFRelease(cursorDictionary);
	
	MMLog("---\nFin.\n");

	return kCGErrorSuccess;
}

