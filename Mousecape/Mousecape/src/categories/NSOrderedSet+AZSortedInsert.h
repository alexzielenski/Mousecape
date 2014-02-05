//
//  NSOrderedSet+AZSortedInsert.h
//  Mousecape
//
//  Created by Alex Zielenski on 6/26/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <Foundation/Foundation.h>

// Adapted from NSArray+CWSortedInsert
@interface NSOrderedSet (AZSortedInsert)

- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingfunction:(NSInteger (*)(id, id, void *))compare context:(void *)context;
- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingComparator:(NSComparator)comparator;
- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingSelector:(SEL)aSelector;
- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingDescriptors:(NSArray *)descriptors;

@end

@interface NSMutableOrderedSet (AZSortedInsert)

- (void)insertObject:(id)anObject sortedUsingfunction:(NSInteger (*)(id, id, void *))compare context:(void *)context;
- (void)insertObject:(id)anObject sortedUsingSelector:(SEL)aSelector;
- (void)insertObject:(id)anObject sortedUsingDescriptors:(NSArray *)descriptors;

@end
