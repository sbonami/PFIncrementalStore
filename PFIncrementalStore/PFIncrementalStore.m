
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
NSString * const PFIncrementalStoreRequestOperationsKey = @"PFIncrementalStoreRequestOperations";
NSString * const PFIncrementalStoreFetchedObjectIDsKey = @"PFIncrementalStoreFetchedObjectIDs";
NSString * const PFIncrementalStoreFaultingObjectIDKey = @"PFIncrementalStoreFaultingObjectID";
NSString * const PFIncrementalStoreFaultingRelationshipKey = @"PFIncrementalStoreFaultingRelationship";
NSString * const PFIncrementalStorePersistentStoreRequestKey = @"PFIncrementalStorePersistentStoreRequest";


#pragma mark - Resource Identifier Methods

static char kPFResourceIdentifierObjectKey;

static NSString * const kPFReferenceObjectPrefix = @"__pf_";
static NSString * const kPFIncrementalStoreLastModifiedAttributeName = @"__pf_lastModified";
static NSString * const kPFIncrementalStoreResourceIdentifierAttributeName = @"__pf_resourceIdentifier";

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

@interface NSManagedObject (_PFIncrementalStore)
@property (readwrite, nonatomic, copy, setter = pf_setResourceIdentifier:) NSString *pf_resourceIdentifier;
@end

@implementation NSManagedObject (_PFIncrementalStore)
@dynamic pf_resourceIdentifier;

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
        [self setValue:[parseObject objectForKey:attributeName] forKey:attributeName];
    }
}

@end

#pragma mark - PFIncrementalStore implementation

@implementation PFIncrementalStore {
@private
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
    
    PFQuery *query = [PFQuery queryWithClassName:fetchRequest.entityName predicate:fetchRequest.predicate];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (error) {
            NSLog(@"Error: %@, %@", query, error);
            [self notifyManagedObjectContext:context requestIsCompleted:YES forFetchRequest:fetchRequest fetchedObjectIDs:nil];
        } else {
            [context performBlockAndWait:^{
                NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                childContext.parentContext = context;
                childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
                
                [childContext performBlockAndWait:^{
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
            return [NSNumber numberWithInteger:[self countResultOfFetchRequest:fetchRequest withContext:context error:error]];
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
    backingFetchRequest.entity = [NSEntityDescription entityForName:fetchRequest.entityName inManagedObjectContext:backingContext];
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

-(NSUInteger)countResultOfFetchRequest:(NSFetchRequest *)fetchRequest
                           withContext:(NSManagedObjectContext *)context
                                 error:(NSError *__autoreleasing *)error {
    
    return [[self objectResultOfFetchRequest:fetchRequest withContext:context error:error] count];
}

#pragma mark - Save Request methods

- (id)executeSaveChangesRequest:(NSSaveChangesRequest *)saveChangesRequest
                    withContext:(NSManagedObjectContext *)context
                          error:(NSError *__autoreleasing *)error {
    NSMutableArray *changedObjects = [NSMutableArray array];
    NSArray *insertedObjects = [[saveChangesRequest insertedObjects] allObjects];
    NSArray *updatedObjects = [[saveChangesRequest updatedObjects] allObjects];
    [changedObjects addObjectsFromArray:insertedObjects];
    [changedObjects addObjectsFromArray:updatedObjects];
    
    for (NSManagedObject *changedObject in changedObjects) {
        PFObject *object = nil;
        if ([insertedObjects indexOfObject:changedObject] != NSNotFound) {
            object = [PFObject objectWithClassName:changedObject.entity.name];
        } else {
            PFQuery *query = [[PFQuery alloc] initWithClassName:changedObject.entity.name];
#warning - NOT IMPLEMENTED
            object = [query getObjectWithId:changedObject.pf_resourceIdentifier];
        }
        
        NSLog(@"%@",changedObject.changedValues);
        for (NSString *attributeName in changedObject.changedValues) {
            id value = [changedObject.changedValues objectForKey:attributeName];
            [object setObject:value forKey:attributeName];
        }
        /*
         for (NSString *relationshipName in changedObject.entity.relationshipsByName) {
         NSRelationshipDescription *relationship = [changedObject.entity.relationshipsByName objectForKey:relationshipName];
         if (![relationship isToMany]) {
         id value = [changedObject valueForKey:relationshipName];
         if (value) {
         [object setObject:value forKey:relationshipName];
         }
         }
         }
         */
        [object save];
    }
    
    for (NSManagedObject *deletedObject in [saveChangesRequest deletedObjects]) {
        PFQuery *query = [[PFQuery alloc] initWithClassName:deletedObject.entity.name];
#warning - NOT IMPLEMENTED
        PFObject *object = [query getObjectWithId:deletedObject.pf_resourceIdentifier];
        [object delete];
    }
    
    return [NSArray array];
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
        NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        childContext.parentContext = context;
        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        PFQuery *query = [[PFQuery alloc] initWithClassName:fetchRequest.entityName];
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
                        [mutableAttributeValues setObject:[object objectForKey:attributeName] forKey:attributeName];
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
        NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        childContext.parentContext = context;
        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
        
        PFQuery *query = [[PFQuery alloc] initWithClassName:objectID.entity.name];
        [query getObjectInBackgroundWithId:PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:objectID]) block:^(PFObject *object, NSError *error) {
            if (error) {
                NSLog(@"Error: %@, %@", query, error);
                [self notifyManagedObjectContext:context requestIsCompleted:YES forNewValuesForRelationship:relationship forObjectWithID:objectID];
            } else {
                [childContext performBlock:^{
                    id relatedObjects = [object objectForKey:relationship.name];
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
             completionBlock:(void (^)(NSArray *managedObjects, NSArray *backingObjects))completionBlock {
    
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
        __block NSManagedObject *managedObject = nil;
        [context performBlockAndWait:^{
            managedObject = [context existingObjectWithID:[self managedObjectIDForEntity:entity withParseObjectId:object.objectId] error:nil];
        }];
        
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
        
        NSLog(@"%@",backingObject);
        if (!backingObjectID) {
            [context insertObject:managedObject];
        }
        
#warning RELATIONSHIP NOT IMPLEMENTED
        
        [mutableManagedObjects addObject:managedObject];
        [mutableBackingObjects addObject:backingObject];
    }
    
    if (completionBlock) {
        completionBlock(mutableManagedObjects, mutableBackingObjects);
    }
    
    return YES;
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
    PFQuery *query = [[PFQuery alloc] initWithClassName:entity.name];
    PFObject *object = [query getObjectWithId:PFResourceIdentifierFromReferenceObject(referenceObject)];
    
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    for (NSString *attributeName in entity.attributesByName) {
        [values setObject:[object objectForKey:attributeName] forKey:attributeName];
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
            lastRequestIsCompleted:(BOOL)isCompleted
             forSaveChangesRequest:(NSSaveChangesRequest *)saveChangesRequest
{
    NSString *notificationName = isCompleted ? PFIncrementalStoreContextDidSaveRemoteValues : PFIncrementalStoreContextWillSaveRemoteValues;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:saveChangesRequest forKey:PFIncrementalStorePersistentStoreRequestKey];
    
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

@end