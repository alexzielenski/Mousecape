//
//  MCDefs.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/11/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#ifndef Mousecape_MCDefs_h
#define Mousecape_MCDefs_h
#include <stdio.h>

#define MMLog(format, ...) fprintf(stdout, format, ## __VA_ARGS__)

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

#endif
