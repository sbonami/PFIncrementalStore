// PFIncrementalStore.m
//
// Copyright (c) 2013 Scott BonAmi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Parse-iOS-SDK/Parse.h>
#import "PFIncrementalStore.h"
#import <objc/runtime.h>

#pragma mark - Resource Identifier Methods

static NSString * const kPFIncrementalStoreErrorDomain = @"PFIncrementalStoreErrorDomain";
static NSString * const kPFIncrementalStoreUnimplementedMethodException = @"PFIncrementalStoreUnimplementedMethodException";
NSString * const PFIncrementalStoreContextWillFetchRemoteValues = @"PFIncrementalStoreContextWillFetchRemoteValues";
NSString * const PFIncrementalStoreContextWillSaveRemoteValues = @"PFIncrementalStoreContextWillSaveRemoteValues";
NSString * const PFIncrementalStoreContextDidFetchRemoteValues = @"PFIncrementalStoreContextDidFetchRemoteValues";
NSString * const PFIncrementalStoreContextDidSaveRemoteValues = @"PFIncrementalStoreContextDidSaveRemoteValues";
NSString * const PFIncrementalStoreContextWillFetchNewValuesForObject = @"PFIncrementalStoreContextWillFetchNewValuesForObject";
NSString * const PFIncrementalStoreContextDidFetchNewValuesForObject = @"PFIncrementalStoreContextDidFetchNewValuesForObject";
NSString * const PFIncrementalStoreContextWillFetchNewValuesForRelationship = @"PFIncrementalStoreContextWillFetchNewValuesForRelationship";
NSString * const PFIncrementalStoreContextDidFetchNewValuesForRelationship = @"PFIncrementalStoreContextDidFetchNewValuesForRelationship";
NSString * const PFIncrementalStoreManagedObjectEntityParseClassName = @"ParseClassName";
NSString * const PFIncrementalStoreRequestOperationsKey = @"PFIncrementalStoreRequestOperations";
NSString * const PFIncrementalStoreFetchedObjectIDsKey = @"PFIncrementalStoreFetchedObjectIDs";
NSString * const PFIncrementalStoreFaultingObjectIDKey = @"PFIncrementalStoreFaultingObjectID";
NSString * const PFIncrementalStoreFaultingRelationshipKey = @"PFIncrementalStoreFaultingRelationship";
NSString * const PFIncrementalStorePersistentStoreRequestKey = @"PFIncrementalStorePersistentStoreRequest";

#pragma mark - Block Definitions Methods

typedef void (^PFInsertUpdateResponseBlock)(NSArray *managedObjects, NSArray *backingObjects);

#pragma mark - Resource Identifier Methods

static char kPFResourceIdentifierObjectKey;

NSString * const kPFReferenceObjectPrefix = @"__pf_";
NSString * const kPFIncrementalStoreLastModifiedAttributeName = @"__pf_lastModified";
NSString * const kPFIncrementalStoreResourceIdentifierAttributeName = @"__pf_resourceIdentifier";

inline NSString * PFReferenceObjectFromResourceIdentifier(NSString *resourceIdentifier) {
    if (!resourceIdentifier) {
        return nil;
    }
    
    return [kPFReferenceObjectPrefix stringByAppendingString:resourceIdentifier];
}

inline NSString * PFResourceIdentifierFromReferenceObject(id referenceObject) {
    if (!referenceObject) {
        return nil;
    }
    
    NSString *string = [referenceObject description];
    return [string hasPrefix:kPFReferenceObjectPrefix] ? [string substringFromIndex:[kPFReferenceObjectPrefix length]] : string;
}

static inline void PFSaveManagedObjectContextOrThrowInternalConsistencyException(NSManagedObjectContext *managedObjectContext) {
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[error localizedFailureReason] userInfo:[NSDictionary dictionaryWithObject:error forKey:NSUnderlyingErrorKey]];
    }
}

@implementation NSEntityDescription (_PFIncrementalStore)

-(NSString *)parseClassNameFromSubclass {
    NSString *parseClassNameFromSubclass = [self.userInfo objectForKey:PFIncrementalStoreManagedObjectEntityParseClassName];
    return (parseClassNameFromSubclass) ? parseClassNameFromSubclass : self.name ;
}

-(NSString *)parseQueryClassName {
    if ([[self.parseClassNameFromSubclass substringWithRange:NSMakeRange(0, 2)] isEqual: @"PF"]) {
        return [self.parseClassNameFromSubclass stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@"_"];
    }
    return self.parseClassNameFromSubclass;
}

@end

@implementation NSManagedObject (_PFIncrementalStore)
@dynamic pf_resourceIdentifier;

-(NSString *)parseClassName {
    return self.entity.parseClassNameFromSubclass;
}

-(NSString *)parseQueryClassName {
    return self.entity.parseQueryClassName;
}

- (NSString *)pf_resourceIdentifier {
    NSString *identifier = (NSString *)objc_getAssociatedObject(self, &kPFResourceIdentifierObjectKey);
    
    if (!identifier) {
        if ([self.objectID.persistentStore isKindOfClass:[PFIncrementalStore class]]) {
            id referenceObject = [(PFIncrementalStore *)self.objectID.persistentStore referenceObjectForObjectID:self.objectID];
            if ([referenceObject isKindOfClass:[NSString class]]) {
                return PFResourceIdentifierFromReferenceObject(referenceObject);
            }
        }
    }
    
    return identifier;
}

