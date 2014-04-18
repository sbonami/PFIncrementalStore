//
//  MREIncrementalStore.m
//  MagicalRecord Example
//
//  Created by Scott BonAmi on 12/31/13.
//  Copyright (c) 2013 Scott BonAmi. All rights reserved.
//

#import "MREIncrementalStore.h"

@implementation MREIncrementalStore

+ (void)initialize {
    [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:[self type]];
}

+ (NSString *)type {
    return NSStringFromClass(self);
}

+ (NSManagedObjectModel *)model {
    return [NSManagedObjectModel MR_defaultManagedObjectModel];
}

@end