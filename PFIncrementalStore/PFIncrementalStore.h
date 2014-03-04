// PFIncrementalStore.h
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

#import <CoreData/CoreData.h>
#import "NSManagedObject_PFIncrementalStore.h"

@interface PFIncrementalStore : NSIncrementalStore

///---------------------------------------------
/// @name Accessing Incremental Store Properties
///---------------------------------------------

/**
 The persistent store coordinator used to persist data from the associated web serivices locally.
 
 @discussion Rather than persist values directly, `PFIncrementalStore` manages and proxies through a persistent store coordinator.
 */
@property (readonly) NSPersistentStoreCoordinator *backingPersistentStoreCoordinator;

///----------------
/// @name Resource Identifier Functions
///----------------

/**
 There is a bug in Core Data wherein managed object IDs whose reference object is a string beginning with a digit will incorrectly strip any subsequent non-numeric characters from the reference object. This breaks any functionality related to URI representations of the managed object ID, and likely other methods as well. For example, an object ID with a reference object of @"123ABC" would generate one with a URI represenation `coredata://store-UUID/Entity/123`, rather than the expected `coredata://store-UUID/Entity/123ABC`. As a fix, rather than resource identifiers being used directly as reference objects, they are prepended with a non-numeric constant first.
 
 Thus, in order to get the resource identifier of a managed object's reference object, you must use the function `PFResourceIdentifierFromReferenceObject()`.
 
 See https://github.com/AFNetworking/AFIncrementalStore/issues/82 for more details.
 */
extern NSString * PFReferenceObjectFromResourceIdentifier(NSString *resourceIdentifier);

extern NSString * PFResourceIdentifierFromReferenceObject(id referenceObject);

///-----------------------
/// @name Required Methods
///-----------------------

/**
 Returns the string used as the `NSStoreTypeKey` value by the application's persistent store coordinator.
 
 @return The string used to describe the type of the store.
 */
+ (NSString *)type;

/**
 Returns the managed object model used by the store.
 
 @return The managed object model used by the store
 */
+ (NSManagedObjectModel *)model;

///-----------------------
/// @name Optional Methods
///-----------------------

/**
 
 */
- (id)executeFetchRequest:(NSFetchRequest *)fetchRequest
              withContext:(NSManagedObjectContext *)context
                    error:(NSError *__autoreleasing *)error;

/**
 
 */
- (id)executeSaveChangesRequest:(NSSaveChangesRequest *)saveChangesRequest
                    withContext:(NSManagedObjectContext *)context
                          error:(NSError *__autoreleasing *)error;

///--------------------
/// @name Notifications
///--------------------

/**
 Posted before an HTTP request operation corresponding to a fetch request starts.
 The object is the managed object context of the request.
 The notification `userInfo` contains the finished request operation, keyed at `PFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `PFIncrementalStorePersistentStoreRequestKey`.
 */
extern NSString * const PFIncrementalStoreContextWillFetchRemoteValues;

/**
 Posted after an HTTP request operation corresponding to a fetch request finishes.
 The object is the managed object context of the request.
 The notification `userInfo` contains the finished request operation, keyed at `PFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `PFIncrementalStorePersistentStoreRequestKey`.
 */
extern NSString * const PFIncrementalStoreContextDidFetchRemoteValues;

//------------------------------------------------------------------------------

/**
 Posted before an HTTP request operation corresponding to a fetch request starts.
 The object is the managed object context of the request.
 The notification `userInfo` contains an array of request operations, keyed at `PFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `PFIncrementalStorePersistentStoreRequestKey`.
 */
extern NSString * const PFIncrementalStoreContextWillSaveRemoteValues;

/**
 Posted after an HTTP request operation corresponding to a fetch request finishes.
 The object is the managed object context of the request.
 The notification `userInfo` contains an array of request operations, keyed at `PFIncrementalStoreRequestOperationKey`, as well as the associated persistent store request, if applicable, keyed at `PFIncrementalStorePersistentStoreRequestKey`.
 */
extern NSString * const PFIncrementalStoreContextDidSaveRemoteValues;

//------------------------------------------------------------------------------

