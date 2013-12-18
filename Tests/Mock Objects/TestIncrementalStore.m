//
//  TestIncrementalStore.m
//  Tests
//
//  Created by Scott BonAmi on 12/17/13.
//
//

#import "TestIncrementalStore.h"

@implementation TestIncrementalStore

+ (void)initialize {
    [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:[self type]];
}

+ (NSString *)type {
    return NSStringFromClass(self);
}

+ (NSManagedObjectModel *)model {
    return [[TestManagedObjectModel alloc] init];
}

@end