//
//  Genre.h
//  OSX Example
//
//  Created by Andrea Cremaschi on 30/04/14.
//  Copyright (c) 2014 PFIncrementalStore. All rights reserved.
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