/**
 Posted before an HTTP request operation corresponding to an attribute fault starts.
 The object is the managed object context of the request.
 The notification `userInfo` contains an array of request operations, keyed at `PFIncrementalStoreRequestOperationKey`, as well as the managed object ID of the faulting object, keyed at `PFIncrementalStoreFaultingObjectIDKey`.
 */
extern NSString * const PFIncrementalStoreContextWillFetchNewValuesForObject;

/**
 Posted after an HTTP request operation corresponding to an attribute fault finishes.
 The object is the managed object context of the request.
 The notification `userInfo` contains an array of request operations, keyed at `PFIncrementalStoreRequestOperationKey`, as well as the managed object ID of the faulting object, keyed at `PFIncrementalStoreFaultingObjectIDKey`.
 */
extern NSString * const PFIncrementalStoreContextDidFetchNewValuesForObject;

//------------------------------------------------------------------------------

/**
 Posted before an HTTP request operation corresponding to an relationship fault starts.
 The object is the managed object context of the request.
 The notification `userInfo` contains an array of request operations, keyed at `PFIncrementalStoreRequestOperationKey`, as well as the faulting relationship, keyed at `PFIncrementalStoreFaultingRelationshipKey`, and the managed object ID of the faulting object, keyed at `PFIncrementalStoreFaultingObjectIDKey`.
 
 */
extern NSString * const PFIncrementalStoreContextWillFetchNewValuesForRelationship;

/**
 Posted after an HTTP request operation corresponding to a relationship fault finishes.
 The object is the managed object context of the request.
 The notification `userInfo` contains an array of request operations, keyed at `PFIncrementalStoreRequestOperationKey`, as well as the faulting relationship, keyed at `PFIncrementalStoreFaultingRelationshipKey`, and the managed object ID of the faulting object, keyed at `PFIncrementalStoreFaultingObjectIDKey`.
 */
extern NSString * const PFIncrementalStoreContextDidFetchNewValuesForRelationship;

//------------------------------------------------------------------------------

/**
 A key in the `userInfo` dictionary in an `NSManagedObject` corresponding to the Parse Class Name with which the entity should synchronize.
 */
extern NSString * const PFIncrementalStoreManagedObjectEntityParseClassName;

/**
 A key in the `userInfo` dictionary in a `PFIncrementalStoreContextWillFetchRemoteValues` or `PFIncrementalStoreContextDidFetchRemoteValues` as well as `PFIncrementalStoreContextWillSaveRemoteValues` or `PFIncrementalStoreContextDidSaveRemoteValues` notifications.
 The corresponding value is an `NSArray` of `AFHTTPRequestOperation` objects corresponding to the request operations triggered by the fetch or save changes request.
 */
extern NSString * const PFIncrementalStoreRequestOperationsKey;

/**
 A key in the `userInfo` dictionary in a `PFIncrementalStoreContextWillFetchRemoteValues` or `PFIncrementalStoreContextDidFetchRemoteValues` notification.
 The corresponding value is an `NSArray` of `NSManagedObjectIDs` for the objects returned by the remote HTTP request for the associated fetch request.
 */
extern NSString * const PFIncrementalStoreFetchedObjectIDsKey;

/**
 A key in the `userInfo` dictionary in a `PFIncrementalStoreContextWillFetchNewValuesForObject` or `PFIncrementalStoreContextDidFetchNewValuesForObject` notification.
 The corresponding value is an `NSManagedObjectID` for the faulting managed object.
 */
extern NSString * const PFIncrementalStoreFaultingObjectIDKey;

/**
 A key in the `userInfo` dictionary in a `PFIncrementalStoreContextWillFetchNewValuesForRelationship` or `PFIncrementalStoreContextDidFetchNewValuesForRelationship` notification.
 The corresponding value is an `NSRelationshipDescription` for the faulting relationship.
 */
extern NSString * const PFIncrementalStoreFaultingRelationshipKey;

/**
 A key in the `userInfo` dictionary in a `PFIncrementalStoreContextWillFetchRemoteValues` or `PFIncrementalStoreContextDidFetchRemoteValues` notification.
 The corresponding value is an `NSPersistentStoreRequest` object representing the associated fetch or save request. */
extern NSString * const PFIncrementalStorePersistentStoreRequestKey;

@end