- (void)pf_setResourceIdentifier:(NSString *)resourceIdentifier {
    objc_setAssociatedObject(self, &kPFResourceIdentifierObjectKey, resourceIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setValuesFromParseObject:(PFObject *)parseObject {
    NSMutableDictionary *mutableAttributeValues = [self.entity.attributesByName mutableCopy];
    [mutableAttributeValues removeObjectForKey:kPFIncrementalStoreResourceIdentifierAttributeName];
    [mutableAttributeValues removeObjectForKey:kPFIncrementalStoreLastModifiedAttributeName];
    for (NSString *attributeName in mutableAttributeValues) {
        id parseValue = [parseObject objectForKey:attributeName];
        if ([parseValue isKindOfClass:[PFFile class]]) {
            [self setPFFile:parseValue forKey:attributeName];
        } else {
            [self setValue:parseValue forKey:attributeName];
        }
    }
}

- (void)setPFFile:(PFFile *)file forKey:(NSString *)key {
    [self setValue:[file getData] forKey:key];
}

@end

@implementation NSMutableDictionary (_PFIncrementalStore)

- (void)setPFFile:(PFFile *)file forKey:(NSString *)key {
    [self setObject:[file getData] forKey:key];
}

@end

#pragma mark - Parse Object

@implementation PFObject (_PFIncrementalStore)

- (void)setValuesFromManagedObject:(NSManagedObject *)managedObject withSaveCallbacks:(NSMutableDictionary **)saveCallbacks {
    NSMutableDictionary *mutableAttributeValues = [managedObject.entity.attributesByName mutableCopy];
    [mutableAttributeValues removeObjectForKey:kPFIncrementalStoreResourceIdentifierAttributeName];
    [mutableAttributeValues removeObjectForKey:kPFIncrementalStoreLastModifiedAttributeName];
    for (NSString *attributeName in mutableAttributeValues) {
        id value = [managedObject valueForKey:attributeName];
        if (value) {
            [self setObject:value forKey:attributeName];
        } else {
            [self removeObjectForKey:attributeName];
        }
    }
    
    for (NSString *relationshipName in managedObject.entity.relationshipsByName) {
        __block NSRelationshipDescription *relationship = [managedObject.entity.relationshipsByName objectForKey:relationshipName];
        id value = [managedObject valueForKey:relationshipName];
        if (value) {
            if (!relationship.isToMany) {
                NSManagedObject *relatedManagedObject = (NSManagedObject *)value;
                if (relatedManagedObject.pf_resourceIdentifier) {
                    PFQuery *query = [PFQuery queryWithClassName:relationship.destinationEntity.parseQueryClassName];
                    PFObject *relatedParseObject = [query getObjectWithId:PFResourceIdentifierFromReferenceObject(relatedManagedObject.pf_resourceIdentifier)];
                    [self setObject:relatedParseObject forKey:relationshipName];
                } else {
                    __block PFObject *blockObject = self;
                    PFObjectResultBlock connectRelationship = ^(PFObject *object, NSError *error) {
                        [blockObject setObject:object forKey:relationship.name];
                        [blockObject saveInBackground];
                    };
                    
                    if (saveCallbacks) {
                        if (![*saveCallbacks objectForKey:relatedManagedObject.objectID]) {
                            [*saveCallbacks setObject:[NSMutableArray array]
                                               forKey:relatedManagedObject.objectID];
                        }
                        [[*saveCallbacks objectForKey:relatedManagedObject.objectID] addObject:connectRelationship];
                    }
                }
            }
        } else {
            // No value, need to unset the relationship value
            if (!relationship.isToMany) {
                [self removeObjectForKey:relationshipName];
            }
            
        }
    }
}

- (id)relatedObjectsForRelationship:(NSRelationshipDescription *)relationship {
    id relatedObjects = nil;
    if (relationship.isToMany) {
        PFQuery *query = [PFQuery queryWithClassName:relationship.destinationEntity.parseQueryClassName];
        [query whereKey:relationship.inverseRelationship.name equalTo:self];
        relatedObjects = [query findObjects];
    } else {
        relatedObjects = [self objectForKey:relationship.name];
    }
    
    return relatedObjects;
}

@end

#pragma mark - PFIncrementalStore implementation

@implementation PFIncrementalStore {
@private
    NSMutableDictionary *_parseSaveCallbacks;
    NSCache *_backingObjectIDByObjectID;
    NSMutableDictionary *_registeredObjectIDsByEntityNameAndNestedResourceIdentifier;
    NSPersistentStoreCoordinator *_backingPersistentStoreCoordinator;
    NSManagedObjectContext *_backingManagedObjectContext;
}
@synthesize backingPersistentStoreCoordinator = _backingPersistentStoreCoordinator;

#pragma mark - Required subclassed methods

+ (NSString *)type {
    @throw([NSException exceptionWithName:kPFIncrementalStoreUnimplementedMethodException reason:NSLocalizedString(@"Unimplemented method: +type. Must be overridden in a subclass", nil) userInfo:nil]);
}

+ (NSManagedObjectModel *)model {
    @throw([NSException exceptionWithName:kPFIncrementalStoreUnimplementedMethodException reason:NSLocalizedString(@"Unimplemented method: +model. Must be overridden in a subclass", nil) userInfo:nil]);
}

#pragma mark - Fetch Request methods

- (id)executeFetchRequest:(NSFetchRequest *)fetchRequest
              withContext:(NSManagedObjectContext *)context
                    error:(NSError *__autoreleasing *)error {
    
    PFQuery *query = [PFQuery queryWithClassName:fetchRequest.entity.parseQueryClassName predicate:fetchRequest.predicate];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error: %@, %@", query, error);
            [self notifyManagedObjectContext:context requestIsCompleted:YES forFetchRequest:fetchRequest fetchedObjectIDs:nil];
        } else {
            [context performBlock:^{
                NSManagedObjectContext *childContext = [self privateChildContextForParentContext:context];
                
                [childContext performBlock:^{
                    [self insertOrUpdateObjects:objects ofEntity:fetchRequest.entity withContext:childContext error:nil completionBlock:^(NSArray *managedObjects, NSArray *backingObjects) {
                        NSSet *childObjects = [childContext registeredObjects];
                        PFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext);
                        
                        NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
                        [backingContext performBlockAndWait:^{
                            PFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext);
                        }];
                        
                        [context performBlockAndWait:^{
                            for (NSManagedObject *childObject in childObjects) {
                                NSManagedObject *parentObject = [context objectWithID:childObject.objectID];
                                [context refreshObject:parentObject mergeChanges:YES];
                            }
                            
                            PFSaveManagedObjectContextOrThrowInternalConsistencyException(context);
                        }];
                        
                        [self notifyManagedObjectContext:context requestIsCompleted:YES forFetchRequest:fetchRequest fetchedObjectIDs:[managedObjects valueForKeyPath:@"objectID"]];
                    }];
                }];
            }];
        }
    }];
    
    [self notifyManagedObjectContext:context requestIsCompleted:NO forFetchRequest:fetchRequest fetchedObjectIDs:nil];
    
    switch (fetchRequest.resultType) {
            
        case NSManagedObjectResultType: {
            return [self objectResultOfFetchRequest:fetchRequest withContext:context error:error];
        }
        case NSManagedObjectIDResultType: {
            return [self objectIDResultOfFetchRequest:fetchRequest withContext:context error:error];
        }
        case NSDictionaryResultType: {
            return [self dictionaryResultOfFetchRequest:fetchRequest withContext:context error:error];
        }
        case NSCountResultType: {
            return [self countResultOfFetchRequest:fetchRequest withContext:context error:error];
        }
    }
    
    NSMutableDictionary *mutableUserInfo = [NSMutableDictionary dictionary];
    [mutableUserInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Unsupported NSFetchRequestResultType, %d", nil), fetchRequest.resultType] forKey:NSLocalizedDescriptionKey];
    if (error) {
        *error = [[NSError alloc] initWithDomain:kPFIncrementalStoreErrorDomain code:0 userInfo:mutableUserInfo];
    }
    
    return nil;
}

