//
//  MCDefs.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/11/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#ifndef Mousecape_MCDefs_h
#define Mousecape_MCDefs_h

#define MMOut(format, ...) fprintf(stdout, format, ## __VA_ARGS__)
#define MMLog(format, ...) MMOut(format "\n", ## __VA_ARGS__)

#import "CGSCursor.h"
#import "CGSAccessibility.h"

#define RESET   "\033[0m"
#define BLACK   "\033[30m"      /* Black */
#define RED     "\033[31m"      /* Red */
#define GREEN   "\033[32m"      /* Green */
#define YELLOW  "\033[33m"      /* Yellow */
#define BLUE    "\033[34m"      /* Blue */
#define MAGENTA "\033[35m"      /* Magenta */
#define CYAN    "\033[36m"      /* Cyan */
#define WHITE   "\033[37m"      /* White */
#define BOLD    "\033[1m"

extern NSString *defaultCursors[];
extern NSString *MCErrorDomain;
extern NSDictionary *cursorNameMap;

typedef NS_ENUM(NSInteger, MCErrorCode) {
    MCErrorInvalidCapeCode = -1,
    MCErrorWriteFailCode   = -2,
    
    MCErrorInvalidFormatCode = -100,
    MCErrorMultipleCursorIdentifiersCode = -101
};

extern const CGFloat   MCCursorCreatorVersion;
extern const CGFloat   MCCursorParserVersion;
extern const NSString *MCCursorDictionaryMinimumVersionKey;
extern const NSString *MCCursorDictionaryVersionKey;
extern const NSString *MCCursorDictionaryCursorsKey;
extern const NSString *MCCursorDictionaryAuthorKey;
extern const NSString *MCCursorDictionaryCloudKey;
extern const NSString *MCCursorDictionaryHiDPIKey;
extern const NSString *MCCursorDictionaryIdentifierKey;
extern const NSString *MCCursorDictionaryCapeNameKey;
extern const NSString *MCCursorDictionaryCapeVersionKey;

// Required cursors for cape format 2.0
extern const NSString *MCCursorDictionaryFrameCountKey;
extern const NSString *MCCursorDictionaryFrameDuratiomKey;
//extern const NSString *MCCursorDictionaryRepeatCountKey;
extern const NSString *MCCursorDictionaryHotSpotXKey;
extern const NSString *MCCursorDictionaryHotSpotYKey;
extern const NSString *MCCursorDictionaryPointsWideKey;
extern const NSString *MCCursorDictionaryPointsHighKey;
extern const NSString *MCCursorDictionaryRepresentationsKey;

extern NSDictionary *cursorMap();
extern NSString *nameForCursorIdentifier(NSString *identifier);
extern NSString *cursorIdentifierForName(NSString *name);

extern NSString *UUID(void);
extern NSDictionary *capeWithIdentifier(NSString *identifier);
extern void CGImageWriteToFile(CGImageRef image, CFStringRef path);
extern NSData *pngDataForImage(id image);
extern NSString *MMGet();

extern CGError MCIsCursorRegistered(CGSConnectionID cid, char *cursorName, bool *registered);
extern BOOL MCCursorIsPointer(NSString *identifier);
#endif
