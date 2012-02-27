//
//  MMAnimatingImageTableCellView.h
//  Magic Mouse
//
//  Created by Alex Zielenski on 2/26/12.
//  Copyright (c) 2012 Alex Zielenski. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "MMAnimatingImageView.h"

@interface MMAnimatingImageTableCellView : NSTableCellView
@property (nonatomic, retain) IBOutlet MMAnimatingImageView *animatingImageView;
@end
