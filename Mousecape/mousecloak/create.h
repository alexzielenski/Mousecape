//
//  create.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#ifndef Mousecape_create_h
#define Mousecape_create_h
extern NSError *createCape(NSString *input, NSString *output, BOOL convert);

extern NSDictionary *processedCapeWithIdentifier(NSString *identifier);
extern void dumpCursorsToFile(NSString *path);

extern NSDictionary *createCapeFromDirectory(NSString *path);
extern NSDictionary *createCapeFromMightyMouse(NSDictionary *mightyMouse);

#endif
