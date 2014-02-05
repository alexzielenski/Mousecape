//
//  NSOrderedSet+AZSortedInsert.m
//  Mousecape
//
//  Created by Alex Zielenski on 6/26/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import "NSOrderedSet+AZSortedInsert.h"
#import <objc/message.h>

@implementation NSOrderedSet (AZSortedInsert)

- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingfunction:(NSInteger (*)(id, id, void *))compare context:(void *)context; {
    NSUInteger index = 0;
	NSUInteger topIndex = [self count];
    IMP objectAtIndexImp = [self methodForSelector:@selector(objectAtIndex:)];
    while (index < topIndex) {
        NSUInteger midIndex = (index + topIndex) / 2;
        id testObject = objectAtIndexImp(self, @selector(objectAtIndex:), midIndex);
        if (compare(anObject, testObject, context) > 0) {
            index = midIndex + 1;
        } else {
            topIndex = midIndex;
        }
    }
    return index;
}

static NSComparisonResult cw_SelectorCompare(id a, id b, void* aSelector) {
	return (NSComparisonResult)objc_msgSend(a, (SEL)aSelector, b);
}

static NSComparisonResult az_comparatorCompare(id a, id b, NSComparator comparator) {
    return comparator(a, b);
}

- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingSelector:(SEL)aSelector; {
	return [self indexForInsertingObject:anObject sortedUsingfunction:&cw_SelectorCompare context:aSelector];
}

- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingComparator:(NSComparator)comparator {
    return [self indexForInsertingObject:anObject sortedUsingfunction:(NSInteger (*)(id, id, void *))&az_comparatorCompare context:comparator];
}

static IMP cw_compareObjectToObjectImp = NULL;
static IMP cw_ascendingImp = NULL;

+ (void)initialize; {
    cw_compareObjectToObjectImp = [NSSortDescriptor instanceMethodForSelector:@selector(compareObject:toObject:)];
	cw_ascendingImp = [NSSortDescriptor instanceMethodForSelector:@selector(ascending)];
}

static NSComparisonResult cw_DescriptorCompare(id a, id b, void* descriptors) {
	NSComparisonResult result = NSOrderedSame;
    for (NSSortDescriptor* sortDescriptor in (NSArray *)descriptors) {
		result = (NSComparisonResult)cw_compareObjectToObjectImp(sortDescriptor, @selector(compareObject:toObject:), a, b);
        if (result != NSOrderedSame) {
            break;
        }
    }
    return result;
}

- (NSUInteger)indexForInsertingObject:(id)anObject sortedUsingDescriptors:(NSArray *)descriptors;
{
	return [self indexForInsertingObject:anObject sortedUsingfunction:&cw_DescriptorCompare context:descriptors];
}

@end

@implementation NSMutableOrderedSet (AZSortedInsert)

- (void)insertObject:(id)anObject sortedUsingfunction:(NSInteger (*)(id, id, void *))compare context:(void *)context; {
	NSUInteger index = [self indexForInsertingObject:anObject sortedUsingfunction:compare context:context];
    [self insertObject:anObject atIndex:index];
}

- (void)insertObject:(id)anObject sortedUsingSelector:(SEL)aSelector; {
	NSUInteger index = [self indexForInsertingObject:anObject sortedUsingfunction:&cw_SelectorCompare context:aSelector];
	[self insertObject:anObject atIndex:index];
}

- (void)insertObject:(id)anObject sortedUsingDescriptors:(NSArray *)descriptors; {
	NSUInteger index = [self indexForInsertingObject:anObject sortedUsingDescriptors:descriptors];
    [self insertObject:anObject atIndex:index];
}

@end