-(NSArray *)objectResultOfFetchRequest:(NSFetchRequest *)fetchRequest
                           withContext:(NSManagedObjectContext *)context
                                 error:(NSError *__autoreleasing *)error {
    
    NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
    NSFetchRequest *backingFetchRequest = [fetchRequest copy];
    backingFetchRequest.entity = [NSEntityDescription entityForName:fetchRequest.entity.name inManagedObjectContext:backingContext];
    backingFetchRequest.resultType = NSDictionaryResultType;
    backingFetchRequest.propertiesToFetch = [NSArray arrayWithObject:kPFIncrementalStoreResourceIdentifierAttributeName];
    NSArray *results = [backingContext executeFetchRequest:backingFetchRequest error:error];
    
    NSMutableArray *mutableObjects = [NSMutableArray arrayWithCapacity:[results count]];
    for (NSString *resourceIdentifier in [results valueForKeyPath:kPFIncrementalStoreResourceIdentifierAttributeName]) {
        NSManagedObjectID *objectID = [self managedObjectIDForEntity:fetchRequest.entity withParseObjectId:resourceIdentifier];
        NSManagedObject *object = [context objectWithID:objectID];
        object.pf_resourceIdentifier = resourceIdentifier;
        [mutableObjects addObject:object];
    }
    
    return mutableObjects;
}

-(NSArray *)objectIDResultOfFetchRequest:(NSFetchRequest *)fetchRequest
                             withContext:(NSManagedObjectContext *)context
                                   error:(NSError *__autoreleasing *)error {
    
    NSMutableArray *managedObjectIDs = [NSMutableArray array];
    
    for (NSManagedObject *object in [self objectResultOfFetchRequest:fetchRequest withContext:context error:error]) {
        [managedObjectIDs addObject:object.objectID];
    }
    
    return managedObjectIDs;
}

-(NSArray *)dictionaryResultOfFetchRequest:(NSFetchRequest *)fetchRequest
                               withContext:(NSManagedObjectContext *)context
                                     error:(NSError *__autoreleasing *)error {
    
    NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
    NSFetchRequest *backingFetchRequest = [fetchRequest copy];
    backingFetchRequest.entity = [NSEntityDescription entityForName:fetchRequest.entityName inManagedObjectContext:backingContext];
    return [backingContext executeFetchRequest:backingFetchRequest error:error];
}

-(NSArray *)countResultOfFetchRequest:(NSFetchRequest *)fetchRequest
                          withContext:(NSManagedObjectContext *)context
                                error:(NSError *__autoreleasing *)error {
    
    NSUInteger count = [[self objectResultOfFetchRequest:fetchRequest withContext:context error:error] count];
    return @[[NSNumber numberWithInteger:count]];
}

#pragma mark - Save Request methods

- (NSMutableDictionary *)parseSaveCallbacks {
    if (_parseSaveCallbacks == nil) {
        _parseSaveCallbacks = [NSMutableDictionary dictionary];
    }
    return _parseSaveCallbacks;
}

- (void)addParseSaveCallbacks:(NSArray*)callbacks forObject:(NSManagedObjectID *)objectID {
    NSArray *saveCallbacks = [[self parseSaveCallbacks] objectForKey:objectID];
    if (saveCallbacks == nil) {
        saveCallbacks = [NSMutableArray arrayWithArray:callbacks];
    }
    [[self parseSaveCallbacks] setObject:saveCallbacks forKey:objectID];
}

- (id)executeSaveChangesRequest:(NSSaveChangesRequest *)saveChangesRequest
                    withContext:(NSManagedObjectContext *)context
                          error:(NSError *__autoreleasing *)error {
    
    // NSManagedObjectContext removes object references from an NSSaveChangesRequest as each object is saved, so create a copy of the original in order to send useful information in AFIncrementalStoreContextDidSaveRemoteValues notification.
    NSSaveChangesRequest *saveChangesRequestCopy = [[NSSaveChangesRequest alloc] initWithInsertedObjects:[saveChangesRequest.insertedObjects copy] updatedObjects:[saveChangesRequest.updatedObjects copy] deletedObjects:[saveChangesRequest.deletedObjects copy] lockedObjects:[saveChangesRequest.lockedObjects copy]];
    
    for (NSManagedObject *insertedObject in [saveChangesRequest insertedObjects]) {
        if (insertedObject.pf_resourceIdentifier) {
            [self updateObject:insertedObject fromRequest:saveChangesRequestCopy inContext:context error:error];
        } else {
            [self insertObject:insertedObject fromRequest:saveChangesRequestCopy inContext:context error:error];
        }
    }
    
    for (NSManagedObject *updatedObject in [saveChangesRequest updatedObjects]) {
        [self updateObject:updatedObject fromRequest:saveChangesRequestCopy inContext:context error:error];
    }
    
    for (NSManagedObject *deletedObject in [saveChangesRequest deletedObjects]) {
        [self deleteObject:deletedObject fromRequest:saveChangesRequestCopy inContext:context error:error];
    }
    
    return [NSArray array];
}

