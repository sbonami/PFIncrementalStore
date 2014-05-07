//
//  AppDelegate.m
//  OSX Example
//
//  Created by Andrea Cremaschi on 30/04/14.
//  Copyright (c) 2014 PFIncrementalStore. All rights reserved.
//

#import "AppDelegate.h"
#import <ParseOSX/ParseOSX.h>

#import "CoreDataStackManager.h"

const NSString * PARSE_APPLICATION_ID = @"YOUR_PARSE_APPLICATION_ID";
const NSString * PARSE_CLIENT_KEY = @"YOUR_PARSE_CLIENT_KEY";


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [Parse setApplicationId: PARSE_APPLICATION_ID
                  clientKey: PARSE_CLIENT_KEY];
}

-(NSManagedObjectContext *)context {
    return [[CoreDataStackManager sharedDataManager] managedObjectContext];
}

@end
