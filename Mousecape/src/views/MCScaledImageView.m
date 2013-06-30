//
//  MCScaledImageView.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/19/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "MCScaledImageView.h"
#import "NSImage+BestRep.h"

NSWindow *MCWindowAtPoint(NSPoint screenPoint) {
    for (NSWindow *window in [NSApp windows]) {
        if ([window isVisible] && NSPointInRect(screenPoint, window.frame)) return window;
    }
    
    return nil;
}

@interface MCScaledImageView ()
@property (readwrite, weak) NSBitmapImageRep *lastRepresentation;
@property (assign) NSRect lastFrame;
@property (assign) CGFloat lastScaleFactor;
- (void)_commonInit;
@end

@implementation MCScaledImageView
- (id)init {
    if ((self = [super init])) {
        [self _commonInit];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)dec {
    if ((self = [super initWithCoder:dec])) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    self.scale = 1.0;
    self.shouldChooseHotSpot = YES;
    self.shouldDrawBezel = YES;
    self.shouldDragToRemove = YES;

    @weakify(self);
    RACDisposable *disp = [[RACSignal merge:@[
                                              RACAble(self.scale),
                                              RACAble(self.sampleSize),
                                              RACAble(self.hotSpot),
                                              RACAble(self.image),
                                              RACAble(self.shouldDrawBezel)
                                              ]] subscribeNext:^(id x) {
        @strongify(self);
        [self setNeedsDisplay:YES];
    }];
    
    [self rac_addDeallocDisposable:disp];
    [self registerForDraggedTypes:@[ NSFilenamesPboardType, (NSString *)kUTTypePNG ]];

}

- (void)drawRect:(NSRect)dirtyRect {    
    [NSGraphicsContext saveGraphicsState];
    
    if (self.shouldDrawBezel) {
        [gColorNormal set];
        NSRectFillUsingOperation(self.bounds, NSCompositeCopy);
        
        [NSGraphicsContext saveGraphicsState];
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:self.bounds];
        
        [gInnerStroke set];
        [path setLineWidth:4.0f];
        [path stroke];

        [gOuterStroke set];
        [path setLineWidth:2.0f];
        [path stroke];
        
        [path setClip];
        [NSGraphicsContext restoreGraphicsState];
    }
    
    if (!self.image) return;
    
    NSSize sampleSize = self.sampleSize;
    if (NSEqualSizes(self.sampleSize, NSZeroSize))
        sampleSize = self.image.size;
    
    NSSize sizeToDraw = NSMakeSize(sampleSize.width * self.scale, sampleSize.height * self.scale);
    NSPoint anchorPoint = NSZeroPoint;
    
    //!TODO If the cursor stops scaling up, halt the crosshair moving. Maybe the issue is with the anchor point?
    self.lastScaleFactor = self.scale;
    
    // Proportionally scale down
    if (sizeToDraw.width > self.bounds.size.width || sizeToDraw.height > self.bounds.size.height) {

        CGFloat scaleFactor  = 1.0;
        CGFloat widthFactor  = self.bounds.size.width / sizeToDraw.width;
        CGFloat heightFactor = self.bounds.size.height / sizeToDraw.height;
        
        if ( widthFactor < heightFactor )
            scaleFactor = widthFactor;
        else
            scaleFactor = heightFactor;
        
        self.lastScaleFactor = scaleFactor;
        
        CGFloat scaledWidth  = sizeToDraw.width * scaleFactor;
        CGFloat scaledHeight = sizeToDraw.height * scaleFactor;
        
        if ( widthFactor < heightFactor )
            anchorPoint.y = (self.bounds.size.height - scaledHeight) * 0.5;
        
        else if ( widthFactor > heightFactor )
            anchorPoint.x = (self.bounds.size.width - scaledWidth) * 0.5;
        
        sizeToDraw.width = scaledWidth;
        sizeToDraw.height = scaledHeight;
    }
    
    NSRect rect;
    rect.origin = NSMakePoint(NSMidX(self.bounds) + anchorPoint.x - sizeToDraw.width / 2, NSMidY(self.bounds) + anchorPoint.y - sizeToDraw.height / 2);
    rect.size   = sizeToDraw;
    
    self.lastFrame = NSIntegralRect(rect);
    
    self.lastRepresentation = (NSBitmapImageRep *)[self.image bestRepresentationForContentsScale:self.scale];
    [self.lastRepresentation drawInRect:self.lastFrame
                               fromRect:NSMakeRect(0, 0, sampleSize.width, sampleSize.height)
                              operation:NSCompositeSourceOver
                               fraction:1.0
                         respectFlipped:NO
                                  hints:nil];
    
    if (self.shouldChooseHotSpot) {
#define kHotSpotSize 1.0
        
        NSColor *hotSpotColor = [NSColor redColor];
        [hotSpotColor set];
        
        CGFloat scaledSize = kHotSpotSize * self.scale;
        
        NSPoint scaledPoint   = NSMakePoint(self.hotSpot.x * self.lastScaleFactor + self.lastFrame.origin.x, (self.lastFrame.origin.y + self.lastFrame.size.height) - self.hotSpot.y * self.lastScaleFactor);
        NSRect verticalLine   = NSIntegralRect(NSMakeRect(scaledPoint.x, scaledPoint.y - scaledSize * 2, scaledSize, scaledSize * 2));
        NSRect horizontalLine = NSIntegralRect(NSMakeRect(scaledPoint.x - scaledSize * 2, scaledPoint.y, scaledSize * 2, scaledSize));
        
        
        NSRectFill(verticalLine);
        NSRectFill(horizontalLine);
        
        verticalLine   = NSIntegralRect(NSMakeRect(scaledPoint.x, scaledPoint.y + scaledSize, scaledSize, scaledSize * 2));
        horizontalLine = NSIntegralRect(NSMakeRect(scaledPoint.x + scaledSize, scaledPoint.y, scaledSize * 2, scaledSize));
        
        NSRectFill(verticalLine);
        NSRectFill(horizontalLine);
    }
    
    [NSGraphicsContext restoreGraphicsState];
    
}