-(void)insertObject:(NSManagedObject *)insertedObject fromRequest:(NSSaveChangesRequest *)request inContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
    
    PFObject *object = [PFObject objectWithClassName:insertedObject.entity.parseQueryClassName];
    
    __block NSMutableDictionary *saveCallbacks = [NSMutableDictionary dictionary];
    [object setValuesFromManagedObject:insertedObject withSaveCallbacks:&saveCallbacks];
    for (NSManagedObjectID *relatedObjectID in saveCallbacks) {
        [self addParseSaveCallbacks:[saveCallbacks objectForKey:relatedObjectID] forObject:relatedObjectID];
    }
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            NSLog(@"Insert %@ %@",object, object.objectId);
            
            NSManagedObjectID *backingObjectID = [self managedObjectIDForBackingObjectForEntity:[insertedObject entity] withParseObjectId:object.objectId];
            insertedObject.pf_resourceIdentifier = object.objectId;
            [insertedObject setValuesFromParseObject:object];
            
            [backingContext performBlockAndWait:^{
                __block NSManagedObject *backingObject = nil;
                if (backingObjectID) {
                    [backingContext performBlockAndWait:^{
                        backingObject = [backingContext existingObjectWithID:backingObjectID error:nil];
                    }];
                }
                
                if (!backingObject) {
                    backingObject = [NSEntityDescription insertNewObjectForEntityForName:insertedObject.entity.name inManagedObjectContext:backingContext];
                    [backingObject.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:backingObject] error:nil];
                }
                
                [backingObject setValue:object.objectId forKey:kPFIncrementalStoreResourceIdentifierAttributeName];
                [self updateBackingObject:backingObject withAttributeAndRelationshipValuesFromManagedObject:insertedObject];
                [backingContext save:nil];
            }];
            
            [self performSaveCallbacksWithParseObject:object andManagedObjectID:insertedObject.objectID];
            
            [insertedObject willChangeValueForKey:@"objectID"];
            [context obtainPermanentIDsForObjects:[NSArray arrayWithObject:insertedObject] error:nil];
            [insertedObject didChangeValueForKey:@"objectID"];
            
            [context refreshObject:insertedObject mergeChanges:NO];
        } else {
            NSLog(@"Insert Error: %@", error);
            
            // Reset destination objects to prevent dangling relationships
            for (NSRelationshipDescription *relationship in [insertedObject.entity.relationshipsByName allValues]) {
                if (!relationship.inverseRelationship) {
                    continue;
                }
                
                id <NSFastEnumeration> destinationObjects = nil;
                if ([relationship isToMany]) {
                    destinationObjects = [insertedObject valueForKey:relationship.name];
                } else {
                    NSManagedObject *destinationObject = [insertedObject valueForKey:relationship.name];
                    if (destinationObject) {
                        destinationObjects = [NSArray arrayWithObject:destinationObject];
                    }
                }
                
                for (NSManagedObject *destinationObject in destinationObjects) {
                    [context refreshObject:destinationObject mergeChanges:NO];
                }
            }
        }
        
        [self notifyManagedObjectContext:context requestIsCompleted:YES forSaveChangesRequest:request changedObjectIDs:@[insertedObject.objectID]];
    }];
    
    [self notifyManagedObjectContext:context requestIsCompleted:NO forSaveChangesRequest:request changedObjectIDs:@[insertedObject.objectID]];
}

-(void)updateObject:(NSManagedObject *)updatedObject fromRequest:(NSSaveChangesRequest *)request inContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
    
    NSManagedObjectID *backingObjectID = [self managedObjectIDForBackingObjectForEntity:[updatedObject entity] withParseObjectId:PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:updatedObject.objectID])];
    
    PFQuery *query = [PFQuery queryWithClassName:updatedObject.entity.parseQueryClassName];
    [query getObjectInBackgroundWithId:updatedObject.pf_resourceIdentifier block:^(PFObject *object, NSError *error) {
        if (error) {
            NSLog(@"Fetch Before Update Error: %@",error);
            
            [self notifyManagedObjectContext:context requestIsCompleted:YES forSaveChangesRequest:request changedObjectIDs:@[updatedObject.objectID]];
        } else {
            [object setValuesFromManagedObject:updatedObject withSaveCallbacks:nil];
            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"Update %@ %@",object, object.objectId);
                    
                    [backingContext performBlockAndWait:^{
                        NSManagedObject *backingObject = [backingContext existingObjectWithID:backingObjectID error:nil];
                        [self updateBackingObject:backingObject withAttributeAndRelationshipValuesFromManagedObject:updatedObject];
                        [backingContext save:nil];
                    }];
                    
                    [context refreshObject:updatedObject mergeChanges:YES];
                } else {
                    NSLog(@"Update Error: %@", error);
                    [context refreshObject:updatedObject mergeChanges:NO];
                }
                
                [self notifyManagedObjectContext:context requestIsCompleted:YES forSaveChangesRequest:request changedObjectIDs:@[updatedObject.objectID]];
            }];
        }
    }];
    
    [self notifyManagedObjectContext:context requestIsCompleted:NO forSaveChangesRequest:request changedObjectIDs:@[updatedObject.objectID]];
}

-(void)deleteObject:(NSManagedObject *)deletedObject fromRequest:(NSSaveChangesRequest *)request inContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
    
    NSManagedObjectID *backingObjectID = [self managedObjectIDForBackingObjectForEntity:[deletedObject entity] withParseObjectId:PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:deletedObject.objectID])];
    
    PFQuery *query = [PFQuery queryWithClassName:deletedObject.entity.parseQueryClassName];
    [query getObjectInBackgroundWithId:deletedObject.pf_resourceIdentifier block:^(PFObject *object, NSError *error) {
        if (error) {
            NSLog(@"Fetch Before Delete Error: %@",error);
            
            [self notifyManagedObjectContext:context requestIsCompleted:YES forSaveChangesRequest:request changedObjectIDs:@[deletedObject.objectID]];
        } else {
            [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    NSLog(@"Delete %@ %@",object, object.objectId);
                    
                    [backingContext performBlockAndWait:^{
                        NSManagedObject *backingObject = [backingContext existingObjectWithID:backingObjectID error:nil];
                        if (backingObject) {
                            [backingContext deleteObject:backingObject];
                            [backingContext save:nil];
                        }
                    }];
                } else {
                    NSLog(@"Delete Error: %@", error);
                }
                
                [self notifyManagedObjectContext:context requestIsCompleted:YES forSaveChangesRequest:request changedObjectIDs:@[deletedObject.objectID]];
            }];
        }
    }];
    
    [self notifyManagedObjectContext:context requestIsCompleted:NO forSaveChangesRequest:request changedObjectIDs:@[deletedObject.objectID]];
}

-(void)performSaveCallbacksWithParseObject:(PFObject *)parseObject andManagedObjectID:(NSManagedObjectID *)managedObjectID {
    NSArray *saveCallbacks = [[self parseSaveCallbacks] objectForKey:managedObjectID];
    if (saveCallbacks != nil) {
        for (PFObjectResultBlock callback in saveCallbacks) {
            callback(parseObject, nil);
        }
        [[self parseSaveCallbacks] removeObjectForKey:managedObjectID];
    }
}

#pragma mark - NSIncrementalStore

