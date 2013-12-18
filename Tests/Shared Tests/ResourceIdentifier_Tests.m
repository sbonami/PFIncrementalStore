//
//  ResourceIdentifier_Tests.m
//  Shared Tests
//
//  Created by Scott BonAmi on 12/17/13.
//
//

#import <Kiwi/Kiwi.h>
#import "PFIncrementalStore_PrivateMethods.h"

SPEC_BEGIN(ResourceIdentifier_Tests)

describe(@"PFReferenceObjectFromResourceIdentifier", ^{
    context(@"with an invalid argument", ^{
        it(@"should return nil", ^{
            [[PFReferenceObjectFromResourceIdentifier(nil) should] beNil];
        });
    });
    
    context(@"with a valid argument", ^{
        it(@"should return a reference object that begins with kPFReferenceObjectPrefix", ^{
            NSString *resourceIdentifier = @"resourceIdentifier";
            [[PFReferenceObjectFromResourceIdentifier(resourceIdentifier) should] equal:[NSString stringWithFormat:@"__pf_%@",resourceIdentifier]];
        });
    });
});

describe(@"PFResourceIdentifierFromReferenceObject", ^{
    context(@"with an invalid argument", ^{
        it(@"should return nil", ^{
            [[PFResourceIdentifierFromReferenceObject(nil) should] beNil];
        });
    });
    
    context(@"when an argument is passed", ^{
        context(@"and the argument starts with kPFReferenceObjectPrefix", ^{
            it(@"should return a resource identifier without the kPFReferenceObjectPrefix", ^{
                NSString *resourceIdentifier = @"resourceIdentifier";
                NSString *referenceObject = [NSString stringWithFormat:@"__pf_%@",resourceIdentifier];
                [[PFResourceIdentifierFromReferenceObject(referenceObject) should] equal:resourceIdentifier];
            });
        });
        context(@"and the argument does not start with kPFReferenceObjectPrefix", ^{
            it(@"should return a resource identifier equal to the argument", ^{
                NSString *referenceObject = @"referenceObject";
                [[PFResourceIdentifierFromReferenceObject(referenceObject) should] equal:referenceObject];
            });
        });
    });
});

SPEC_END