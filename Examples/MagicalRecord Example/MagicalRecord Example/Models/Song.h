//
//  Song.h
//  MagicalRecord Example
//
//  Created by Scott BonAmi on 1/2/14.
//  Copyright (c) 2014 Scott BonAmi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Artist, Genre;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSString * songTitle;
@property (nonatomic, retain) Artist *songArtist;
@property (nonatomic, retain) Genre *songGenre;

@end
