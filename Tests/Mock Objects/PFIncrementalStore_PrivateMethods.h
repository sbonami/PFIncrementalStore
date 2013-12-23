//
//  PFIncrementalStore_PrivateMethods.h
//  Tests
//
//  Created by Scott BonAmi on 12/17/13.
//
//

#import "PFIncrementalStore.h"

static NSString * const kPFIncrementalStoreErrorDomain = @"PFIncrementalStoreErrorDomain";
static NSString * const kPFIncrementalStoreUnimplementedMethodException = @"PFIncrementalStoreUnimplementedMethodException";

static NSString * const kPFReferenceObjectPrefix = @"__pf_";
static NSString * const kPFIncrementalStoreLastModifiedAttributeName = @"__pf_lastModified";
static NSString * const kPFIncrementalStoreResourceIdentifierAttributeName = @"__pf_resourceIdentifier";

inline NSString * PFReferenceObjectFromResourceIdentifier(NSString *resourceIdentifier);
inline NSString * PFResourceIdentifierFromReferenceObject(id referenceObject);

inline void PFSaveManagedObjectContextOrThrowInternalConsistencyException(NSManagedObjectContext *managedObjectContext);

@interface PFIncrementalStore ()

- (NSManagedObjectContext *)backingManagedObjectContext;

// Backing Methods

typedef void (^PFInsertUpdateResponseBlock)(NSArray *managedObjects, NSArray *backingObjects);

-(BOOL)insertOrUpdateObjects:(NSArray *)parseObjects
                    ofEntity:(NSEntityDescription *)entity
                 withContext:(NSManagedObjectContext *)context
                       error:(NSError *__autoreleasing *)error
             completionBlock:(PFInsertUpdateResponseBlock)completionBlock;

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

@end