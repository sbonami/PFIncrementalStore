//
//  MainWindow.h
//  ParseOSXStarterProject
//
//  Created by Andrea Cremaschi on 24/04/14.
//  Copyright (c) 2014 Parse. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ParseOSX/ParseOSX.h>

@class RootViewController;
@interface MainWindow : NSWindow

@property (strong) RootViewController *rootViewController;

@end
