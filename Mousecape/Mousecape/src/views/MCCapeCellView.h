//
//  MCCapeCellView.h
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MMAnimatingImageView.h"

@interface MCCapeCellView : NSTableCellView
@property IBOutlet NSTextField *titleField;
@property IBOutlet NSTextField *subtitleField;
@property IBOutlet NSImageView *appliedImageView;
@property IBOutlet NSImageView *resolutionImageView;
@property IBOutlet NSCollectionView *collectionView;
@end

@interface MCHDValueTransformer : NSValueTransformer
@end

