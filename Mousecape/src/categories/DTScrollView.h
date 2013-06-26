//
//  DTScrollView.h
//  iCatalogEditor
//
//  Created by Oliver Drobnik on 10/23/12.
//  Copyright (c) 2012 Oliver Drobnik. All rights reserved.
//


/**
 A scroll view that forwards scroll events up the responder chain if scrolling is along an axis that no scroll bar is shown for. This is useful to have a horizontal scroll view contained in a vertical one. To enable, set usesPredominantAxisScrolling to YES and hide the scroll bar for the axis you don't want to support.
 */
#import "RBLScrollView.h"

@interface DTScrollView : RBLScrollView

@end