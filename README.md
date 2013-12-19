PFIncrementalStore
==================

[![Build Status](https://travis-ci.org/sbonami/PFIncrementalStore.png?branch=master)](https://travis-ci.org/sbonami/PFIncrementalStore)
[![Stories in Ready](https://badge.waffle.io/sbonami/PFIncrementalStore.png?label=ready)](https://waffle.io/sbonami/PFIncrementalStore)  

An NSIncrementalStore subclass for Parse

PFIncrementalStore is an
[`NSIncrementalStore`](http://nshipster.com/nsincrementalstore/)
subclass that uses
[Parse](https://www.parse.com) to
automatically request resources as properties and relationships are
needed.

## Incremental Store Persistence

`PFIncrementalStore` does not persist data directly. Instead, _it
manages a persistent store coordinator_ that can be configured to
communicate with any number of persistent stores of your choice.

``` objective-c
NSURL *storeURL = [[self applicationDocumentsDirectory]
URLByAppendingPathComponent:@"BasicExample.sqlite"];
NSDictionary *options = @{ NSInferMappingModelAutomaticallyOption :
@(YES) };

NSError *error = nil;
if (![incrementalStore.backingPersistentStoreCoordinator
addPersistentStoreWithType:NSSQLiteStoreType configuration:nil
URL:storeURL options:options error:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
}
```

If your data set is of a more fixed or ephemeral nature, you may want to
use `NSInMemoryStoreType`.

## Requirements

PFIncrementalStore requires a subscription to Parse, a valid Parse App, API
Key and Secret, and minor programming knowledge. Parse subscription and
API information can be obtained at
[https://www.parse.com/](https://www.parse.com/)

PFIncrementalStore requires Xcode 4.4 with the [iOS
5.0](http://developer.apple.com/library/ios/#releasenotes/General/WhatsNewIniPhoneOS/Articles/iOS5.html)
SDK, as well as [Parse](https://www.parse.com/downloads/ios/parse-library/latest) 1.2 or
higher.

## Installation

[CocoaPods](http://cocoapods.org) is the recommended way to add
PFIncrementalStore to your project.

Here's an example podfile that installs PFIncrementalStore and its
dependency, Parse:

### Podfile

```ruby
platform :ios, '5.0'

pod 'PFIncrementalStore'
```

Note the specification of iOS 5.0 as the platform; leaving out the 5.0
will cause CocoaPods to fail with the following message:

> [!] PFIncrementalStore is not compatible with iOS 4.3.

## References

Apple has recently updated their programming guide for
`NSIncrementalStore`, which is [available from the Developer
Center](https://developer.apple.com/library/prerelease/ios/documentation/DataManagement/Conceptual/IncrementalStorePG/ImplementationStrategy/ImplementationStrategy.html).
You may find this useful in debugging the behavior of
`PFIncrementalStore`, and its interactions with your app's Core Data
stack.

## Credits

PFIncrementalStore was created by [Scott
BonAmi](https://github.com/sbonami/).

### Creators

[Scott BonAmi](http://github.com/sbonami)  
[@snb828](https://twitter.com/snb828)

## License

PFIncrementalStore is available under the MIT license.
See the LICENSE file for more info.
