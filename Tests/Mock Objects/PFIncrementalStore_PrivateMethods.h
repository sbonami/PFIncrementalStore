//
//  PFIncrementalStore_PrivateMethods.h
//  Tests
//
//  Created by Scott BonAmi on 12/17/13.
//
//

#import <Parse/Parse.h>

#import "PFIncrementalStore.h"

static NSString * const kPFIncrementalStoreErrorDomain = @"PFIncrementalStoreErrorDomain";
static NSString * const kPFIncrementalStoreUnimplementedMethodException = @"PFIncrementalStoreUnimplementedMethodException";

inline NSString * PFReferenceObjectFromResourceIdentifier(NSString *resourceIdentifier);
inline NSString * PFResourceIdentifierFromReferenceObject(id referenceObject);

inline void PFSaveManagedObjectContextOrThrowInternalConsistencyException(NSManagedObjectContext *managedObjectContext);

@interface PFIncrementalStore ()

- (NSManagedObjectContext *)backingManagedObjectContext;

// Save Request Methods

-(void)insertObject:(NSManagedObject *)insertedObject
        fromRequest:(NSSaveChangesRequest *)request
          inContext:(NSManagedObjectContext *)context
              error:(NSError *__autoreleasing *)error;

-(void)updateObject:(NSManagedObject *)insertedObject
        fromRequest:(NSSaveChangesRequest *)request
          inContext:(NSManagedObjectContext *)context
              error:(NSError *__autoreleasing *)error;

-(void)deleteObject:(NSManagedObject *)insertedObject
        fromRequest:(NSSaveChangesRequest *)request
          inContext:(NSManagedObjectContext *)context
              error:(NSError *__autoreleasing *)error;

// Backing Methods

typedef void (^PFInsertUpdateResponseBlock)(NSArray *managedObjects, NSArray *backingObjects);

-(BOOL)insertOrUpdateObjects:(NSArray *)parseObjects
                    ofEntity:(NSEntityDescription *)entity
                 withContext:(NSManagedObjectContext *)context
                       error:(NSError *__autoreleasing *)error
             completionBlock:(PFInsertUpdateResponseBlock)completionBlock;

- (void)updateBackingObject:(NSManagedObject *)backingObject
withAttributeAndRelationshipValuesFromManagedObject:(NSManagedObject *)managedObject;

// Object ID Methods
- (NSManagedObjectID *)managedObjectIDForBackingObjectForEntity:(NSEntityDescription *)entity
                                              withParseObjectId:(NSString *)resourceIdentifier;

// Notification Methods
- (void)notifyManagedObjectContext:(NSManagedObjectContext *)context
                requestIsCompleted:(BOOL)isCompleted
                                   forFetchRequest:(NSFetchRequest *)fetchRequest
                                                     fetchedObjectIDs:(NSArray *)fetchedObjectIDs;

- (void)notifyManagedObjectContext:(NSManagedObjectContext *)context
                requestIsCompleted:(BOOL)isCompleted
                             forSaveChangesRequest:(NSSaveChangesRequest *)saveChangesRequest
                                               changedObjectIDs:(NSArray *)changedObjectIDs;

- (void)notifyManagedObjectContext:(NSManagedObjectContext *)context
                requestIsCompleted:(BOOL)isCompleted
                       forNewValuesForObjectWithID:(NSManagedObjectID *)objectID;

- (void)notifyManagedObjectContext:(NSManagedObjectContext *)context
                requestIsCompleted:(BOOL)isCompleted
                       forNewValuesForRelationship:(NSRelationshipDescription *)relationship
                                          forObjectWithID:(NSManagedObjectID *)objectID;

// Helper Methods
- (NSManagedObjectContext *)privateChildContextForParentContext:(NSManagedObjectContext *)parentContext;

@end

@interface NSManagedObject (_PFIncrementalStore)

@property (readwrite, nonatomic, copy, setter = pf_setResourceIdentifier:) NSString *pf_resourceIdentifier;

- (void)setValuesFromParseObject:(PFObject *)parseObject;

- (void)setPFFile:(PFFile *)file forKey:(NSString *)key;

@end

@interface NSMutableDictionary (_PFIncrementalStore)

- (void)setPFFile:(PFFile *)file forKey:(NSString *)key;

@end

@interface PFObject (_PFIncrementalStore)

- (void)setValuesFromManagedObject:(NSManagedObject *)managedObject withSaveCallbacks:(NSMutableDictionary **)saveCallbacks;

@end