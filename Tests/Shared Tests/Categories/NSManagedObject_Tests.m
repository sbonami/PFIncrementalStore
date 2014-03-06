//
//  NSManagedObject_Tests.m
//  Shared Tests
//
//  Created by Scott BonAmi on 3/4/14.
//
//

#import <Kiwi/Kiwi.h>
#import "PFIncrementalStore_PrivateMethods.h"

#import "TestManagedObjectModel.h"

@interface TestNSManagedObject : NSManagedObject
@property (nonatomic, strong) NSString *testAttribute;
@end

@implementation TestNSManagedObject
@synthesize testAttribute;
@end

SPEC_BEGIN(Category_NSManagedObject_Tests)

describe(@"setPFFile:forKey:", ^{
    __block PFFile *testFile = nil;
    __block NSData *testFileData = nil;
    __block NSManagedObject *testObject = nil;
    
    beforeEach(^{
        testFile = [PFFile nullMock];
        testFileData = [NSData nullMock];
        
        TestManagedObjectModel *testManagedObjectModel = [[TestManagedObjectModel alloc] init];
        NSPersistentStoreCoordinator *testPersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:testManagedObjectModel];
        
        NSManagedObjectContext *testManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [testManagedObjectContext setPersistentStoreCoordinator:testPersistentStoreCoordinator];
        
        NSEntityDescription *testEntityDescription = [NSEntityDescription entityForName:@"TestEntity" inManagedObjectContext:testManagedObjectContext];
        testObject = [[NSManagedObject alloc] initWithEntity:testEntityDescription insertIntoManagedObjectContext:testManagedObjectContext];
        
        [testFile stub:@selector(getData) andReturn:testFileData];
    });
    
    it(@"should update the Managed Object by setting the PFFile's data as the value for the key", ^{
        NSString *testKey = @"testAttribute";
        
        [[testObject should] receive:@selector(setValue:forUndefinedKey:) withArguments:testFileData, testKey];
        [testObject setPFFile:testFile forKey:testKey];
    });
});

SPEC_END