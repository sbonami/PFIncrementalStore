//
//  RootViewController.h
//  ParseOSXStarterProject
//
//  Created by Andrea Cremaschi on 24/04/14.
//  Copyright (c) 2014 Parse. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PFUser;

@interface RootViewController : NSViewController

// UI
@property (weak) IBOutlet NSTableView *artistsTableView;

// Content controllers
@property (strong) IBOutlet NSArrayController *artistsController;


- (IBAction)createArtist:(id)sender;

@end
