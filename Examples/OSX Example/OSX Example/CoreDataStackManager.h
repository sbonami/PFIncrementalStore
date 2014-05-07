//
//  IssueDataManager.h
//  duczogno
//
//  Created by Andrea Cremaschi on 26/03/14.
//  Copyright (c) 2014 midapp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface CoreDataStackManager : NSObject

@property (nonatomic, readonly) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (nonatomic, readonly) NSManagedObjectModel* managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext* managedObjectContext;

+ (instancetype)sharedDataManager;

@end
