//
//  MREAppDelegate.m
//  MagicalRecord Example
//
//  Created by Scott BonAmi on 12/31/13.
//  Copyright (c) 2013 Scott BonAmi. All rights reserved.
//

#import "MREAppDelegate.h"

#import <Parse/Parse.h>
#import "MREIncrementalStore.h"
#import "MRERootViewController.h"

@implementation MREAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Override point for customization after application launch.
    [Parse setApplicationId:<# Parse Application ID #>
                  clientKey:<# Parse Client Key #>];
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [NSPersistentStoreCoordinator MR_newPersistentStoreCoordinator];
    MREIncrementalStore *incrementalStore = (MREIncrementalStore *)[persistentStoreCoordinator addPersistentStoreWithType:[MREIncrementalStore type]
                                                                                                            configuration:nil URL:nil options:nil error:nil];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption: @(YES)
                              };
    [incrementalStore.backingPersistentStoreCoordinator MR_addSqliteStoreNamed:@"MagicalRecord_Example.sqlite" withOptions:options];
    [NSPersistentStore MR_setDefaultPersistentStore:incrementalStore];
    [NSPersistentStoreCoordinator MR_setDefaultStoreCoordinator:incrementalStore.persistentStoreCoordinator];
    [NSManagedObjectContext MR_initializeDefaultContextWithCoordinator:incrementalStore.persistentStoreCoordinator];
    
    MRERootViewController *rootViewController = [[MRERootViewController alloc] init];
    UINavigationController *navRootViewController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    
    self.window.rootViewController = navRootViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [MagicalRecord cleanUp];
}

@end