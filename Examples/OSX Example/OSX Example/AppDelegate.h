//
//  AppDelegate.h
//  OSX Example
//
//  Created by Andrea Cremaschi on 30/04/14.
//  Copyright (c) 2014 PFIncrementalStore. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (readonly) NSManagedObjectContext *context;

@end
