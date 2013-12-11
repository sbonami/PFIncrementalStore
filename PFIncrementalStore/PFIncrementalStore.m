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
    PFQuery *query = [PFQuery queryWithClassName:fetchRequest.entityName predicate:fetchRequest.predicate];
    NSMutableSet *fetchedObjects = [NSMutableSet set];
    
    for (PFObject *object in [query findObjects]) {
        NSManagedObjectID *objectID = [self managedObjectIDForEntity:fetchRequest.entity withParseObjectId:object.objectId];
        [fetchedObjects addObject:[context objectWithID:objectID]];
    }
    
    return [fetchedObjects allObjects];
}

-(NSArray *)objectIDResultOfFetchRequest:(NSFetchRequest *)fetchRequest
                             withContext:(NSManagedObjectContext *)context
                                   error:(NSError *__autoreleasing *)error {
    return [[self objectResultOfFetchRequest:fetchRequest withContext:context error:error] valueForKeyPath:@"objectID"];
}

-(NSDictionary *)dictionaryResultOfFetchRequest:(NSFetchRequest *)fetchRequest
                                    withContext:(NSManagedObjectContext *)context
                                          error:(NSError *__autoreleasing *)error {
    return NSDictionaryOfVariableBindings([self objectResultOfFetchRequest:fetchRequest withContext:context error:error]);
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
            [lastModifiedProperty setAttributeType:NSStringAttributeType];
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
    NSDictionary *values = [self valuesForEntity:objectID.entity withParseObjectId:[self referenceObjectForObjectID:objectID]];
    return [[NSIncrementalStoreNode alloc] initWithObjectID:objectID withValues:values version:1];
}

-(id)newValueForRelationship:(NSRelationshipDescription *)relationship forObjectWithID:(NSManagedObjectID *)objectID withContext:(NSManagedObjectContext *)context error:(NSError *__autoreleasing *)error {
    id parseID = PFResourceIdentifierFromReferenceObject([self referenceObjectForObjectID:objectID]);
    
    PFQuery *query = [[PFQuery alloc] initWithClassName:objectID.entity.name];
    PFObject *object = [query getObjectWithId:parseID];
    
    NSMutableArray *relatedObjects = [NSMutableArray array];
    for (PFObject *relatedObject in [object objectForKey:relationship.name]) {
        [relatedObjects addObject:[self managedObjectIDForEntity:relationship.destinationEntity
                                               withParseObjectId:relatedObject.objectId]];
    }
    return relatedObjects;
}

-(NSArray *)obtainPermanentIDsForObjects:(NSArray *)array error:(NSError *__autoreleasing *)error {
    NSMutableArray *objectIDs = [NSMutableArray arrayWithCapacity:[array count]];
    for (NSManagedObject *managedObject in array) {
        NSManagedObjectID *managedObjectID = managedObject.objectID;
#warning - NOT IMPLEMENTED
        if ([managedObjectID isTemporaryID] && managedObject.pf_resourceIdentifier) {
            [objectIDs addObject:[self managedObjectIDForEntity:managedObject.entity withParseObjectId:managedObject.pf_resourceIdentifier]];
        } else {
            [objectIDs addObject:managedObjectID];
        }
    }
    
    return objectIDs;
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

@end