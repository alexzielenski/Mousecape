//
//  MousecapeTests.m
//  MousecapeTests
//
//  Created by Alex Zielenski on 2/1/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MCCursorLibrary.h"

@interface MousecapeTests : XCTestCase
@property (strong) MCCursorLibrary *library;
@end

@implementation MousecapeTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.library = [MCCursorLibrary cursorLibraryWithContentsOfFile:[@(PROJECT_DIR) stringByAppendingPathComponent: @"com.maxrudberg.svanslosbluehazard.cape"]];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testLibraryCreation {
    XCTAssertTrue(self.library != nil, @"Library must not be nil");
    XCTAssertEqualObjects(self.library.author, @"Max Rudberg", @"Author must be taken from cape");
    XCTAssertEqualObjects(self.library.identifier, @"com.maxrudberg.svanslosbluehazard", @"Identifier must be taken from cape");
    XCTAssertNotNil([self.library cursorWithIdentifier:@"com.apple.coregraphics.Arrow"], @"Must retrieve cursor correctly");
}

- (void)testCursorCreation {
    MCCursor *cursor = [self.library cursorWithIdentifier:@"com.apple.coregraphics.Arrow"];
    XCTAssertTrue(cursor.representations.count == 4, @"Must have correct cursor count");
    XCTAssertTrue(cursor.frameCount == 1, @"Must have correct frame count");
    XCTAssertTrue(cursor.frameDuration == 1, @"Must have current frame duration");
    XCTAssertTrue(NSEqualSizes(cursor.size, NSMakeSize(20, 24)), @"Must have correct size");
    
    NSImageRep *smallest = [cursor representationForScale:MCCursorScale100];
    XCTAssertTrue(NSEqualSizes(NSMakeSize(smallest.pixelsWide, smallest.pixelsHigh), cursor.size), @"Size must be equal to 1x rep");
}

- (void)testCursorOperations {
    MCCursor *cursor = [self.library cursorWithIdentifier:@"com.apple.coregraphics.Arrow"];
    [self.library moveCursorAtIdentifier:@"com.apple.coregraphics.Arrow" toIdentifier:@"com.apple.cursor.2"];
    XCTAssertEqualObjects(cursor.name, nameForCursorIdentifier(@"com.apple.cursor.2"), @"Name must be correctly set");
    XCTAssertEqual(cursor, [self.library cursorWithIdentifier:@"com.apple.cursor.2"], @"Object must not be copied");
    XCTAssertEqualObjects(cursor, cursor, @"isEqualTo: must work");
    XCTAssertNil([self.library cursorWithIdentifier:@"com.apple.coregraphics.Arrow"], @"Old cursor spot must not be occupied");

    MCCursor *replacement = [[MCCursor alloc] init];
    [self.library setCursor:replacement forIdentifier:@"com.apple.cursor.2"];
    XCTAssertEqualObjects(cursor.name, @"", @"Name of old cursor must be set to an empty string");
    XCTAssertEqual(replacement, [self.library cursorWithIdentifier:@"com.apple.cursor.2"], @"Replacement cursor must be retrievable");
}

- (void)testSavingAndReading {
    NSDictionary *dictionary = self.library.dictionaryRepresentation;
    MCCursorLibrary *read = [MCCursorLibrary cursorLibraryWithDictionary:dictionary];
    XCTAssertEqualObjects(self.library, read, @"Saving and reading must result in equal objects");
}

@end
