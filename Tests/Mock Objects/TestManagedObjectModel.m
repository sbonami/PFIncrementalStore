//
//  TestManagedObjectModel.m
//  Tests
//
//  Created by Scott BonAmi on 12/17/13.
//
//

#import "TestManagedObjectModel.h"

@implementation TestManagedObjectModel

- (id)init
{
    self = [super init];
    if (self) {
        
        [self setEntities:@[
                            [TestManagedObjectModel entityDescriptionForEntityWithName:@"TestEntity"]
                            ]];
    }
    return self;
}

+(NSEntityDescription *)entityDescriptionForEntityWithName:(NSString *)entityName {
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:entityName];
    return entity;
}

@end