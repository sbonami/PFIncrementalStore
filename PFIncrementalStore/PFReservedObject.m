// PFReservedObject.m
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

#import <CoreData/CoreData.h>
#import <Parse-iOS-SDK/Parse.h>

#import "PFReservedObject.h"
#import "PFIncrementalStore.h"
#import "NSManagedObject_PFIncrementalStore.h"

@implementation PFReservedObject

-(PFObject *)reservedObject {
    NSUInteger index = [@[@"_User", @"_Role", @"_Product", @"_Installation"] indexOfObject:self.parseQueryClassName];
    NSAssert(index != NSNotFound, @"PFReservedObject subclass should return one of 'PFUser', 'PFRole', 'PFProduct', or 'PFInstallation'");
    
    PFQuery *query = [PFQuery queryWithClassName:self.parseQueryClassName];
    return [query getObjectWithId:self.pf_resourceIdentifier];
}

#pragma mark - Message Forwarding

-(BOOL)respondsToSelector:(SEL)aSelector {
    if (self.reservedObject) {
        return [self.reservedObject respondsToSelector:aSelector];
    }
    return [super respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([self.reservedObject respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:self.reservedObject];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

-(id)valueForUndefinedKey:(NSString *)key {
    return [self.reservedObject valueForKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    [self.reservedObject setValue:value forKey:key];
}

@end