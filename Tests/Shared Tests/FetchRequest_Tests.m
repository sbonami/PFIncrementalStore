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

typedef void(^NSManagedContextPerformBlockHandler)();

NSFetchRequest * FetchRequestWithRequestResultTypeAndEntityDescription(NSFetchRequestResultType resultType, NSEntityDescription *entityDescription) {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entityDescription];
    [fetchRequest setResultType:resultType];
    return fetchRequest;
}

SPEC_BEGIN(FetchRequest_Tests)

__block NSFetchRequest *fetchRequest = nil;
__block NSManagedObject *testEntity = nil;
__block NSEntityDescription *testEntityDescription = nil;
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
    testManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [testManagedObjectContext setPersistentStoreCoordinator:persistentStoreCoordinator];
    
    // Create Backing Persistent Store Coordinator for the Test Incremental Store's Backing MOC
    [testIncrementalStore.backingPersistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
    
    // Create Backing MOC for testing
    testBackingManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [testBackingManagedObjectContext setPersistentStoreCoordinator:testIncrementalStore.backingPersistentStoreCoordinator];
    
    testEntityDescription = [NSEntityDescription entityForName:@"TestEntity" inManagedObjectContext:testManagedObjectContext];
});

describe(@"executeRequest:withContext:error:", ^{
    it(@"should call executeFetchRequest:withContext:error: if the request type is NSFetchRequestType", ^{
        fetchRequest = FetchRequestWithRequestResultTypeAndEntityDescription(NSManagedObjectResultType, testEntityDescription);
        
        [[testIncrementalStore should] receive:@selector(executeFetchRequest:withContext:error:) withArguments:fetchRequest, testManagedObjectContext, nil];
        
        [testIncrementalStore executeRequest:fetchRequest withContext:testManagedObjectContext error:nil];
    });
});

