// PFProxyUser.m
//
// Copyright (c) 2013 Scott BonAmi
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PFProxyUser.h"
#import "PFReservedObject.h"
#import "NSManagedObject_PFIncrementalStore.h"

static NSString *staticReservedObjectSubclass = nil;
static NSManagedObjectContext *staticDefaultContext = nil;
@implementation PFProxyUser

+(void)initialize {
    [self registerSubclass];
}

+(NSString *)reservedObjectSubclass {
    return staticReservedObjectSubclass;
}

+(void)setReservedObjectSubclass:(NSString *)reservedObjectSubclass {
    staticReservedObjectSubclass = reservedObjectSubclass;
}

+(NSManagedObjectContext *)defaultContext {
    return staticDefaultContext;
}

+(void)setDefaultContext:(NSManagedObjectContext *)defaultContext {
    staticDefaultContext = defaultContext;
}

-(NSManagedObject *)managedObject {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:staticReservedObjectSubclass];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K = %@", kPFIncrementalStoreResourceIdentifierAttributeName, self.objectId]];
    id result = [staticDefaultContext executeFetchRequest:fetchRequest error:nil];
    return (result) ? [result objectAtIndex:0] : nil ;
}

@end