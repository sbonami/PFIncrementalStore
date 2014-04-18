//
//  Artist.h
//  Basic Example
//
//  Created by Scott BonAmi on 12/30/13.
//  Copyright (c) 2013 Scott BonAmi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Song;

@interface Artist : NSManagedObject

@property (nonatomic, retain) NSString * artistName;
@property (nonatomic, retain) NSSet *artistSongs;
@end

@interface Artist (CoreDataGeneratedAccessors)

- (void)addArtistSongsObject:(Song *)value;
- (void)removeArtistSongsObject:(Song *)value;
- (void)addArtistSongs:(NSSet *)values;
- (void)removeArtistSongs:(NSSet *)values;

@end