- (BOOL)loadMetadata:(NSError *__autoreleasing *)error {
    if (!_backingObjectIDByObjectID) {
        NSMutableDictionary *mutableMetadata = [NSMutableDictionary dictionary];
        [mutableMetadata setValue:[[NSProcessInfo processInfo] globallyUniqueString] forKey:NSStoreUUIDKey];
        [mutableMetadata setValue:NSStringFromClass([self class]) forKey:NSStoreTypeKey];
        [self setMetadata:mutableMetadata];
        
        _backingObjectIDByObjectID = [[NSCache alloc] init];
        _registeredObjectIDsByEntityNameAndNestedResourceIdentifier = [[NSMutableDictionary alloc] init];
        
        NSManagedObjectModel *model = [self.persistentStoreCoordinator.managedObjectModel copy];
        for (NSEntityDescription *entity in model.entities) {
            // Don't add properties for sub-entities, as they already exist in the super-entity
            if ([entity superentity]) {
                continue;
            }
            
            NSAttributeDescription *resourceIdentifierProperty = [[NSAttributeDescription alloc] init];
            [resourceIdentifierProperty setName:kPFIncrementalStoreResourceIdentifierAttributeName];
            [resourceIdentifierProperty setAttributeType:NSStringAttributeType];
            [resourceIdentifierProperty setIndexed:YES];
            
            NSAttributeDescription *lastModifiedProperty = [[NSAttributeDescription alloc] init];
            [lastModifiedProperty setName:kPFIncrementalStoreLastModifiedAttributeName];
            [lastModifiedProperty setAttributeType:NSDateAttributeType];
            [lastModifiedProperty setIndexed:NO];
            
            [entity setProperties:[entity.properties arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:resourceIdentifierProperty, lastModifiedProperty, nil]]];
        }
        
        _backingPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        
        return YES;
    } else {
        return NO;
    }
}

- (id)executeRequest:(NSPersistentStoreRequest *)persistentStoreRequest
         withContext:(NSManagedObjectContext *)context
               error:(NSError *__autoreleasing *)error {
    if (persistentStoreRequest.requestType == NSFetchRequestType) {
        return [self executeFetchRequest:(NSFetchRequest *)persistentStoreRequest withContext:context error:error];
    } else if (persistentStoreRequest.requestType == NSSaveRequestType) {
        return [self executeSaveChangesRequest:(NSSaveChangesRequest *)persistentStoreRequest withContext:context error:error];
    } else {
        NSMutableDictionary *mutableUserInfo = [NSMutableDictionary dictionary];
        [mutableUserInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Unsupported NSPersistentStoreRequestType, %d", nil), persistentStoreRequest.requestType] forKey:NSLocalizedDescriptionKey];
        if (error) {
            *error = [[NSError alloc] initWithDomain:kPFIncrementalStoreErrorDomain code:0 userInfo:mutableUserInfo];
        }
        
        return nil;
    }
}

-(NSIncrementalStoreNode *)newValuesForObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[[objectID entity] name]];
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.fetchLimit = 1;
    fetchRequest.includesSubentities = NO;
    
    NSArray *attributes = [[[NSEntityDescription entityForName:fetchRequest.entityName inManagedObjectContext:context] attributesByName] allValues];
    NSArray *intransientAttributes = [attributes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"isTransient == NO"]];
    fetchRequest.propertiesToFetch = [[intransientAttributes valueForKeyPath:@"name"] arrayByAddingObject:kPFIncrementalStoreLastModifiedAttributeName];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", kPFIncrementalStoreResourceIdentifierAttributeName, PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:objectID])];
    
    __block NSArray *results;
    NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
    [backingContext performBlockAndWait:^{
        results = [backingContext executeFetchRequest:fetchRequest error:error];
    }];
    
    NSDictionary *attributeValues = [results lastObject] ?: [NSDictionary dictionary];
    NSIncrementalStoreNode *node = [[NSIncrementalStoreNode alloc] initWithObjectID:objectID withValues:attributeValues version:1];
    
    if (attributeValues) {
        NSManagedObjectContext *childContext = [self privateChildContextForParentContext:context];
        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        PFQuery *query = [[PFQuery alloc] initWithClassName:fetchRequest.entity.parseQueryClassName];
        [query getObjectInBackgroundWithId:PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:objectID]) block:^(PFObject *object, NSError *error) {
            if (error) {
                NSLog(@"Error: %@, %@", query, error);
                [self notifyManagedObjectContext:context requestIsCompleted:YES forNewValuesForObjectWithID:objectID];
            } else {
                [childContext performBlock:^{
                    NSManagedObject *managedObject = [childContext existingObjectWithID:objectID error:nil];
                    NSManagedObjectID *backingObjectID = [self managedObjectIDForBackingObjectForEntity:[objectID entity] withParseObjectId:object.objectId];
                    NSManagedObject *backingObject = [[self backingManagedObjectContext] existingObjectWithID:backingObjectID error:nil];
                    
                    NSMutableDictionary *mutableAttributeValues = [fetchRequest.entity.attributesByName mutableCopy];
                    [mutableAttributeValues removeObjectForKey:kPFIncrementalStoreResourceIdentifierAttributeName];
                    [mutableAttributeValues removeObjectForKey:kPFIncrementalStoreLastModifiedAttributeName];
                    for (NSString *attributeName in fetchRequest.entity.attributesByName) {
                        id parseValue = [object objectForKey:attributeName];
                        if ([parseValue isKindOfClass:[PFFile class]]) {
                            [mutableAttributeValues setPFFile:parseValue forKey:attributeName];
                        } else {
                            [mutableAttributeValues setObject:parseValue forKey:attributeName];
                        }
                    }
                    
                    [managedObject setValuesForKeysWithDictionary:mutableAttributeValues];
                    [backingObject setValuesForKeysWithDictionary:mutableAttributeValues];
                    
                    [childContext performBlockAndWait:^{
                        PFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext);
                        
                        NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
                        [backingContext performBlockAndWait:^{
                            PFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext);
                        }];
                    }];
                    
                    [self notifyManagedObjectContext:context requestIsCompleted:YES forNewValuesForObjectWithID:objectID];
                }];
            }
        }];
        
        [self notifyManagedObjectContext:context requestIsCompleted:NO forNewValuesForObjectWithID:objectID];
    }
    
    return node;
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    
    if (![[context existingObjectWithID:objectID error:nil] hasChanges]) {
        NSManagedObjectContext *childContext = [self privateChildContextForParentContext:context];

        PFQuery *query = [[PFQuery alloc] initWithClassName:objectID.entity.parseQueryClassName];
        [query getObjectInBackgroundWithId:PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:objectID]) block:^(PFObject *object, NSError *error) {
            if (error) {
                NSLog(@"Error: %@, %@", query, error);
                [self notifyManagedObjectContext:context requestIsCompleted:YES forNewValuesForRelationship:relationship forObjectWithID:objectID];
            } else {
                [childContext performBlock:^{
                    id relatedObjects = [object relatedObjectsForRelationship:relationship];
                    if (relatedObjects && ![relatedObjects conformsToProtocol:@protocol(NSFastEnumeration)]) {
                        relatedObjects = @[relatedObjects];
                    }
                    
                    for (PFObject *relatedObject in relatedObjects) {
                        [relatedObject fetchIfNeeded];
                    }
                    
                    [self insertOrUpdateObjects:relatedObjects ofEntity:relationship.destinationEntity withContext:childContext error:nil completionBlock:^(NSArray *managedObjects, NSArray *backingObjects) {
                        NSManagedObject *managedObject = [childContext objectWithID:objectID];
                        
						NSManagedObjectID *backingObjectID = [self managedObjectIDForBackingObjectForEntity:[objectID entity] withParseObjectId:object.objectId];
                        NSManagedObject *backingObject = (backingObjectID == nil) ? nil : [[self backingManagedObjectContext] existingObjectWithID:backingObjectID error:nil];
                        
                        if ([relationship isToMany]) {
                            if ([relationship isOrdered]) {
                                [managedObject setValue:[NSOrderedSet orderedSetWithArray:managedObjects] forKey:relationship.name];
                                [backingObject setValue:[NSOrderedSet orderedSetWithArray:backingObjects] forKey:relationship.name];
                            } else {
                                [managedObject setValue:[NSSet setWithArray:managedObjects] forKey:relationship.name];
                                [backingObject setValue:[NSSet setWithArray:backingObjects] forKey:relationship.name];
                            }
                        } else {
                            [managedObject setValue:[managedObjects lastObject] forKey:relationship.name];
                            [backingObject setValue:[backingObjects lastObject] forKey:relationship.name];
                        }
                        
                        [childContext performBlockAndWait:^{
                            PFSaveManagedObjectContextOrThrowInternalConsistencyException(childContext);
                            
                            NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
                            [backingContext performBlockAndWait:^{
                                PFSaveManagedObjectContextOrThrowInternalConsistencyException(backingContext);
                            }];
                        }];
                        
                        [self notifyManagedObjectContext:context requestIsCompleted:YES forNewValuesForRelationship:relationship forObjectWithID:objectID];
                    }];
                }];
            }
        }];
        
        [self notifyManagedObjectContext:context requestIsCompleted:NO forNewValuesForRelationship:relationship forObjectWithID:objectID];
    }
    
    NSManagedObjectID *backingObjectID = [self managedObjectIDForBackingObjectForEntity:[objectID entity] withParseObjectId:PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:objectID])];
    NSManagedObject *backingObject = (backingObjectID == nil) ? nil : [[self backingManagedObjectContext] existingObjectWithID:backingObjectID error:nil];
    
    if (backingObject) {
        id backingRelationshipObject = [backingObject valueForKeyPath:relationship.name];
        if ([relationship isToMany]) {
            NSMutableArray *mutableObjects = [NSMutableArray arrayWithCapacity:[backingRelationshipObject count]];
            for (NSString *resourceIdentifier in [backingRelationshipObject valueForKeyPath:kPFIncrementalStoreResourceIdentifierAttributeName]) {
                NSManagedObjectID *objectID = [self managedObjectIDForEntity:relationship.destinationEntity withParseObjectId:resourceIdentifier];
                [mutableObjects addObject:objectID];
            }
            
            return mutableObjects;
        } else {
            NSString *resourceIdentifier = [backingRelationshipObject valueForKeyPath:kPFIncrementalStoreResourceIdentifierAttributeName];
            NSManagedObjectID *objectID = [self managedObjectIDForEntity:relationship.destinationEntity withParseObjectId:resourceIdentifier];
            
            return objectID ?: [NSNull null];
        }
    } else {
        if ([relationship isToMany]) {
            return [NSArray array];
        } else {
            return [NSNull null];
        }
    }
}

