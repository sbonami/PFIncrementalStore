//
//  NSMutableDictionary_Tests.m
//  Shared Tests
//
//  Created by Scott BonAmi on 3/4/14.
//
//

#import <Kiwi/Kiwi.h>
#import "PFIncrementalStore_PrivateMethods.h"

SPEC_BEGIN(Category_NSMutableDictionary_Tests)

describe(@"setPFFile:forKey:", ^{
    __block PFFile *testFile = nil;
    __block NSData *testFileData = nil;
    __block NSMutableDictionary *testDictionary = nil;
    
    beforeEach(^{
        testFile = [PFFile nullMock];
        testFileData = [NSData nullMock];
        testDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        
        [testFile stub:@selector(getData) andReturn:testFileData];
    });
    
    it(@"should update the Dictionary by setting the PFFile's data as the value for the key", ^{
        NSString *testKey = @"TEST KEY";
        [testDictionary setPFFile:testFile forKey:testKey];
        
        [[[testDictionary objectForKey:testKey] should] equal:testFileData];
    });
});

SPEC_END