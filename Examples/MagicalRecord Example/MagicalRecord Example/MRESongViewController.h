//
//  MRESongViewController.h
//  MagicalRecord Example
//
//  Created by Scott BonAmi on 1/2/14.
//  Copyright (c) 2014 Scott BonAmi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Artist;

@interface MRESongViewController : UITableViewController

@property (nonatomic, strong) Artist *artist;

-(id)initWithArtist:(Artist *)artist;

@end
