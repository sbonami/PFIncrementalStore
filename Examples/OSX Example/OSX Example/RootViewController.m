//
//  RootViewController.m
//  ParseOSXStarterProject
//
//  Created by Andrea Cremaschi on 24/04/14.
//  Copyright (c) 2014 Parse. All rights reserved.
//

#import "RootViewController.h"

#import <ParseOSX/ParseOSX.h>
#import <CoreData/CoreData.h>
#import "CoreDataStackManager.h"

#import "Model.h"

@interface RootViewController () <NSTableViewDataSource, NSTableViewDelegate>

@end


@implementation RootViewController

-(id)init {
    self = [self initWithNibName:@"RootViewController" bundle:nil];
    if (self) {
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}


-(void)awakeFromNib {
    [super awakeFromNib];
    
    
    NSManagedObjectContext *context = [[CoreDataStackManager sharedDataManager] managedObjectContext];
    self.artistsController.managedObjectContext = context;

    [self.artistsTableView reloadData];
    
}

#pragma mark -tableviewdelegate


#pragma mark - IBActions
- (IBAction)createArtist:(id)sender {
    
    NSManagedObjectContext *context = [CoreDataStackManager sharedDataManager].managedObjectContext;
    Artist  *newArtist = [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:context];


}


@end