-(NSArray *)obtainPermanentIDsForObjects:(NSArray *)array error:(NSError *__autoreleasing *)error {
    NSMutableArray *mutablePermanentIDs = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSManagedObject *managedObject in array) {
        NSManagedObjectID *managedObjectID = managedObject.objectID;
        if ([managedObjectID isTemporaryID] && managedObject.pf_resourceIdentifier) {
            NSManagedObjectID *objectID = [self managedObjectIDForEntity:managedObject.entity withParseObjectId:managedObject.pf_resourceIdentifier];
            [mutablePermanentIDs addObject:objectID];
        } else {
            [mutablePermanentIDs addObject:managedObjectID];
        }
    }
    
    return mutablePermanentIDs;
}

- (void)managedObjectContextDidRegisterObjectsWithIDs:(NSArray *)objectIDs {
    [super managedObjectContextDidRegisterObjectsWithIDs:objectIDs];
    
    for (NSManagedObjectID *objectID in objectIDs) {
        id referenceObject = [self referenceObjectForObjectID:objectID];
        if (!referenceObject) {
            continue;
        }
        
        NSMutableDictionary *objectIDsByResourceIdentifier = [_registeredObjectIDsByEntityNameAndNestedResourceIdentifier objectForKey:objectID.entity.name] ?: [NSMutableDictionary dictionary];
        [objectIDsByResourceIdentifier setObject:objectID forKey:PFResourceIdentifierFromReferenceObject(referenceObject)];
        
        [_registeredObjectIDsByEntityNameAndNestedResourceIdentifier setObject:objectIDsByResourceIdentifier forKey:objectID.entity.name];
    }
}

- (void)managedObjectContextDidUnregisterObjectsWithIDs:(NSArray *)objectIDs {
    [super managedObjectContextDidUnregisterObjectsWithIDs:objectIDs];
    
    for (NSManagedObjectID *objectID in objectIDs) {
        [[_registeredObjectIDsByEntityNameAndNestedResourceIdentifier objectForKey:objectID.entity.name] removeObjectForKey:PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:objectID])];
    }
}

#pragma mark - Backing Methods

- (NSManagedObjectContext *)backingManagedObjectContext {
    if (!_backingManagedObjectContext) {
        _backingManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _backingManagedObjectContext.persistentStoreCoordinator = _backingPersistentStoreCoordinator;
        _backingManagedObjectContext.retainsRegisteredObjects = YES;
    }
    
    return _backingManagedObjectContext;
}