- (void)keyDown:(NSEvent *)theEvent {
    // Backspace without any modifiers
    if (theEvent.keyCode == 51 && theEvent.modifierFlags == 0) {
        //!TODO: Remove image current
        return;
    }
    
    [super keyDown:theEvent];
}

- (void)mouseDown:(NSEvent *)event {
    if (self.shouldChooseHotSpot && (event.modifierFlags & NSAlternateKeyMask) != NSAlternateKeyMask) {
        NSPoint clickPoint = [self convertPoint:event.locationInWindow fromView: nil];

        clickPoint.x -= self.lastFrame.origin.x;
        clickPoint.y = (self.lastFrame.origin.y + self.lastFrame.size.height) - clickPoint.y;
        
        // hotSpot.x = (clickPoint.x - self.lastFrame.origin.x) / scale
        // hotSpot.y = ((self.lastFrame.origin.y + self.lastFrame.size.height) - clickPoint.y) / scale
        // clickPoint.y = hotSpot.y * scale -
        
        // scale down magnitude
        NSPoint hs = NSMakePoint(clickPoint.x / self.lastScaleFactor, clickPoint.y / self.lastScaleFactor);
        hs.x = round(hs.x);
        hs.y = round(hs.y);
        
        if (hs.x < 0)
            hs.x = 0;
        if (hs.x > self.sampleSize.width)
            hs.x = self.sampleSize.width;
        if (hs.y < 0)
            hs.y = 0;
        if (hs.y > self.sampleSize.height)
            hs.y = self.sampleSize.height;
        
        self.hotSpot = hs;
    }
    
    [super mouseDown:event];
}
//https://bitbucket.org/alunbestor/boxer/src/347a0bfa5b04/Boxer/BXDriveList.m use that for poof code
- (void)mouseDragged:(NSEvent *)event {
    if (self.shouldDragToRemove && (event.modifierFlags & NSAlternateKeyMask) == NSAlternateKeyMask) {        
        NSPasteboard *pb = [NSPasteboard pasteboardWithName:NSDragPboard];
        [pb declareTypes:[NSArray arrayWithObject:(NSString *)kUTTypePNG] owner:self];
        [pb setData:[self.lastRepresentation representationUsingType:NSPNGFileType properties:Nil] forType:(NSString *)kUTTypePNG];
        
        NSImage *im = [[NSImage alloc] initWithSize:NSMakeSize(self.lastRepresentation.pixelsWide, self.lastRepresentation.pixelsHigh)];
        [im addRepresentation:self.lastRepresentation];
        [self dragImage:im
                     at:NSMakePoint(self.lastFrame.origin.x, self.lastFrame.origin.y)
                 offset:NSZeroSize
                  event:event
             pasteboard:pb
                 source:self
              slideBack:NO];
        
    }
    
    [super mouseDragged:event];
}

- (void)draggedImage:(NSImage *)draggedImage movedTo:(NSPoint)screenPoint {
    NSPoint mousePoint = [NSEvent mouseLocation];
    NSCursor *poof = [NSCursor disappearingItemCursor];
    
    //If there's no Boxer window under the mouse cursor, change the cursor to a poof to indicate we will discard the drive
    if (!MCWindowAtPoint(mousePoint)) [poof set];
    //otherwise, revert any poof cursor (which may already have been changed by valid drag destinations anyway)
    else if ([[NSCursor currentCursor] isEqualTo: poof]) [[NSCursor arrowCursor] set];
}


- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    NSPoint mousePoint = [NSEvent mouseLocation];
    
    if (operation == NSDragOperationNone && !MCWindowAtPoint(mousePoint)) {
        //Calculate the center-point of the image for displaying the poof icon
        NSRect imageRect;
        imageRect.size          = image.size;
        imageRect.origin        = screenPoint;
        
        NSPoint midPoint = NSMakePoint(NSMidX(imageRect), NSMidY(imageRect));
        
        //We make it square instead of fitting the width of the image,
        //because the image may include a big fat horizontal margin
        NSSize poofSize = imageRect.size;
        poofSize.width = poofSize.height;
            
                //Reset the cursor back to normal
        [[NSCursor arrowCursor] set];
        
                //Play the poof animation
        NSShowAnimationEffect(NSAnimationEffectPoof, midPoint, poofSize, nil, nil, nil);
    }

}

#pragma mark - NSDragDestination

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if ([self.delegate respondsToSelector:@selector(draggingEntered:)])
        return [self.delegate draggingEntered:sender];
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id < NSDraggingInfo >)sender {
    if ([self.delegate respondsToSelector:@selector(draggingUpdated:)])
        return [self.delegate draggingUpdated:sender];
    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
    if ([self.delegate respondsToSelector:@selector(prepareForDragOperation:)])
        return [self.delegate prepareForDragOperation:sender];
    return NO;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    if ([self.delegate respondsToSelector:@selector(performDragOperation:)])
        return [self.delegate performDragOperation:sender];
    return NO;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
    if ([self.delegate respondsToSelector:@selector(concludeDragOperation:)])
        [self.delegate concludeDragOperation:sender];
}

@end
