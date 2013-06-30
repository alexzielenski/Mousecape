//
//  MCScaledImageView.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MCScaledImageView : NSView <NSDraggingDestination>
@property (strong) NSImage *image;
@property (assign) CGFloat scale;
@property (assign) BOOL shouldDrawBezel;
@property (assign) BOOL shouldChooseHotSpot;
@property (assign) BOOL shouldDragToRemove;
@property (assign) NSSize sampleSize;
@property (assign) NSPoint hotSpot;
@property (assign) IBOutlet id <NSDraggingDestination> delegate;
@end

@interface MCScaledImageView (Properties)
@property (readonly, weak) NSBitmapImageRep *lastRepresentation;
@end