-(BOOL)insertOrUpdateObjects:(NSArray *)parseObjects
                    ofEntity:(NSEntityDescription *)entity
                 withContext:(NSManagedObjectContext *)context
                       error:(NSError *__autoreleasing *)error
             completionBlock:(PFInsertUpdateResponseBlock)completionBlock {
    
    if (!parseObjects) {
        return NO;
    }
    
    if ([parseObjects count] == 0) {
        if (completionBlock) {
            completionBlock([NSArray array], [NSArray array]);
        }
        
        return NO;
    }
    
    NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
    
    NSUInteger numberOfRepresentations = [parseObjects count];
    NSMutableArray *mutableManagedObjects = [NSMutableArray arrayWithCapacity:numberOfRepresentations];
    NSMutableArray *mutableBackingObjects = [NSMutableArray arrayWithCapacity:numberOfRepresentations];
    
    for (PFObject *object in parseObjects) {
        NSArray *insertedObjectIDs = [context.insertedObjects valueForKey:@"pf_resourceIdentifier"];
        NSArray *updatedObjectIDs = [context.updatedObjects valueForKey:@"pf_resourceIdentifier"];
        if ([insertedObjectIDs containsObject:object.objectId] || [updatedObjectIDs containsObject:object.objectId]) {
            continue;
        }
        
        __block NSManagedObject *managedObject = nil;
        [context performBlockAndWait:^{
            managedObject = [context existingObjectWithID:[self managedObjectIDForEntity:entity withParseObjectId:object.objectId] error:nil];
        }];
        
        [object fetchIfNeeded];
        
        [managedObject setValuesFromParseObject:object];
        
        NSManagedObjectID *backingObjectID = [self managedObjectIDForBackingObjectForEntity:entity withParseObjectId:object.objectId];
        __block NSManagedObject *backingObject = nil;
        [backingContext performBlockAndWait:^{
            if (backingObjectID) {
                backingObject = [backingContext existingObjectWithID:backingObjectID error:nil];
            } else {
                backingObject = [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:backingContext];
                [backingObject.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:backingObject] error:nil];
            }
        }];
        [backingObject setValue:object.objectId forKey:kPFIncrementalStoreResourceIdentifierAttributeName];
        [backingObject setValue:object.updatedAt forKey:kPFIncrementalStoreLastModifiedAttributeName];
        [backingObject setValuesFromParseObject:object];
        
        if (!backingObjectID) {
            [context insertObject:managedObject];
        }
        
        for(NSString *relationshipName in entity.relationshipsByName) {
            NSRelationshipDescription *relationship = [[entity relationshipsByName] valueForKey:relationshipName];
            
            if (!relationship || relationship.isOptional) {
                continue;
            }
            
            id relatedObject = [object relatedObjectsForRelationship:relationship];
            if (!relatedObject || [relatedObject isEqual:[NSNull null]] || ([relatedObject conformsToProtocol:@protocol(NSFastEnumeration)] && [relatedObject count] == 0)) {
                [managedObject setValue:nil forKey:relationshipName];
                [backingObject setValue:nil forKey:relationshipName];
                continue;
            }
            
            NSArray *relatedObjectArray = (relationship.isToMany) ? relatedObject : @[relatedObject];
            [self insertOrUpdateObjects:relatedObjectArray ofEntity:relationship.destinationEntity withContext:context error:error completionBlock:^(NSArray *managedObjects, NSArray *backingObjects) {
                if ([relationship isToMany]) {
                    if ([relationship isOrdered]) {
                        [managedObject setValue:[NSOrderedSet orderedSetWithArray:managedObjects] forKey:relationship.name];
                        [backingObject setValue:[NSOrderedSet orderedSetWithArray:backingObjects] forKey:relationship.name];
                    } else {
                        [managedObject setValue:[NSSet setWithArray:managedObjects] forKey:relationship.name];
                        [backingObject setValue:[NSSet setWithArray:backingObjects] forKey:relationship.name];
                    }
                } else {
                    [managedObject setValue:[managedObjects lastObject] forKey:relationship.name];
                    [backingObject setValue:[backingObjects lastObject] forKey:relationship.name];
                }
            }];
        }
        
        [mutableManagedObjects addObject:managedObject];
        [mutableBackingObjects addObject:backingObject];
    }
    
    if (completionBlock) {
        completionBlock(mutableManagedObjects, mutableBackingObjects);
    }
    
    return YES;
}

- (void)updateBackingObject:(NSManagedObject *)backingObject
withAttributeAndRelationshipValuesFromManagedObject:(NSManagedObject *)managedObject {

    NSMutableDictionary *mutableRelationshipValues = [[NSMutableDictionary alloc] init];
    for (NSRelationshipDescription *relationship in [managedObject.entity.relationshipsByName allValues]) {
        
        if ([managedObject hasFaultForRelationshipNamed:relationship.name]) {
            continue;
        }
        
        id relationshipValue = [managedObject valueForKey:relationship.name];
        if (!relationshipValue) {
            continue;
        }
        
        if ([relationship isToMany]) {
            NSSet *relatedObjects = (NSSet *)relationshipValue;
            id mutableBackingRelationshipValue = nil;
            if ([relationship isOrdered]) {
                mutableBackingRelationshipValue = [NSMutableOrderedSet orderedSetWithCapacity:[relatedObjects count]];
            } else {
                mutableBackingRelationshipValue = [NSMutableSet setWithCapacity:[relatedObjects count]];
            }
            
            for (NSManagedObject *relationshipManagedObject in relatedObjects) {
                if (![[relationshipManagedObject objectID] isTemporaryID]) {
                    NSManagedObjectID *backingRelationshipObjectID = [self managedObjectIDForBackingObjectForEntity:relationship.destinationEntity withParseObjectId:PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:relationshipManagedObject.objectID])];
                    if (backingRelationshipObjectID) {
                        NSManagedObject *backingRelationshipObject = [backingObject.managedObjectContext existingObjectWithID:backingRelationshipObjectID error:nil];
                        if (backingRelationshipObject) {
                            [mutableBackingRelationshipValue addObject:backingRelationshipObject];
                        }
                    }
                }
            }
            
            [mutableRelationshipValues setValue:mutableBackingRelationshipValue forKey:relationship.name];
        } else {
            NSManagedObject *relatedObject = (NSManagedObject *)relationshipValue;
            if (![[relatedObject objectID] isTemporaryID]) {
                NSManagedObjectID *backingRelationshipObjectID = [self managedObjectIDForBackingObjectForEntity:relationship.destinationEntity withParseObjectId:PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:[relationshipValue objectID]])];
                if (backingRelationshipObjectID) {
                    NSManagedObject *backingRelationshipObject = [backingObject.managedObjectContext existingObjectWithID:backingRelationshipObjectID error:nil];
                    [mutableRelationshipValues setValue:backingRelationshipObject forKey:relationship.name];
                }
            }
        }
    }
    
    [backingObject setValuesForKeysWithDictionary:mutableRelationshipValues];
    [backingObject setValuesForKeysWithDictionary:[managedObject dictionaryWithValuesForKeys:[managedObject.entity.attributesByName allKeys]]];
}

