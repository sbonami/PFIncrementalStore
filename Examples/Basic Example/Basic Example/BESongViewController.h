//
//  BESongViewController.h
//  Basic Example
//
//  Created by Scott BonAmi on 12/30/13.
//  Copyright (c) 2013 Scott BonAmi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Artist;

@interface BESongViewController : UITableViewController

@property (nonatomic, strong) Artist *artist;

-(id)initWithArtist:(Artist *)artist;

@end