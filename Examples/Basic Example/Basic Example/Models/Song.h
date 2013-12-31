//
//  Song.h
//  Basic Example
//
//  Created by Scott BonAmi on 12/30/13.
//  Copyright (c) 2013 Scott BonAmi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Artist, Genre;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSString * songTitle;
@property (nonatomic, retain) Artist *songArtist;
@property (nonatomic, retain) Genre *songGenre;

@end
