//
//  NSArray+CWSortedInsert.m
//  CWFoundation
//  Created by Fredrik Olsson
//
//  Copyright (c) 2011, Jayway AB All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of Jayway AB nor the names of its contributors may
//       be used to endorse or promote products derived from this software
//       without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL JAYWAY AB BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
//  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "NSArray+CWSortedInsert.h"
#import <objc/message.h>

@implementation NSArray (CWSortedInsert)

-(NSUInteger)indexForInsertingObject:(id)anObject sortedUsingfunction:(NSInteger (*)(id, id, void *))compare context:(void*)context;
{
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

-(NSUInteger)indexForInsertingObject:(id)anObject sortedUsingSelector:(SEL)aSelector;
{
	return [self indexForInsertingObject:anObject sortedUsingfunction:&cw_SelectorCompare context:aSelector];
}

static IMP cw_compareObjectToObjectImp = NULL;
static IMP cw_ascendingImp = NULL;

+(void)initialize;
{
    cw_compareObjectToObjectImp = [NSSortDescriptor instanceMethodForSelector:@selector(compareObject:toObject:)];
	cw_ascendingImp = [NSSortDescriptor instanceMethodForSelector:@selector(ascending)];
}

static NSComparisonResult cw_DescriptorCompare(id a, id b, void* descriptors) {
	NSComparisonResult result = NSOrderedSame;
    for (NSSortDescriptor* sortDescriptor in (NSArray*)descriptors) {
		result = (NSComparisonResult)cw_compareObjectToObjectImp(sortDescriptor, @selector(compareObject:toObject:), a, b);
        if (result != NSOrderedSame) {
            break;
        }
    }
    return result;
}

-(NSUInteger)indexForInsertingObject:(id)anObject sortedUsingDescriptors:(NSArray*)descriptors;
{
	return [self indexForInsertingObject:anObject sortedUsingfunction:&cw_DescriptorCompare context:descriptors];
}

@end


@implementation NSMutableArray (CWSortedInsert)

-(void)insertObject:(id)anObject sortedUsingfunction:(NSInteger (*)(id, id, void *))compare context:(void*)context;
{
	NSUInteger index = [self indexForInsertingObject:anObject sortedUsingfunction:compare context:context];
    [self insertObject:anObject atIndex:index];
}

-(void)insertObject:(id)anObject sortedUsingSelector:(SEL)aSelector;
{
	NSUInteger index = [self indexForInsertingObject:anObject sortedUsingfunction:&cw_SelectorCompare context:aSelector];
	[self insertObject:anObject atIndex:index];
}

-(void)insertObject:(id)anObject sortedUsingDescriptors:(NSArray*)descriptors;
{
	NSUInteger index = [self indexForInsertingObject:anObject sortedUsingDescriptors:descriptors];
    [self insertObject:anObject atIndex:index];
}

@end