describe(@"executeFetchRequest:withContext:error:", ^{
    __block PFQuery *testQuery = nil;
    
    beforeEach(^{
        // Stub Test Incremental Store's Backing MOC
        [testIncrementalStore stub:@selector(backingManagedObjectContext) andReturn:testBackingManagedObjectContext];
        
        // Setup and stub Test Entity
        testEntity = [NSManagedObject mockWithName:testEntityDescription.name];
        [testEntity stub:@selector(entity) andReturn:testEntityDescription];
        
        // Stub Parse
        testQuery = [PFQuery mock];
        [PFQuery stub:@selector(queryWithClassName:predicate:) andReturn:testQuery withArguments:fetchRequest.entityName, fetchRequest.predicate];
    });
    
    context(@"when the request type is invalid", ^{
        beforeEach(^{
            [testQuery stub:@selector(findObjectsInBackgroundWithBlock:)];
        });
        
        it(@"should return an error", ^{
            NSFetchRequest *invalidFetchRequest = FetchRequestWithRequestResultTypeAndEntityDescription(-1, testEntityDescription);
            
            NSError *error = nil;
            [testIncrementalStore executeFetchRequest:invalidFetchRequest withContext:testManagedObjectContext error:&error];
            
            [[error.domain should] equal:kPFIncrementalStoreErrorDomain];
            [[[error.userInfo objectForKey:NSLocalizedDescriptionKey] should] containString:@"Unsupported NSFetchRequestResultType"];
        });
    });
    
    context(@"when the request type is NSManagedObjectResultType", ^{
        beforeEach(^{
            fetchRequest = FetchRequestWithRequestResultTypeAndEntityDescription(NSManagedObjectResultType, testEntityDescription);
        });
        
        it(@"should notify user that sync has started with no objects returned", ^{
            [testQuery stub:@selector(findObjectsInBackgroundWithBlock:)];
            
            [[testIncrementalStore shouldEventually] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forFetchRequest:fetchedObjectIDs:) withArguments:testManagedObjectContext, theValue(NO), fetchRequest, nil];
            
            [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
        });
        
        context(@"-- Communication with Parse --", ^{
            context(@"when the parse query fails", ^{
                it(@"should notify user that sync is completed with no objects returned", ^{
                    KWCaptureSpy *spy = [testQuery captureArgument:@selector(findObjectsInBackgroundWithBlock:) atIndex:0];
                    
                    [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
                    
                    PFArrayResultBlock blockToRun = spy.argument;
                    
                    [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forFetchRequest:fetchedObjectIDs:) withArguments:testManagedObjectContext, theValue(YES), fetchRequest, nil];
                    
                    blockToRun(nil, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
                });
            });
            
            context(@"when the parse query succeeds", ^{
                __block PFObject *testParseObject = nil;
                __block PFArrayResultBlock testParseReturnBlock = nil;
                
                beforeEach(^{
                    // Stub Parse
                    PFQuery *query = [PFQuery mock];
                    KWCaptureSpy *spy = [query captureArgument:@selector(findObjectsInBackgroundWithBlock:) atIndex:0];
                    [PFQuery stub:@selector(queryWithClassName:predicate:) andReturn:query withArguments:fetchRequest.entityName, fetchRequest.predicate];
                    
                    [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
                    
                    testParseObject = [PFObject nullMock];
                    [testParseObject stub:@selector(objectId) andReturn:@"TestParseObjectID"];
                    [testEntity stub:@selector(valueForKey:) andReturn:@"TestParseObjectID" withArguments:kPFIncrementalStoreResourceIdentifierAttributeName];
                    
                    [testBackingManagedObjectContext stub:@selector(executeFetchRequest:error:) andReturn:@[testEntity]];
                    
                    testParseReturnBlock = spy.argument;
                });
                
                it(@"should create and update response objects", ^{
                    [[testIncrementalStore shouldEventually] receive:@selector(insertOrUpdateObjects:ofEntity:withContext:error:completionBlock:) andReturn:nil withArguments:@[testParseObject], testEntityDescription, any(), nil, any()];
                    
                    testParseReturnBlock(@[testParseObject], nil);
                });
                
                it(@"should save intermediate context", ^{
                    [testIncrementalStore stub:@selector(insertOrUpdateObjects:ofEntity:withContext:error:completionBlock:) andReturn:nil];
                    
                    NSManagedObjectContext *testChildMoc = [NSManagedObjectContext nullMock];
                    [testIncrementalStore stub:@selector(privateChildContextForParentContext:) andReturn:testChildMoc withArguments:testManagedObjectContext];
                    
                    [testBackingManagedObjectContext stub:@selector(save:) andReturn:theValue(YES)];
                    
                    KWCaptureSpy *testMocSpy = [testManagedObjectContext captureArgument:@selector(performBlock:) atIndex:0];
                    KWCaptureSpy *testChildMocSpy = [testChildMoc captureArgument:@selector(performBlock:) atIndex:0];
                    KWCaptureSpy *callbackSpy = [testIncrementalStore captureArgument:@selector(insertOrUpdateObjects:ofEntity:withContext:error:completionBlock:) atIndex:4];
                    
                    testParseReturnBlock(@[testParseObject], nil);
                    NSManagedContextPerformBlockHandler testMocBlockHandler = testMocSpy.argument;
                    testMocBlockHandler();
                    NSManagedContextPerformBlockHandler testChildMocBlockHandler = testChildMocSpy.argument;
                    testChildMocBlockHandler();
                    
                    [[testChildMoc should] receive:@selector(save:) andReturn:theValue(YES) withCountAtLeast:1];
                    
                    PFInsertUpdateResponseBlock blockToRun = callbackSpy.argument;
                    blockToRun(@[testEntity], @[testEntity]);
                });
                
                it(@"should save backing store context", ^{
                    [testIncrementalStore stub:@selector(insertOrUpdateObjects:ofEntity:withContext:error:completionBlock:) andReturn:nil];
                    
                    NSManagedObjectContext *testChildMoc = [NSManagedObjectContext nullMock];
                    [testChildMoc stub:@selector(save:) andReturn:theValue(YES)];
                    [testIncrementalStore stub:@selector(privateChildContextForParentContext:) andReturn:testChildMoc withArguments:testManagedObjectContext];
                    
                    KWCaptureSpy *testMocSpy = [testManagedObjectContext captureArgument:@selector(performBlock:) atIndex:0];
                    KWCaptureSpy *testChildMocSpy = [testChildMoc captureArgument:@selector(performBlock:) atIndex:0];
                    KWCaptureSpy *callbackSpy = [testIncrementalStore captureArgument:@selector(insertOrUpdateObjects:ofEntity:withContext:error:completionBlock:) atIndex:4];
                    
                    testParseReturnBlock(@[testParseObject], nil);
                    NSManagedContextPerformBlockHandler testMocBlockHandler = testMocSpy.argument;
                    testMocBlockHandler();
                    NSManagedContextPerformBlockHandler testChildMocBlockHandler = testChildMocSpy.argument;
                    testChildMocBlockHandler();
                    
                    [[testBackingManagedObjectContext should] receive:@selector(save:) andReturn:theValue(YES) withCountAtLeast:1];
                    
                    PFInsertUpdateResponseBlock blockToRun = callbackSpy.argument;
                    blockToRun(@[testEntity], @[testEntity]);
                });
                
                it(@"should notify user that sync is completed with objects returned", ^{
                    [testIncrementalStore stub:@selector(insertOrUpdateObjects:ofEntity:withContext:error:completionBlock:) andReturn:nil];
                    
                    NSManagedObjectContext *testChildMoc = [NSManagedObjectContext nullMock];
                    [testChildMoc stub:@selector(save:) andReturn:theValue(YES)];
                    [testIncrementalStore stub:@selector(privateChildContextForParentContext:) andReturn:testChildMoc withArguments:testManagedObjectContext];
                    
                    [testBackingManagedObjectContext stub:@selector(save:) andReturn:theValue(YES)];
                    
                    KWCaptureSpy *testMocSpy = [testManagedObjectContext captureArgument:@selector(performBlock:) atIndex:0];
                    KWCaptureSpy *testChildMocSpy = [testChildMoc captureArgument:@selector(performBlock:) atIndex:0];
                    KWCaptureSpy *callbackSpy = [testIncrementalStore captureArgument:@selector(insertOrUpdateObjects:ofEntity:withContext:error:completionBlock:) atIndex:4];
                    
                    testParseReturnBlock(@[testParseObject], nil);
                    NSManagedContextPerformBlockHandler testMocBlockHandler = testMocSpy.argument;
                    testMocBlockHandler();
                    NSManagedContextPerformBlockHandler testChildMocBlockHandler = testChildMocSpy.argument;
                    testChildMocBlockHandler();
                    
                    [testEntity stub:@selector(valueForKey:) andReturn:@"TestEntityObjectID" withArguments:@"objectID"];
                    [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forFetchRequest:fetchedObjectIDs:) withArguments:testManagedObjectContext, theValue(YES), fetchRequest, @[@"TestEntityObjectID"]];
                    
                    PFInsertUpdateResponseBlock blockToRun = callbackSpy.argument;
                    blockToRun(@[testEntity], @[testEntity]);
                });
            });
        });
        
        context(@"-- Communication with Backing Store --", ^{
            beforeEach(^{
                [testEntity stub:@selector(valueForKey:) andReturn:@"TestParseObjectID" withArguments:kPFIncrementalStoreResourceIdentifierAttributeName];
                [testBackingManagedObjectContext stub:@selector(executeFetchRequest:error:) andReturn:@[testEntity]];
                
                [testQuery stub:@selector(findObjectsInBackgroundWithBlock:)];
            });
            
            it(@"should return an array of NSManagedObjects", ^{
                id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
                [[output should] beKindOfClass:[NSArray class]];
                [[[output objectAtIndex:0] should] beKindOfClass:[NSManagedObject class]];
            });
            
            it(@"returned NSManagedObjects should be faulted", ^{
                id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
                [[output should] beKindOfClass:[NSArray class]];
                NSManagedObject *firstObject = [output objectAtIndex:0];
                [[theValue([firstObject isFault]) should] equal:theValue(YES)];
            });
        });
    });
    
    context(@"when the request type is NSManagedObjectIDResultType", ^{
        beforeEach(^{
            fetchRequest = FetchRequestWithRequestResultTypeAndEntityDescription(NSManagedObjectIDResultType, testEntityDescription);
            
            [testEntity stub:@selector(valueForKey:) andReturn:@"TestParseObjectID" withArguments:kPFIncrementalStoreResourceIdentifierAttributeName];
            [testBackingManagedObjectContext stub:@selector(executeFetchRequest:error:) andReturn:@[testEntity]];
            
            [testQuery stub:@selector(findObjectsInBackgroundWithBlock:)];
        });
        
        it(@"should return an array of NSManagedObjectIDs", ^{
            id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
            [[output should] beKindOfClass:[NSArray class]];
            [[[output objectAtIndex:0] should] beKindOfClass:[NSManagedObjectID class]];
        });
    });
    
    context(@"when the request type is NSDictionaryResultType", ^{
        beforeEach(^{
            fetchRequest = FetchRequestWithRequestResultTypeAndEntityDescription(NSDictionaryResultType, testEntityDescription);
            
            [testEntity stub:@selector(valueForKey:) andReturn:@"TestParseObjectID" withArguments:kPFIncrementalStoreResourceIdentifierAttributeName];
            [testBackingManagedObjectContext stub:@selector(executeFetchRequest:error:) andReturn:@[testEntity]];
            
            [testQuery stub:@selector(findObjectsInBackgroundWithBlock:)];
        });
        
        it(@"should return an array of NSDictionaries", ^{
            id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
            [[output should] beKindOfClass:[NSArray class]];
            [[[output objectAtIndex:0] should] equal:testEntity];
        });
    });
    
    context(@"when the request type is NSCountResultType", ^{
        beforeEach(^{
            fetchRequest = FetchRequestWithRequestResultTypeAndEntityDescription(NSCountResultType, testEntityDescription);
            
            [testEntity stub:@selector(valueForKey:) andReturn:@"TestParseObjectID" withArguments:kPFIncrementalStoreResourceIdentifierAttributeName];
            [testBackingManagedObjectContext stub:@selector(executeFetchRequest:error:) andReturn:@[testEntity]];
            
            [testQuery stub:@selector(findObjectsInBackgroundWithBlock:)];
        });
        
        it(@"should return an array with one NSNumber value", ^{
            id output = [testIncrementalStore executeFetchRequest:fetchRequest withContext:testManagedObjectContext error:nil];
            [[output should] beKindOfClass:[NSArray class]];
            [[output should] haveCountOf:1];
            [[output should] equal:@[[NSNumber numberWithInt:1]]];
        });
    });
});

SPEC_END