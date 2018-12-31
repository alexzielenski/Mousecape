/*
 * Copyright (C) 2007-2008 Alacatia Labs. (C) 2011-2012 Alex Zielenski
 * 
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 * 
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 * 
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 * 
 * Joe Ranieri    joe@alacatia.com
 * Alex Zielenski alex@alexzielenski.com
 *
 */

#pragma once
#include "CGSConnection.h"
#import <ApplicationServices/ApplicationServices.h>

typedef int CGSCursorID;

#pragma mark - HIServices

CG_EXTERN CGError CoreCursorUnregisterAll(CGSConnectionID cid);
CG_EXTERN CGError CoreCursorSet(CGSConnectionID cid, CGSCursorID cursorID);
CG_EXTERN CGError CoreCursorSetAndReturnSeed(CGSConnectionID cid, CGSCursorID cursorNum, int *seed);
CG_EXTERN CGError CoreCursorCopyImages(CGSConnectionID cid, CGSCursorID cursorID, CFArrayRef *images, CGSize *imageSize, CGPoint *hotSpot, NSUInteger *frameCount, CGFloat *frameDuration);

#pragma mark - Cursor APIs reversed by Alex Zielenski on Lion 10.7.3
#pragma mark -

//CG_EXTERN CGError CGSIsCursorRegistered(CGSConnectionID cid, char *cursorName, bool *registered) __attribute__((weak_import));

#if defined(MAC_OS_X_VERSION_10_8)
CG_EXTERN CGError CGSCopyRegisteredCursorImages(CGSConnectionID cid, char *cursorName, CGSize *imageSize, CGPoint *hotSpot, NSUInteger *frameCount, CGFloat *frameDuration, CFArrayRef *imageArray);
#endif

CG_EXTERN CGError CGSGetRegisteredCursorImages(CGSConnectionID cid, char *cursorName, CGSize *imageSize, CGPoint *hotSpot, NSUInteger *frameCount, CGFloat *frameDuration, CFArrayRef *imageArray);


// Verified, stable
/*! Registers a cursor in the current CGSConnection or globally */
CG_EXTERN CGError CGSRegisterCursorWithImages(CGSConnectionID cid, char *cursorName, bool setGlobally, bool instantly, NSUInteger frameCount, CFArrayRef imageArray, CGSize cursorSize, CGPoint hotspot, int *seed, CGRect bounds, CGFloat frameDuration, NSInteger repeatCount);

CG_EXTERN CGError CGSSetSystemDefinedCursor(CGSConnectionID cid, CGSCursorID cursor);

/*! Sets the current cursor to a system defined cursor and returns the seed */
CG_EXTERN void CGSSetSystemDefinedCursorWithSeed(CGSConnectionID connection, CGSCursorID systemCursor, int *cursorSeed);

/*! Flag indicating whether or not the dock can change/override the cursor */
CG_EXTERN void CGSSetDockCursorOverride(CGSConnectionID cid, bool flag);

/*! Gets size in bytes of the raw ARGB data for the indicated cursor */
CG_EXTERN CGError CGSGetRegisteredCursorDataSize(CGSConnectionID cid, char *cursorName, size_t *size);

/*! Creates and returns a CGImage representation and the hotspot of a cursor for a name. Ownership follows the Create Rule */
CG_EXTERN CGImageRef CGSCreateRegisteredCursorImage(CGSConnectionID cid, char *cursorName, CGPoint *hotSpot);

/*! Sets the current cursor to a cursorname. Returns the seed of the current cursor. */
CG_EXTERN CGError CGSSetRegisteredCursor(CGSConnectionID cid, char *cursorName, int *seed);

/*! Retrieves registered ARGB cursor data and some other important info for it */
CG_EXTERN CGError CGSGetRegisteredCursorData2(CGSConnectionID cid, char *cursorName, void *data, size_t *dataSize, int *bytesPerRow, CGSize *imageSize, CGSize *cursorSize, CGPoint *hotSpot, int *bitsPerPixel, int *samplesPerPixel, int *bitsPerSample, int *frameCount, float *frameDuration);