#pragma mark - Object ID Methods

- (NSManagedObjectID *)managedObjectIDForEntity:(NSEntityDescription *)entity
                              withParseObjectId:(NSString *)resourceIdentifier {
    if (!resourceIdentifier) {
        return nil;
    }
    
    NSManagedObjectID *objectID = nil;
    NSMutableDictionary *objectIDsByResourceIdentifier = [_registeredObjectIDsByEntityNameAndNestedResourceIdentifier objectForKey:entity.name];
    if (objectIDsByResourceIdentifier) {
        objectID = [objectIDsByResourceIdentifier objectForKey:resourceIdentifier];
    }
    
    if (!objectID) {
        objectID = [self newObjectIDForEntity:entity referenceObject:PFReferenceObjectFromResourceIdentifier(resourceIdentifier)];
    }
    
    NSParameterAssert([objectID.entity.name isEqualToString:entity.name]);
    
    return objectID;
}

- (NSManagedObjectID *)managedObjectIDForBackingObjectForEntity:(NSEntityDescription *)entity
                                              withParseObjectId:(NSString *)resourceIdentifier {
    if (!resourceIdentifier) {
        return nil;
    }
    
    NSManagedObjectID *objectID = [self managedObjectIDForEntity:entity withParseObjectId:resourceIdentifier];
    __block NSManagedObjectID *backingObjectID = [_backingObjectIDByObjectID objectForKey:objectID];
    if (backingObjectID) {
        return backingObjectID;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[entity name]];
    fetchRequest.resultType = NSManagedObjectIDResultType;
    fetchRequest.fetchLimit = 1;
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", kPFIncrementalStoreResourceIdentifierAttributeName, resourceIdentifier];
    
    __block NSError *error = nil;
    NSManagedObjectContext *backingContext = [self backingManagedObjectContext];
    [backingContext performBlockAndWait:^{
        backingObjectID = [[backingContext executeFetchRequest:fetchRequest error:&error] lastObject];
    }];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return nil;
    }
    
    if (backingObjectID) {
        [_backingObjectIDByObjectID setObject:backingObjectID forKey:objectID];
    }
    
    return backingObjectID;
}

- (NSDictionary *)valuesForEntity:(NSEntityDescription *)entity
                withParseObjectId:(NSString *)referenceObject {
    PFQuery *query = [[PFQuery alloc] initWithClassName:entity.parseQueryClassName];
    PFObject *object = [query getObjectWithId:PFResourceIdentifierFromReferenceObject(referenceObject)];
    
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    for (NSString *attributeName in entity.attributesByName) {
        id value = [object objectForKey:attributeName];
        if (value) {
            [values setObject:value forKey:attributeName];
        } else {
            NSLog(@"nil");
        }
    }
    for (NSString *relationshipName in entity.relationshipsByName) {
        NSRelationshipDescription *relationship = [entity.relationshipsByName objectForKey:relationshipName];
        if (![relationship isToMany]) {
            PFObject *relatedObject = [object objectForKey:relationshipName];
            [values setObject:PFReferenceObjectFromResourceIdentifier(relatedObject.objectId) forKey:relationshipName];
        }
    }
    
    return values;
}

#pragma mark - Notification Methods

- (void)notifyManagedObjectContext:(NSManagedObjectContext *)context
                requestIsCompleted:(BOOL)isCompleted
                   forFetchRequest:(NSFetchRequest *)fetchRequest
                  fetchedObjectIDs:(NSArray *)fetchedObjectIDs
{
    NSString *notificationName = isCompleted ? PFIncrementalStoreContextDidFetchRemoteValues : PFIncrementalStoreContextWillFetchRemoteValues;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:fetchRequest forKey:PFIncrementalStorePersistentStoreRequestKey];
    if (isCompleted && fetchedObjectIDs) {
        [userInfo setObject:fetchedObjectIDs forKey:PFIncrementalStoreFetchedObjectIDsKey];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:context userInfo:userInfo];
}

- (void)notifyManagedObjectContext:(NSManagedObjectContext *)context
                requestIsCompleted:(BOOL)isCompleted
             forSaveChangesRequest:(NSSaveChangesRequest *)saveChangesRequest
                  changedObjectIDs:(NSArray *)changedObjectIDs
{
    NSString *notificationName = isCompleted ? PFIncrementalStoreContextDidSaveRemoteValues : PFIncrementalStoreContextWillSaveRemoteValues;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:saveChangesRequest forKey:PFIncrementalStorePersistentStoreRequestKey];
    if (isCompleted && changedObjectIDs) {
        [userInfo setObject:changedObjectIDs forKey:PFIncrementalStoreFetchedObjectIDsKey];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:context userInfo:userInfo];
}

- (void)notifyManagedObjectContext:(NSManagedObjectContext *)context
                requestIsCompleted:(BOOL)isCompleted
       forNewValuesForObjectWithID:(NSManagedObjectID *)objectID
{
    NSString *notificationName = isCompleted ? PFIncrementalStoreContextDidFetchNewValuesForObject : PFIncrementalStoreContextWillFetchNewValuesForObject;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:objectID forKey:PFIncrementalStoreFaultingObjectIDKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:context userInfo:userInfo];
}

- (void)notifyManagedObjectContext:(NSManagedObjectContext *)context
                requestIsCompleted:(BOOL)isCompleted
       forNewValuesForRelationship:(NSRelationshipDescription *)relationship
                   forObjectWithID:(NSManagedObjectID *)objectID
{
    NSString *notificationName = isCompleted ? PFIncrementalStoreContextDidFetchNewValuesForRelationship : PFIncrementalStoreContextWillFetchNewValuesForRelationship;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:objectID forKey:PFIncrementalStoreFaultingObjectIDKey];
    [userInfo setObject:relationship forKey:PFIncrementalStoreFaultingRelationshipKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:context userInfo:userInfo];
}

#pragma mark - Helper Methods

-(NSManagedObjectContext *)privateChildContextForParentContext:(NSManagedObjectContext *)parentContext {
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = parentContext;
    childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    return childContext;
}

@end
