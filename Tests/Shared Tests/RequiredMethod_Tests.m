//
//  RequiredMethod_Tests.m
//  Shared Tests
//
//  Created by Scott BonAmi on 12/17/13.
//
//

#import <Kiwi/Kiwi.h>
#import "PFIncrementalStore_PrivateMethods.h"

#import "TestIncrementalStore.h"

SPEC_BEGIN(RequiredMethod_Tests)

describe(@"+type", ^{
    context(@"when a subclass has not implemented the method", ^{
        it(@"should raise an exception", ^{
            [[theBlock(^{ [PFIncrementalStore type]; }) should] raiseWithName:kPFIncrementalStoreUnimplementedMethodException];
        });
    });
    
    context(@"when a subclass has implemented the method", ^{
        it(@"should not raise an exception", ^{
            [[theBlock(^{ [TestIncrementalStore type]; }) shouldNot] raiseWithName:kPFIncrementalStoreUnimplementedMethodException];
        });
    });
});

describe(@"+model", ^{
    context(@"when a subclass has not implemented the method", ^{
        it(@"should raise an exception", ^{
            [[theBlock(^{ [PFIncrementalStore model]; }) should] raiseWithName:kPFIncrementalStoreUnimplementedMethodException];
        });
    });
    
    context(@"when a subclass has implemented the method", ^{
        it(@"should not raise an exception", ^{
            [[theBlock(^{ [TestIncrementalStore model]; }) shouldNot] raiseWithName:kPFIncrementalStoreUnimplementedMethodException];
        });
    });
});

SPEC_END