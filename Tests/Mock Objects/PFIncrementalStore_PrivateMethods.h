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

inline NSString * PFReferenceObjectFromResourceIdentifier(NSString *resourceIdentifier);
inline NSString * PFResourceIdentifierFromReferenceObject(id referenceObject);

@interface PFIncrementalStore ()

- (NSManagedObjectContext *)backingManagedObjectContext;

@end