// Not fully reversed/researched. Should not be used
CG_EXTERN CGError CGSRemoveRegisteredCursor(CGSConnectionID cid, char *cursorName, bool unknownFlag);
CG_EXTERN CGError CGSGetRegisteredCursorData(CGSConnectionID cid, char *cursorName, void *data, int *dataSize, CGSize *cursorSize, CGPoint *hotSpot, int *depth, int *bitsPerPixel, int *samplesPerPixel, int *bitsPerSample, int *unknown);
CG_EXTERN CGError CGSRegisterCursorWithImage(CGSConnectionID, char *, bool, bool, int, CGImageRef, CGSize, CGPoint, int *, CGFloat, CGFloat);
CG_EXTERN CGError CGSRegisterCursorWithData(CGSConnectionID cid, char *cursorName, char, bool, bool, CGSize, CGRect, CGPoint, int, int, int, int, int, int, int, int, int, int, int);

#pragma mark - Original cursor APIs found by Joe Ranieri in 2008 probably under Leopard (10.5)
#pragma mark -
/*! Does the system support hardware cursors? */
CG_EXTERN CGError CGSSystemSupportsHardwareCursor(CGSConnectionID cid, bool *outSupportsHardwareCursor);

/*! Does the system support hardware color cursors? */
CG_EXTERN CGError CGSSystemSupportsColorHardwareCursor(CGSConnectionID cid, bool *outSupportsHardwareCursor);

/*! Shows the cursor. */
CG_EXTERN CGError CGSShowCursor(CGSConnectionID cid);

/*! Hides the cursor. */
CG_EXTERN CGError CGSHideCursor(CGSConnectionID cid);

/*! Hides the cursor until the mouse is moved. */
CG_EXTERN CGError CGSObscureCursor(CGSConnectionID cid);

/*! Gets the cursor location. */
CG_EXTERN CGError CGSGetCurrentCursorLocation(CGSConnectionID cid, CGPoint *outPos);

/*! Gets the name (in reverse DNS form) of a system cursor. */
CG_EXTERN char *CGSCursorNameForSystemCursor(CGSCursorID cursor);

/*! Gets the size of the data for the connection's cursor. */
CG_EXTERN CGError CGSGetCursorDataSize(CGSConnectionID cid, int *outDataSize);

/*! Gets the data for the connection's cursor. */
CG_EXTERN CGError CGSGetCursorData(CGSConnectionID cid, void *outData);

/*! Gets the size of the data for the current cursor. */
CG_EXTERN CGError CGSGetGlobalCursorDataSize(CGSConnectionID cid, int *outDataSize);

/*! Gets the data for the current cursor. */
CG_EXTERN CGError CGSGetGlobalCursorData(CGSConnectionID cid, void *outData, int *outDataSize, CGSize *outSize, CGPoint *outHotSpot, int *outDepth, int *outComponents, int *outBitsPerComponent, int *m);

/*! Gets the size of data for a system-defined cursor. */
CG_EXTERN CGError CGSGetSystemDefinedCursorDataSize(CGSConnectionID cid, CGSCursorID cursor, int *outDataSize);

/*! Gets the data for a system-defined cursor. */
CG_EXTERN CGError CGSGetSystemDefinedCursorData(CGSConnectionID cid, CGSCursorID cursor, void *outData, int *outRowBytes, CGRect *outRect, CGRect *outHotSpot, int *outDepth, int *outComponents, int *outBitsPerComponent, int *mystery);

/*! Gets the cursor 'seed'. Every time the cursor is updated, the seed changes. */
CG_EXTERN int CGSCurrentCursorSeed(void);

/*! Shows or hides the spinning beachball of death. */
CG_EXTERN CGError CGSForceWaitCursorActive(CGSConnectionID cid, bool showWaitCursor);
