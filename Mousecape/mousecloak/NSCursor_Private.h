//
//  NSCursor_Private.h
//  CursorProject
//
//  Created by Alex Zielenski on 2/19/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

@interface NSCursor (Private)
+ (void)initialize;
+ (id)_buildCursor:(id)arg1 cursorData:(struct CGPoint)arg2;
+ (id)arrowCursor;
+ (id)IBeamCursor;
+ (id)pointingHandCursor;
+ (id)closedHandCursor;
+ (id)openHandCursor;
+ (id)resizeLeftCursor;
+ (id)resizeRightCursor;
+ (id)resizeLeftRightCursor;
+ (id)resizeUpCursor;
+ (id)resizeDownCursor;
+ (id)resizeUpDownCursor;
+ (id)crosshairCursor;
+ (id)disappearingItemCursor;
+ (id)operationNotAllowedCursor;
+ (id)busyButClickableCursor;
+ (id)contextualMenuCursor;
+ (id)IBeamCursorForVerticalLayout;
+ (void)hide;
+ (void)unhide;
+ (void)setHiddenUntilMouseMoves:(BOOL)arg1;
+ (id)currentCursor;
+ (id)currentSystemCursor;
+ (void)_setOverrideCursor:(id)arg1;
+ (void)_clearOverrideCursorAndSetArrow;
+ (void)pop;
+ (id)_makeCursors;
+ (id)_setHelpCursor:(BOOL)arg1;
+ (BOOL)helpCursorShown;
+ (id)dragCopyCursor;
+ (id)_copyDragCursor;
+ (id)dragLinkCursor;
+ (id)_genericDragCursor;
+ (id)_handCursor;
+ (id)_closedHandCursor;
+ (id)_moveCursor;
+ (id)_waitCursor;
+ (id)_crosshairCursor;
+ (id)_horizontalResizeCursor;
+ (id)_verticalResizeCursor;
+ (id)_bottomLeftResizeCursor;
+ (id)_topLeftResizeCursor;
+ (id)_bottomRightResizeCursor;
+ (id)_topRightResizeCursor;
+ (id)_resizeLeftCursor;
+ (id)_resizeRightCursor;
+ (id)_resizeLeftRightCursor;
+ (id)_zoomInCursor;
+ (id)_zoomOutCursor;
+ (id)_windowResizeEastCursor;
+ (id)_windowResizeWestCursor;
+ (id)_windowResizeEastWestCursor;
+ (id)_windowResizeNorthCursor;
+ (id)_windowResizeSouthCursor;
+ (id)_windowResizeNorthSouthCursor;
+ (id)_windowResizeNorthEastCursor;
+ (id)_windowResizeNorthWestCursor;
+ (id)_windowResizeSouthEastCursor;
+ (id)_windowResizeSouthWestCursor;
+ (id)_windowResizeNorthEastSouthWestCursor;
+ (id)_windowResizeNorthWestSouthEastCursor;
- (id)initWithImage:(id)arg1 hotSpot:(struct CGPoint)arg2;
- (id)initWithImage:(id)arg1 foregroundColorHint:(id)arg2 backgroundColorHint:(id)arg3 hotSpot:(struct CGPoint)arg4;
- (void)_setImage:(id)arg1;
- (id)init;
- (void)dealloc;
- (long long)_coreCursorType;
- (void)_getImageAndHotSpotFromCoreCursor;
- (id)image;
- (struct CGPoint)hotSpot;
- (void)setOnMouseExited:(BOOL)arg1;
- (void)setOnMouseEntered:(BOOL)arg1;
- (BOOL)isSetOnMouseExited;
- (BOOL)isSetOnMouseEntered;
- (id)_premultipliedARGBBitmaps;
- (void)_reallySet;
- (void)set;
- (id)forceSet;
- (void)mouseEntered:(id)arg1;
- (void)mouseExited:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)awakeAfterUsingCoder:(id)arg1;
- (void)push;
- (void)pop;

@end
