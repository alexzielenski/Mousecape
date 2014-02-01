//
//  BTRScrollView.m
//  Originally from Rebel
//
//  Created by Jonathan Willing on 12/4/12.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "BTRScrollView.h"
#import "BTRClipView.h"

@implementation BTRScrollView

#pragma mark Lifecycle

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil) return nil;
	
	[self swapClipView];
	
	return self;
}

- (void)awakeFromNib {
	[super awakeFromNib];
	
	if (![self.contentView isKindOfClass:BTRClipView.class] ) {
		[self swapClipView];
	}
}

#pragma mark Clip view swapping

- (void)swapClipView {
	self.wantsLayer = YES;
	id documentView = self.documentView;
	Class clipViewClass = [self.class clipViewClass];
	BTRClipView *clipView = [[clipViewClass alloc] initWithFrame:self.contentView.frame];
	clipView.backgroundColor = [self.contentView backgroundColor];
	self.contentView = clipView;
	self.documentView = documentView;
}

+ (Class)clipViewClass {
	return [BTRClipView class];
}

@end
