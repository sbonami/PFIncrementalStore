//
//  Genre.h
//  Basic Example
//
//  Created by Scott BonAmi on 12/30/13.
//  Copyright (c) 2013 Scott BonAmi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Song;

@interface Genre : NSManagedObject

@property (nonatomic, retain) NSString * genreName;
@property (nonatomic, retain) NSSet *genreSongs;
@end

@interface Genre (CoreDataGeneratedAccessors)

- (void)addGenreSongsObject:(Song *)value;
- (void)removeGenreSongsObject:(Song *)value;
- (void)addGenreSongs:(NSSet *)values;
- (void)removeGenreSongs:(NSSet *)values;

@end
