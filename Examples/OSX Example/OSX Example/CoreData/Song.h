//
//  Song.h
//  OSX Example
//
//  Created by Andrea Cremaschi on 30/04/14.
//  Copyright (c) 2014 PFIncrementalStore. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Artist, Genre;

@interface Song : NSManagedObject

@property (nonatomic, retain) NSString * songTitle;
@property (nonatomic, retain) Artist *songArtist;
@property (nonatomic, retain) Genre *songGenre;

@end
