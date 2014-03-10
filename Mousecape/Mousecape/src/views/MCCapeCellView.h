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
@property (assign) IBOutlet NSTextField *titleField;
@property (assign) IBOutlet NSTextField *subtitleField;
@property (assign) IBOutlet NSImageView *appliedImageView;
@property (assign) IBOutlet NSCollectionView *collectionView;
@end

@interface MCHDValueTransformer : NSValueTransformer
@end

