//
//  IssueDataManager.m
//  duczogno
//
//  Created by Andrea Cremaschi on 26/03/14.
//  Copyright (c) 2014 midapp. All rights reserved.
//

#import "CoreDataStackManager.h"
#import "MyIncrementalStore.h"

@interface CoreDataStackManager ()
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSManagedObjectModel* managedObjectModel;
@property (nonatomic, strong, readwrite) NSManagedObjectContext* managedObjectContext;
@end

@implementation CoreDataStackManager

#pragma mark Singleton

+ (instancetype)sharedDataManager {
    
    static id __sharedDataManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedDataManager = [self new];
    });
    return __sharedDataManager;
    
}


#pragma mark - Core Data Stack

- (NSManagedObjectContext*)managedObjectContext {
	if (_managedObjectContext != nil) {
		return _managedObjectContext;
	}
	
	_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	_managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
	
	return _managedObjectContext;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator {
	if (_persistentStoreCoordinator != nil) {
		return _persistentStoreCoordinator;
	}
	
     NSURL *storeURL = [ApplicationDocumentsDirectory() URLByAppendingPathComponent:[NSString stringWithFormat:@"LocalStore.sqlite"]];
    
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [MyIncrementalStore model]];
    
	NSError* error = nil;
    NSPersistentStore *store;

    MyIncrementalStore* incrementalStore = (MyIncrementalStore*)[_persistentStoreCoordinator addPersistentStoreWithType:[MyIncrementalStore type]
                                                                                                                  configuration:nil
                                                                                                                            URL:nil
                                                                                                                        options:nil error:&error];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption: @(YES)
                              };
    
    store= [incrementalStore.backingPersistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                            configuration:nil
                                                                                      URL:storeURL
                                                                                  options:options
                                                                                    error:&error];
    if (!store)
    {
		[self handleFatalCoreDataError:error];
		return nil;
	}
    
	return _persistentStoreCoordinator;
}

- (NSManagedObjectModel*)managedObjectModel {
	if (_managedObjectModel != nil) {
		return _managedObjectModel;
	}
	
	_managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
	
	return _managedObjectModel;
}

- (void)handleFatalCoreDataError:(NSError*)error {
	NSLog(@"Core data error:");
	NSLog(@"%@", error);
	NSLog(@"%@", [error userInfo]);
}

NSURL * ApplicationDocumentsDirectory()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return [NSURL fileURLWithPath: basePath];
}

@end
