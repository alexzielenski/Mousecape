//
//  Mousecape_Tests.m
//  Mousecape Tests
//
//  Created by Alex Zielenski on 6/29/13.
//  Copyright (c) 2013 Alex Zielenski. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MCCursorLibrary.h"

@interface Mousecape_Tests : XCTestCase
@property (nonatomic, strong) MCCursorLibrary *library;
@end

@implementation Mousecape_Tests

- (void)setUp
{
    [super setUp];
    NSURL *fileURL = [[NSBundle bundleForClass:self.class] URLForResource:@"Metropolite" withExtension:@"cape"];
    
    self.library = [MCCursorLibrary cursorLibraryWithContentsOfURL:fileURL];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testSize {
    MCCursor *cursor = self.library.cursors.anyObject;
    CGFloat scale    = 1.0;
    NSImageRep *rep  = [cursor smallestRepresentationWithScale:&scale];
    XCTAssertTrue(NSEqualSizes(cursor.size, NSMakeSize(rep.pixelsWide / scale, rep.pixelsHigh / scale / cursor.frameCount)), @"Cursor size must be equal to the rep's frame size");
}

- (void)testCopying {
    MCCursorLibrary *copy = self.library.copy;
    XCTAssertNotNil(copy, @"copy must not non nil");
    XCTAssertTrue([self.library isEqualTo:copy], @"Copying must return an equal object");
}

@end
