//
//  MainWindow.m
//  ParseOSXStarterProject
//
//  Created by Andrea Cremaschi on 24/04/14.
//  Copyright (c) 2014 Parse. All rights reserved.
//

#import "MainWindow.h"
#import "RootViewController.h"

#import "CoreDataStackManager.h"

@interface MainWindow ()
@end



@implementation MainWindow

-(void)dealloc {
    self.rootViewController = nil;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    
    RootViewController *rootVC = [RootViewController new];

    self.contentView = rootVC.view;
    self.rootViewController = rootVC;
    
    
    //NSManagedObjectContext *localContext = [[CoreDataStackManager sharedDataManager] managedObjectContext] ;
    
}

- (IBAction)synchronize:(id)sender {

    NSError *error;
    NSManagedObjectContext *context = [[CoreDataStackManager sharedDataManager] managedObjectContext];
    
    if (![context save: &error]) {
        NSAlert *alert = [NSAlert alertWithMessageText:@"Error" defaultButton:@"Ok" alternateButton:@"Try again" otherButton:nil informativeTextWithFormat:@"An error occurred:\n%@", error.localizedDescription];
        alert.alertStyle = NSCriticalAlertStyle;
        
        [alert runModal];
        
    }
    
}

@end
