//
//  MCCapePreviewItem.h
//  Mousecape
//
//  Created by Alex Zielenski on 3/10/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMAnimatingImageView.h"

@interface MCCapePreviewItem : NSCollectionViewItem
@property (nonatomic, assign) IBOutlet MMAnimatingImageView *animatingImageView;
@end
