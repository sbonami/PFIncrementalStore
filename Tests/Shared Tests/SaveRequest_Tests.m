//
//  SaveRequest_Tests.m
//  Shared Tests
//
//  Created by Scott BonAmi on 12/17/13.
//
//

#import <Kiwi/Kiwi.h>
#import "PFIncrementalStore_PrivateMethods.h"

#ifdef TARGET_OS_IPHONE
#import <Parse-iOS-SDK/Parse.h>
#else
#import <Parse-OSX-SDK/ParseOSX.h>
#endif

#import "TestIncrementalStore.h"
#import "TestManagedObjectModel.h"

SPEC_BEGIN(SaveRequest_Tests)

__block NSSaveChangesRequest *saveChangesRequest = nil;
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
    
    saveChangesRequest = [[NSSaveChangesRequest alloc] init];
});

describe(@"executeRequest:withContext:error:", ^{
    it(@"should call executeSaveChangesRequest:withContext:error: if the request type is NSSaveChangesRequest", ^{
        [[testIncrementalStore should] receive:@selector(executeSaveChangesRequest:withContext:error:) withArguments:saveChangesRequest, testManagedObjectContext, nil];
        
        [testIncrementalStore executeRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
});

describe(@"executeSaveChangesRequest:withContext:error:", ^{
    __block PFObject *testObject = nil;
    
    beforeEach(^{
        // Stub Test Incremental Store's Backing MOC
        [testIncrementalStore stub:@selector(backingManagedObjectContext) andReturn:testBackingManagedObjectContext];
        
        // Setup and stub Test Entity
        testEntity = [NSManagedObject mockWithName:testEntityDescription.name];
        [testEntity stub:@selector(entity) andReturn:testEntityDescription];
        [testEntity stub:@selector(objectID) andReturn:@"TestEntityObjectID"];
        
        // Stub Parse
        testObject = [PFObject mock];
        [PFObject stub:@selector(objectWithClassName:) andReturn:testObject withArguments:testEntityDescription.name];
    });
    
    context(@"with inserted objects", ^{
        it(@"should call updateObject:fromRequest:inContext:error: when a Resource Identifier exists", ^{
            [saveChangesRequest stub:@selector(insertedObjects) andReturn:@[testEntity]];
            [testEntity stub:@selector(pf_resourceIdentifier) andReturn:@""];
            
            [[testIncrementalStore should] receive:@selector(updateObject:fromRequest:inContext:error:) andReturn:nil];
            
            [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
        });
        
        it(@"should call insertObject:fromRequest:inContext:error: when a Resource Identifier does not exist", ^{
            [saveChangesRequest stub:@selector(insertedObjects) andReturn:@[testEntity]];
            [testEntity stub:@selector(pf_resourceIdentifier) andReturn:nil];
            
            [[testIncrementalStore should] receive:@selector(insertObject:fromRequest:inContext:error:) andReturn:nil];
            
            [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
        });
    });
    
    context(@"with updated objects", ^{
        it(@"should call updateObject:fromRequest:inContext:error:", ^{
            [saveChangesRequest stub:@selector(updatedObjects) andReturn:@[testEntity]];
            
            [[testIncrementalStore should] receive:@selector(updateObject:fromRequest:inContext:error:)];
            
            [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
        });
    });
    
    context(@"with deleted objects", ^{
        it(@"should call deleteObject:fromRequest:inContext:error:", ^{
            [saveChangesRequest stub:@selector(deletedObjects) andReturn:@[testEntity]];
            
            [[testIncrementalStore should] receive:@selector(deleteObject:fromRequest:inContext:error:)];
            
            [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
        });
    });
});

describe(@"insertObject:fromRequest:inContext:error:", ^{
    __block PFObject *testObject = nil;
    
    beforeEach(^{
        // Stub Test Incremental Store's Backing MOC
        [testIncrementalStore stub:@selector(backingManagedObjectContext) andReturn:testBackingManagedObjectContext];
        
        // Setup and stub Test Entity
        testEntity = [NSManagedObject mockWithName:testEntityDescription.name];
        [testEntity stub:@selector(entity) andReturn:testEntityDescription];
        [testEntity stub:@selector(objectID) andReturn:@"TestEntityObjectID"];
        [testEntity stub:@selector(pf_resourceIdentifier) andReturn:nil];
        
        // Stub Parse
        testObject = [PFObject mock];
        [PFObject stub:@selector(objectWithClassName:) andReturn:testObject withArguments:testEntityDescription.name];
        
        [saveChangesRequest stub:@selector(insertedObjects) andReturn:@[testEntity]];
        
        [testObject stub:@selector(saveInBackgroundWithBlock:)];
        [testObject stub:@selector(setValuesFromManagedObject:withSaveCallbacks:) andReturn:nil];
    });
    
    it(@"should set the Parse Object values from the managed object", ^{
        [[testObject should] receive:@selector(setValuesFromManagedObject:withSaveCallbacks:)];
        
        [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
    
    
    it(@"should notify user that save is started for inserted object(s)", ^{
        [testObject stub:@selector(saveInBackgroundWithBlock:)];
        
        [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(NO), any(), @[@"TestEntityObjectID"]];
        
        [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
    
    context(@"-- Communication with Parse --", ^{
        __block PFBooleanResultBlock blockToRun = nil;
        
        beforeEach(^{
            KWCaptureSpy *spy = [testObject captureArgument:@selector(saveInBackgroundWithBlock:) atIndex:0];
            [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
            
            blockToRun = spy.argument;
        });
        
        it(@"should notify user that save is completed while sending inserted object ids", ^{
            [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(YES), any(), @[@"TestEntityObjectID"]];
            
            blockToRun(NO, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
        });
        
        context(@"when the parse query fails", ^{
            it(@"should reset related to-one objects", ^{
                // Stubs
                NSString *relationshipName = @"testRelationship";
                NSRelationshipDescription *testRelationship = [[NSRelationshipDescription alloc] init];
                NSRelationshipDescription *testInverseRelationship = [[NSRelationshipDescription alloc] init];
                [testRelationship stub:@selector(inverseRelationship) andReturn:testInverseRelationship];
                [testRelationship stub:@selector(isToMany) andReturn:theValue(NO)];
                [testRelationship stub:@selector(name) andReturn:relationshipName];
                
                [testEntityDescription stub:@selector(relationshipsByName) andReturn:@{relationshipName:testRelationship}];
                
                NSManagedObject *relatedObject = [NSManagedObject mock];
                [testEntity stub:@selector(valueForKey:) andReturn:relatedObject withArguments:relationshipName];
                
                // Expectations
                [[testManagedObjectContext should] receive:@selector(refreshObject:mergeChanges:) withArguments:relatedObject, theValue(NO)];
                
                blockToRun(NO, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
            });
            
            it(@"should reset related to-many objects", ^{
                // Stubs
                NSString *relationshipName = @"testRelationship";
                NSRelationshipDescription *testRelationship = [[NSRelationshipDescription alloc] init];
                NSRelationshipDescription *testInverseRelationship = [[NSRelationshipDescription alloc] init];
                [testRelationship stub:@selector(inverseRelationship) andReturn:testInverseRelationship];
                [testRelationship stub:@selector(isToMany) andReturn:theValue(YES)];
                [testRelationship stub:@selector(name) andReturn:relationshipName];
                
                [testEntityDescription stub:@selector(relationshipsByName) andReturn:@{relationshipName:testRelationship}];
                
                NSManagedObject *relatedObject1 = [NSManagedObject mock];
                NSManagedObject *relatedObject2 = [NSManagedObject mock];
                [testEntity stub:@selector(valueForKey:) andReturn:@[relatedObject1, relatedObject2] withArguments:relationshipName];
                
                // Expectations
                [[testManagedObjectContext should] receive:@selector(refreshObject:mergeChanges:) withArguments:relatedObject1, theValue(NO)];
                [[testManagedObjectContext should] receive:@selector(refreshObject:mergeChanges:) withArguments:relatedObject2, theValue(NO)];
                
                blockToRun(NO, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
            });
        });
        
        context(@"when the parse query succeeds", ^{
            __block NSString *parseObjectID = nil;
            
            beforeEach(^{
                parseObjectID = @"TestParseObjectID";
                [testObject stub:@selector(objectId) andReturn:parseObjectID];
                
                [testEntity stub:@selector(pf_setResourceIdentifier:) andReturn:nil withArguments:parseObjectID];
                [testEntity stub:@selector(setValuesFromParseObject:) andReturn:nil withArguments:testObject];
                
                [testManagedObjectContext stub:@selector(obtainPermanentIDsForObjects:error:)];
            });
            
            it(@"should update inserted object from parse object id, attributes, and relationships", ^{
                [[testEntity should] receive:@selector(pf_setResourceIdentifier:) withArguments:parseObjectID];
                [[testEntity should] receive:@selector(setValuesFromParseObject:) withArguments:testObject];
                
                blockToRun(YES, nil);
            });
            
            context(@"with the backing context", ^{
                it(@"should fetch existing temporary object ID", ^{
                    [[testIncrementalStore should] receive:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) withArguments:testEntityDescription, parseObjectID];
                    
                    blockToRun(YES, nil);
                });
                
                it(@"should fetch existing temporary object", ^{
                    NSManagedObjectID *managedObjectID = [NSManagedObjectID nullMock];
                    [testIncrementalStore stub:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:managedObjectID withArguments:testEntityDescription, parseObjectID];
                    
                    [[testBackingManagedObjectContext should] receive:@selector(existingObjectWithID:error:) withArguments:managedObjectID, any()];
                    
                    blockToRun(YES, nil);
                });
                
                it(@"should create new object when temporary object does not exist", ^{
                    [testIncrementalStore stub:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:nil withArguments:testEntityDescription, parseObjectID];
                    
                    NSManagedObject *returnedObject = [NSManagedObject nullMock];
                    NSManagedObjectContext *testReturnedObjectContext = [NSManagedObjectContext nullMock];
                    [returnedObject stub:@selector(managedObjectContext) andReturn:testReturnedObjectContext];
                    
                    [[NSEntityDescription should] receive:@selector(insertNewObjectForEntityForName:inManagedObjectContext:) andReturn:returnedObject withArguments:testEntityDescription.name, testBackingManagedObjectContext];
                    [[testReturnedObjectContext should] receive:@selector(obtainPermanentIDsForObjects:error:) withArguments:@[returnedObject], any()];
                    
                    blockToRun(YES, nil);
                });
                
                it(@"should update backing object with resource identifier", ^{
                    NSManagedObject *returnedObject = [NSManagedObject nullMock];
                    [NSEntityDescription stub:@selector(insertNewObjectForEntityForName:inManagedObjectContext:) andReturn:returnedObject withArguments:testEntityDescription.name, any()];
                    
                    [[returnedObject should] receive:@selector(setValue:forKey:) withArguments:parseObjectID, kPFIncrementalStoreResourceIdentifierAttributeName];
                    
                    blockToRun(YES, nil);
                });
                
                it(@"should update backing object with attributes and relationships from inserted object", ^{
                    NSManagedObject *returnedObject = [NSManagedObject nullMock];
                    [NSEntityDescription stub:@selector(insertNewObjectForEntityForName:inManagedObjectContext:) andReturn:returnedObject withArguments:testEntityDescription.name, any()];
                    
                    [[testIncrementalStore should] receive:@selector(updateBackingObject:withAttributeAndRelationshipValuesFromManagedObject:) withArguments:returnedObject, testEntity];
                    
                    blockToRun(YES, nil);
                });
                
                it(@"should save backing context", ^{
                    [[testBackingManagedObjectContext should] receive:@selector(save:)];
                    
                    blockToRun(YES, nil);
                });
            });
            
            context(@"with the test context", ^{
                it(@"should replace temporary objectID with permanent objectID", ^{
                    [[testManagedObjectContext should] receive:@selector(obtainPermanentIDsForObjects:error:)];
                    
                    blockToRun(YES, nil);
                });
                
                it(@"should refresh inserted object in context", ^{
                    [[testManagedObjectContext should] receive:@selector(refreshObject:mergeChanges:) withArguments:testEntity, theValue(NO)];
                    
                    blockToRun(YES, nil);
                });
            });
        });
    });
});

describe(@"updateObject:fromRequest:inContext:error:", ^{
    __block PFQuery *testQuery = nil;
    __block NSManagedObjectID *testManagedObjectID = nil;
    __block PFObject *testObject = nil;
    
    beforeEach(^{
        // Stub Test Incremental Store's Backing MOC
        [testIncrementalStore stub:@selector(backingManagedObjectContext) andReturn:testBackingManagedObjectContext];
        
        // Setup and stub Test Entity
        testEntity = [NSManagedObject mockWithName:testEntityDescription.name];
        [testEntity stub:@selector(entity) andReturn:testEntityDescription];
        [testEntity stub:@selector(objectID) andReturn:@"TestEntityObjectID"];
        
        // Stub Parse
        testObject = [PFObject mock];
        [PFObject stub:@selector(objectWithClassName:) andReturn:testObject withArguments:testEntityDescription.name];
        
        [saveChangesRequest stub:@selector(updatedObjects) andReturn:@[testEntity]];
        
        testManagedObjectID = [NSManagedObjectID nullMock];
        
        // Stub Parse
        testQuery = [PFQuery mock];
        [PFQuery stub:@selector(queryWithClassName:) andReturn:testQuery withArguments:testEntityDescription.name];
        [testQuery stub:@selector(getObjectInBackgroundWithId:block:) andReturn:nil];
    });
    
    it(@"should fetch backing object ID from updated object's resource identifier", ^{
        [testEntity stub:@selector(objectID) andReturn:testManagedObjectID];
        [testEntity stub:@selector(pf_resourceIdentifier) andReturn:@"TestParseObjectID"];
        
        [testIncrementalStore stub:@selector(referenceObjectForObjectID:) andReturn:@"TestParseObjectID" withArguments:testManagedObjectID];
        
        [[testIncrementalStore should] receive:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:nil withArguments:testEntityDescription, @"TestParseObjectID"];
        
        [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
    
    it(@"should query parse for the object by it's parse object ID", ^{
        [testEntity stub:@selector(objectID) andReturn:testManagedObjectID];
        [testEntity stub:@selector(pf_resourceIdentifier) andReturn:@"TestParseObjectID"];
        [testIncrementalStore stub:@selector(referenceObjectForObjectID:) andReturn:@"TestParseObjectID" withArguments:testManagedObjectID];
        [testIncrementalStore stub:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:testManagedObjectID];
        
        [[testQuery should] receive:@selector(getObjectInBackgroundWithId:block:) andReturn:nil withArguments:@"TestParseObjectID", any()];
        
        [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
    
    it(@"should notify user that save is started for updated object(s)", ^{
        [testEntity stub:@selector(objectID) andReturn:testManagedObjectID];
        [testEntity stub:@selector(pf_resourceIdentifier) andReturn:@"TestParseObjectID"];
        [testIncrementalStore stub:@selector(referenceObjectForObjectID:) andReturn:@"TestParseObjectID" withArguments:testManagedObjectID];
        [testIncrementalStore stub:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:testManagedObjectID];
        [testQuery stub:@selector(getObjectInBackgroundWithId:block:)];
        
        [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(NO), any(), @[testManagedObjectID]];
        
        [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
    
    context(@"-- Communication with Parse --", ^{
        __block PFObjectResultBlock fetchBlockToRun = nil;
        
        beforeEach(^{
            [testEntity stub:@selector(objectID) andReturn:testManagedObjectID];
            [testEntity stub:@selector(pf_resourceIdentifier) andReturn:@"TestParseObjectID"];
            [testIncrementalStore stub:@selector(referenceObjectForObjectID:) andReturn:@"TestParseObjectID" withArguments:testManagedObjectID];
            [testIncrementalStore stub:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:testManagedObjectID];
            
            KWCaptureSpy *spy = [testQuery captureArgument:@selector(getObjectInBackgroundWithId:block:) atIndex:1];
            [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
            
            fetchBlockToRun = spy.argument;
        });
        
        context(@"for the object fetch result", ^{
            context(@"when the parse fetch query fails", ^{
                it(@"should notify user that updated failed while sending ids", ^{
                    [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(YES), any(), @[testManagedObjectID]];
                    
                    fetchBlockToRun(nil, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
                });
            });
            
            context(@"when the parse fetch query succeeds", ^{
                it(@"should update the fetched object with the values from the updated object", ^{
                    [testObject stub:@selector(saveInBackgroundWithBlock:)];
                    
                    [[testObject should] receive:@selector(setValuesFromManagedObject:withSaveCallbacks:) withArguments:testEntity, nil];
                    
                    fetchBlockToRun(testObject, nil);
                });
                
                it(@"should save the parse object", ^{
                    [testObject stub:@selector(setValuesFromManagedObject:withSaveCallbacks:)];
                    
                    [[testObject should] receive:@selector(saveInBackgroundWithBlock:)];
                    
                    fetchBlockToRun(testObject, nil);
                });
                
                context(@"-- Communication with Parse --", ^{
                    __block PFBooleanResultBlock saveBlockToRun = nil;
                    
                    beforeEach(^{
                        [testObject stub:@selector(setValuesFromManagedObject:withSaveCallbacks:)];
                        
                        KWCaptureSpy *spy = [testObject captureArgument:@selector(saveInBackgroundWithBlock:) atIndex:0];
                        fetchBlockToRun(testObject, nil);
                        
                        saveBlockToRun = spy.argument;
                    });
                    
                    context(@"when the parse save fails", ^{
                        it(@"should refresh the updated object's MOC without refreshing changes", ^{
                            [[testManagedObjectContext should] receive:@selector(refreshObject:mergeChanges:) withArguments:testEntity, theValue(NO)];
                            
                            saveBlockToRun(NO, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
                        });
                        
                        it(@"should notify user that save is completed while sending ids", ^{
                            [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(YES), any(), @[testManagedObjectID]];
                            
                            saveBlockToRun(NO, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
                        });
                    });
                    
                    context(@"when the parse save succeeds", ^{
                        beforeEach(^{
                            [testObject stub:@selector(objectId) andReturn:@"TestParseObjectID"];
                        });
                        
                        it(@"should refresh the updated object's MOC while refreshing changes", ^{
                            [[testManagedObjectContext should] receive:@selector(refreshObject:mergeChanges:) withArguments:testEntity, theValue(YES)];
                            
                            saveBlockToRun(YES, nil);
                        });
                        
                        it(@"should notify user that save is completed while sending object ids", ^{
                            [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(YES), any(), @[testManagedObjectID]];
                            
                            saveBlockToRun(YES, nil);
                        });
                    });
                });
            });
        });
    });
});

describe(@"deleteObject:fromRequest:inContext:error:", ^{
    __block PFQuery *testQuery = nil;
    __block NSManagedObjectID *testManagedObjectID = nil;
    __block PFObject *testObject = nil;
    
    beforeEach(^{
        // Stub Test Incremental Store's Backing MOC
        [testIncrementalStore stub:@selector(backingManagedObjectContext) andReturn:testBackingManagedObjectContext];
        
        // Setup and stub Test Entity
        testEntity = [NSManagedObject mockWithName:testEntityDescription.name];
        [testEntity stub:@selector(entity) andReturn:testEntityDescription];
        [testEntity stub:@selector(objectID) andReturn:@"TestEntityObjectID"];
        
        // Stub Parse
        testObject = [PFObject mock];
        [PFObject stub:@selector(objectWithClassName:) andReturn:testObject withArguments:testEntityDescription.name];
    
        [saveChangesRequest stub:@selector(deletedObjects) andReturn:@[testEntity]];
        
        testManagedObjectID = [NSManagedObjectID nullMock];
        
        // Stub Parse
        testQuery = [PFQuery mock];
        [PFQuery stub:@selector(queryWithClassName:) andReturn:testQuery withArguments:testEntityDescription.name];
        [testQuery stub:@selector(getObjectInBackgroundWithId:block:) andReturn:nil];
    });
    
    it(@"should fetch backing object ID from deleted object's resource identifier", ^{
        [testEntity stub:@selector(objectID) andReturn:testManagedObjectID];
        [testEntity stub:@selector(pf_resourceIdentifier) andReturn:@"TestParseObjectID"];
        
        [testIncrementalStore stub:@selector(referenceObjectForObjectID:) andReturn:@"TestParseObjectID" withArguments:testManagedObjectID];
        
        [[testIncrementalStore should] receive:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:nil withArguments:testEntityDescription, @"TestParseObjectID"];
        
        [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
    
    it(@"should query parse for the object by it's parse object ID", ^{
        [testEntity stub:@selector(objectID) andReturn:testManagedObjectID];
        [testEntity stub:@selector(pf_resourceIdentifier) andReturn:@"TestParseObjectID"];
        [testIncrementalStore stub:@selector(referenceObjectForObjectID:) andReturn:@"TestParseObjectID" withArguments:testManagedObjectID];
        [testIncrementalStore stub:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:testManagedObjectID];
        
        [[testQuery should] receive:@selector(getObjectInBackgroundWithId:block:) andReturn:nil withArguments:@"TestParseObjectID", any()];
        
        [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
    
    it(@"should notify user that save is started for deleted object(s)", ^{
        [testEntity stub:@selector(objectID) andReturn:testManagedObjectID];
        [testEntity stub:@selector(pf_resourceIdentifier) andReturn:@"TestParseObjectID"];
        [testIncrementalStore stub:@selector(referenceObjectForObjectID:) andReturn:@"TestParseObjectID" withArguments:testManagedObjectID];
        [testIncrementalStore stub:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:testManagedObjectID];
        [testQuery stub:@selector(getObjectInBackgroundWithId:block:)];
        
        [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(NO), any(), @[testManagedObjectID]];
        
        [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
    });
    
    context(@"-- Communication with Parse --", ^{
        __block PFObjectResultBlock fetchBlockToRun = nil;
        
        beforeEach(^{
            [testEntity stub:@selector(objectID) andReturn:testManagedObjectID];
            [testEntity stub:@selector(pf_resourceIdentifier) andReturn:@"TestParseObjectID"];
            [testIncrementalStore stub:@selector(referenceObjectForObjectID:) andReturn:@"TestParseObjectID" withArguments:testManagedObjectID];
            [testIncrementalStore stub:@selector(managedObjectIDForBackingObjectForEntity:withParseObjectId:) andReturn:testManagedObjectID];
            
            KWCaptureSpy *spy = [testQuery captureArgument:@selector(getObjectInBackgroundWithId:block:) atIndex:1];
            [testIncrementalStore executeSaveChangesRequest:saveChangesRequest withContext:testManagedObjectContext error:nil];
            
            fetchBlockToRun = spy.argument;
        });
        
        context(@"for the object fetch result", ^{
            context(@"when the parse fetch query fails", ^{
                it(@"should notify user that delete failed while sending ids", ^{
                    [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(YES), any(), @[testManagedObjectID]];
                    
                    fetchBlockToRun(nil, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
                });
            });
            
            context(@"when the parse fetch query succeeds", ^{
                it(@"should delete the parse object", ^{
                    [[testObject should] receive:@selector(deleteInBackgroundWithBlock:)];
                    
                    fetchBlockToRun(testObject, nil);
                });
                
                context(@"-- Communication with Parse --", ^{
                    __block PFBooleanResultBlock deleteBlockToRun = nil;
                    
                    beforeEach(^{
                        KWCaptureSpy *spy = [testObject captureArgument:@selector(deleteInBackgroundWithBlock:) atIndex:0];
                        fetchBlockToRun(testObject, nil);
                        
                        deleteBlockToRun = spy.argument;
                    });
                    
                    context(@"when the parse save fails", ^{
                        it(@"should notify user that delete is completed while sending ids", ^{
                            [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(YES), any(), @[testManagedObjectID]];
                            
                            deleteBlockToRun(NO, [NSError errorWithDomain:@"" code:0 userInfo:nil]);
                        });
                    });
                    
                    context(@"when the parse delete succeeds", ^{
                        __block NSManagedObject *testBackingObject = nil;
                        
                        beforeEach(^{
                            testBackingObject = [NSManagedObject nullMock];
                            
                            [testObject stub:@selector(objectId) andReturn:@"TestParseObjectID"];
                        });
                        
                        it(@"should fetch backing object from backing MOC", ^{
                            [[testBackingManagedObjectContext should] receive:@selector(existingObjectWithID:error:) andReturn:testBackingObject withArguments:testManagedObjectID, any()];
                            
                            deleteBlockToRun(YES, nil);
                        });
                        
                        it(@"should remove the deleted object from the backing MOC and save", ^{
                            [testBackingManagedObjectContext stub:@selector(existingObjectWithID:error:) andReturn:testBackingObject withArguments:testManagedObjectID, any()];
                            
                            [[testBackingManagedObjectContext should] receive:@selector(deleteObject:) withArguments:testBackingObject, theValue(YES)];
                            [[testBackingManagedObjectContext should] receive:@selector(save:)];
                            
                            deleteBlockToRun(YES, nil);
                        });
                        
                        it(@"should notify user that delete is completed while sending object ids", ^{
                            [testBackingManagedObjectContext stub:@selector(existingObjectWithID:error:) andReturn:testBackingObject withArguments:testManagedObjectID, any()];
                            
                            [[testIncrementalStore should] receive:@selector(notifyManagedObjectContext:requestIsCompleted:forSaveChangesRequest:changedObjectIDs:) withArguments:testManagedObjectContext, theValue(YES), any(), @[testManagedObjectID]];
                            
                            deleteBlockToRun(YES, nil);
                        });
                    });
                });
            });
        });
    });
});

SPEC_END