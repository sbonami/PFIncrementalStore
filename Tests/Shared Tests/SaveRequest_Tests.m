//
//  SaveRequest_Tests.m
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

SPEC_BEGIN(SaveRequest_Tests)
__block NSSaveChangesRequest *saveChangesRequest = nil;
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
    
    saveChangesRequest = [[NSSaveChangesRequest alloc] init];
});

describe(@"executeRequest:withContext:error:", ^{
    it(@"should call executeSaveChangesRequest:withContext:error: if the request type is NSFetchRequestType", ^{
        [[testIncrementalStore should] receive:@selector(executeSaveChangesRequest:withContext:error:) withArguments:saveChangesRequest, testManagedObjectContext, nil];
        
        [testIncrementalStore executeRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
});

describe(@"executeSaveChangesRequest:withContext:error:", ^{
    context(@"with inserted objects", ^{
        context(@"when the parse query fails", ^{
            pending(@"should notify user that save is completed while sending no ids", ^{});
        });
        
        context(@"when the parse query succeeds", ^{
            pending(@"should insert new objects into backing store", ^{});
            
            pending(@"should notify user that save is completed while sending object ids", ^{});
        });
    });
    
    context(@"with updated objects", ^{
        context(@"when the parse query fails", ^{
            pending(@"should notify user that save is completed while sending no ids", ^{});
        });
        
        context(@"when the parse query succeeds", ^{
            pending(@"should insert new objects into backing store", ^{});
            
            pending(@"should notify user that save is completed while sending object ids", ^{});
        });
    });
    
    context(@"with deleted objects", ^{
        context(@"when the parse query fails", ^{
            pending(@"should notify user that save is completed while sending no ids", ^{});
        });
        
        context(@"when the parse query succeeds", ^{
            pending(@"should insert new objects into backing store", ^{});
            
            pending(@"should notify user that save is completed while sending object ids", ^{});
        });
    });
});


SPEC_END