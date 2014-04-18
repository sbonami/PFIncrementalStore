//
//  BEIncrementalStore.m
//  Basic Example
//
//  Created by Scott BonAmi on 12/27/13.
//  Copyright (c) 2013 Scott BonAmi. All rights reserved.
//

#import "BEIncrementalStore.h"

@implementation BEIncrementalStore

+ (void)initialize {
    [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:[self type]];
}

+ (NSString *)type {
    return NSStringFromClass(self);
}

+ (NSURL *)modelURL {
    return [[NSBundle mainBundle] URLForResource:@"Basic_Example" withExtension:@"momd"];
}

+ (NSManagedObjectModel *)model {
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:[self modelURL]];
}

@end