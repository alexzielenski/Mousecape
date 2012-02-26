#ifndef MMDefs

#define MMDefs
#include <stdio.h>

#define MMLog(format, ...) fprintf(stdout, format, ## __VA_ARGS__)
#define kMMPrefsLocation CFSTR("/Library/Preferences/com.alexzielenski.magicmouse.plist")
#define kMMPrefsAppID    CFSTR("com.alexzielenski.magicmouse")

#define kMMVersion       CFSTR("1.02")

#define kMMPrefsThemeLocationKey        CFSTR("CursorLocation")
#define kMMPrefsCursorScaleKey          CFSTR("CursorScale")

#define kMinimumVersionKey              CFSTR("MinimumVersion")
#define kCreatorVersionKey              CFSTR("Version")

#define kCursorsKey                     CFSTR("Cursors")
#define kCursorInfoKey                  CFSTR("Global")
#define kCursorDataKey                  CFSTR("Cursor Data")

#define kCursorInfoIdentifiersKey       CFSTR("Identifiers")
#define kCursorInfoDefaultKey           CFSTR("Default Key")
#define kCursorInfoCustomKey            CFSTR("Custom Key")
#define kCursorInfoNameKey              CFSTR("Name")
#define kCursorInfoTableIdentifierKey   CFSTR("Table Identifier")

#define kCursorDataBitsPerPixelKey      CFSTR("BitsPerPixel")
#define kCursorDataBitsPerSampleKey     CFSTR("BitsPerSample")
#define kCursorDataBytesPerRowKey       CFSTR("BytesPerRow")
#define kCursorDataDataKey              CFSTR("CursorData")
#define kCursorDataFrameCountKey        CFSTR("FrameCount")
#define kCursorDataFrameDurationKey     CFSTR("FrameDuration")
#define kCursorDataHotspotXKey          CFSTR("HotspotX")
#define kCursorDataHotspotYKey          CFSTR("HotspotY")
#define kCursorDataPixelsWideKey        CFSTR("PixelsWide")
#define kCursorDataPixelsHighKey        CFSTR("PixelsHigh")
#define kCursorDataSamplesPerPixelKey   CFSTR("SamplesPerPixel")

#endif