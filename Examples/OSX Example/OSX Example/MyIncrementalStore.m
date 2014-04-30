//
//  OrobieIncrementalStore.m
//  ParseOSXStarterProject
//
//  Created by Andrea Cremaschi on 24/04/14.
//  Copyright (c) 2014 Parse. All rights reserved.
//

#import "MyIncrementalStore.h"

@implementation MyIncrementalStore
+ (void)initialize {
    [NSPersistentStoreCoordinator registerStoreClass:self forStoreType:[self type]];
}

+ (NSString *)type {
    return NSStringFromClass(self);
}

+ (NSURL *)modelURL {
    return [[NSBundle mainBundle] URLForResource:@"CoreDataModel" withExtension:@"momd"];
}

+ (NSManagedObjectModel *)model {
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:[self modelURL]];
}
@end
