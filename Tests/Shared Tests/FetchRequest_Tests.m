//
//  FetchRequest_Tests.m
//  Shared Tests
//
//  Created by Scott BonAmi on 12/17/13.
//
//

#import <Kiwi/Kiwi.h>
#import "PFIncrementalStore_PrivateMethods.h"

#import <Parse/Parse.h>

#import "TestIncrementalStore.h"
#import "TestManagedObjectModel.h"

NSFetchRequest * FetchRequestWithRequestResultType(NSFetchRequestResultType resultType) {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"TestEntity"];
    [fetchRequest setResultType:resultType];
    return fetchRequest;
}

SPEC_BEGIN(FetchRequest_Tests)

__block NSFetchRequest *fetchRequest = nil;
__block TestIncrementalStore *testIncrementalStore = nil;
__block NSManagedObjectContext *testManagedObjectContext = nil;
__block NSManagedObjectContext *testBackingManagedObjectContext = nil;

beforeEach(^{
    // Create Persistent Store Coordinator so that we may create a Test Incremental Store
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[TestIncrementalStore model]];
    
    // Create Test Incremental Store
    testIncrementalStore = (TestIncrementalStore *)[persistentStoreCoordinator addPersistentStoreWithType:[TestIncrementalStore type]
                                                                                            configuration:nil URL:nil options:nil error:nil];
    
    // Create MOC for testing
    testManagedObjectContext = [[NSManagedObjectContext alloc] init];
    [testManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    
    // Create Backing Persistent Store Coordinator for the Test Incremental Store's Backing MOC
    [testIncrementalStore.backingPersistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
    
    // Create Backing MOC for testing
    testBackingManagedObjectContext = [[NSManagedObjectContext alloc] init];
    [testBackingManagedObjectContext setPersistentStoreCoordinator:testIncrementalStore.backingPersistentStoreCoordinator];
});

describe(@"executeRequest:withContext:error:", ^{
    it(@"should call executeFetchRequest:withContext:error: if the request type is NSFetchRequestType", ^{
        fetchRequest = FetchRequestWithRequestResultType(NSManagedObjectResultType);
        
        [[testIncrementalStore should] receive:@selector(executeFetchRequest:withContext:error:) withArguments:fetchRequest, testManagedObjectContext, nil];
        
        [testIncrementalStore executeRequest:fetchRequest withContext:testManagedObjectContext error:nil];
    });
});

describe(@"executeFetchRequest:withContext:error:", ^{
    beforeEach(^{
        // Stub Test Incremental Store's Backing MOC
        [testIncrementalStore stub:@selector(backingManagedObjectContext) andReturn:testBackingManagedObjectContext];
        
        // Stub Parse
        PFQuery *query = [PFQuery mock];
        [PFQuery stub:@selector(queryWithClassName:) andReturn:query withArguments:@"TestEntity"];
        [query stub:@selector(findObjectsInBackgroundWithBlock:)];
    });
    
    context(@"when the request type is NSManagedObjectResultType", ^{
        beforeEach(^{
            fetchRequest = FetchRequestWithRequestResultType(NSManagedObjectResultType);
            
            NSManagedObject *testEntity = [NSManagedObject mockWithName:@"TestEntity"];
            [testBackingManagedObjectContext stub:@selector(executeFetchRequest:error:) andReturn:@[testEntity]];
        });
        
        context(@"-- Communication with Parse --", ^{
            context(@"when the parse query fails", ^{
                pending(@"should notify user that sync is completed with no objects returned", ^{});
            });
            
            context(@"when the parse query succeeds", ^{
                pending(@"should insert new response objects into backing store", ^{});
                
                pending(@"should update existing response objects in backing store", ^{});
                
                pending(@"should notify user that sync is completed with objects returned", ^{});
            });
        });
        
        context(@"-- Communication with Backing Store --", ^{
            pending(@"should return an array of NSManagedObjects", ^{
                id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
                [[output should] beKindOfClass:[NSArray class]];
                [[[output objectAtIndex:0] should] beKindOfClass:[NSManagedObject class]];
            });
            
            pending(@"returned NSManagedObjects should be faulted", ^{
                id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
                [[output should] beKindOfClass:[NSArray class]];
                NSManagedObject *firstObject = [output objectAtIndex:0];
                [[theValue([firstObject isFault]) should] beTrue];
            });
        });
    });
    
    context(@"when the request type is NSManagedObjectIDResultType", ^{
        beforeEach(^{
            fetchRequest = FetchRequestWithRequestResultType(NSManagedObjectIDResultType);
            
            NSManagedObject *testEntity = [NSManagedObject mockWithName:@"TestEntity"];
            [testBackingManagedObjectContext stub:@selector(executeFetchRequest:error:) andReturn:@[testEntity]];
        });
        
        pending(@"should return an array of NSManagedObjectIDs", ^{
            id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
            [[output should] beKindOfClass:[NSArray class]];
            [[[output objectAtIndex:0] should] beKindOfClass:[NSManagedObjectID class]];
        });
    });
    
    context(@"when the request type is NSDictionaryResultType", ^{
        beforeEach(^{
            fetchRequest = FetchRequestWithRequestResultType(NSDictionaryResultType);
            
            NSManagedObject *testEntity = [NSManagedObject mockWithName:@"TestEntity"];
            [testBackingManagedObjectContext stub:@selector(executeFetchRequest:error:) andReturn:@[testEntity]];
        });
        
        pending(@"should return an array of NSDictionaries", ^{
            id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
            [[output should] beKindOfClass:[NSArray class]];
            [[[output objectAtIndex:0] should] beKindOfClass:[NSDictionary class]];
        });
    });
    
    context(@"when the request type is NSCountResultType", ^{
        beforeEach(^{
            fetchRequest = FetchRequestWithRequestResultType(NSCountResultType);
            
            NSManagedObject *testEntity = [NSManagedObject mockWithName:@"TestEntity"];
            [testBackingManagedObjectContext stub:@selector(executeFetchRequest:error:) andReturn:@[testEntity]];
        });
        
        pending(@"should return an array with one NSNumber value", ^{
            id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
            [[output should] beKindOfClass:[NSArray class]];
            [[theValue([output count]) should] equal:theValue(1)];
            [[[output objectAtIndex:0] should] beKindOfClass:[NSNumber class]];
        });
        
        pending(@"returned NSNumber should equal the number of objects returned in the query", ^{
            id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
            [[output should] beKindOfClass:[NSArray class]];
            NSNumber *firstObject = [output objectAtIndex:0];
            [[firstObject should] equal:[NSNumber numberWithInt:2]];
        });
    });
    
    context(@"when the request type is invalid", ^{
        it(@"should raise an exception", ^{
            NSFetchRequest *invalidFetchRequest = FetchRequestWithRequestResultType(-1);
            [[theBlock(^{ [testManagedObjectContext executeFetchRequest:invalidFetchRequest error:nil]; }) shouldNot] raiseWithName:kPFIncrementalStoreUnimplementedMethodException];
        });
    });
});

SPEC_END