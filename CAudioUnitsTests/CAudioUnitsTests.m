//
//  CAudioUnitsTests.m
//  CAudioUnitsTests
//
//  Created by CHARLES GILLINGHAM on 6/28/15.
//  Copyright (c) 2015 CharlesGillingham. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

#import "CAudioUnit+Debug.h"
#import "CAudioUnit+Examples.h"

@interface CAudioUnitTests : XCTestCase
@end


@implementation CAudioUnitTests

- (void) test1                        { XCTAssert([CAudioUnit test1]); }
- (void) test2                        { XCTAssert([CAudioUnit test2]); }
- (void) testChangeEffect             { XCTAssert([CAudioUnit testChangeEffect]); }
- (void) testSearch                   { XCTAssert([CAudioUnit testSearch]); }
- (void) testLoadSave;                { XCTAssert([CAudioUnit testLoadSave]); }
- (void) testMultipleManagers         { XCTAssert([CAudioUnit testMultipleManagers]); }
- (void) testErrors                   { XCTAssert([CAudioUnit testErrors]); }
- (void) testConnectionsGridTest      { XCTAssert([CAudioUnit connectionsGridTest]); }
- (void) testUnits                    { XCTAssert([CAudioUnit unitGridTest]); }
- (void) testInstrument               { XCTAssert([CAudioUnit testInstrument]); }

// Can't run this test in the framework
//- (void) testUI                       { XCTAssert([CAudioUnit UICrashTest]); }

@end