//
//  iOS_Test.m
//  iOS Test
//
//  Created by Scott BonAmi on 12/11/13.
//
//

#import <XCTest/XCTest.h>

@interface iOS_Test : XCTestCase

@end

@implementation iOS_Test

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

@end
