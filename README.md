PFIncrementalStore
==================

[![Build Status](https://travis-ci.org/sbonami/PFIncrementalStore.png?branch=master)](https://travis-ci.org/sbonami/PFIncrementalStore)
[![Stories in Ready](https://badge.waffle.io/sbonami/PFIncrementalStore.png?label=ready)](https://waffle.io/sbonami/PFIncrementalStore)
[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/sbonami/pfincrementalstore/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

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

Check out the PFIncrementalStore [github page](http://sbonami.github.io/PFIncrementalStore/) for installation instructions.

## References

Apple has recently updated their programming guide for
`NSIncrementalStore`, which is [available from the Developer
Center](https://developer.apple.com/library/prerelease/ios/documentation/DataManagement/Conceptual/IncrementalStorePG/ImplementationStrategy/ImplementationStrategy.html).
You may find this useful in debugging the behavior of
`PFIncrementalStore`, and its interactions with your app's Core Data
stack.

## Contributors

- [Scott BonAmi](http://github.com/sbonami)  ([@snb828](https://twitter.com/snb828))
- [Aaron Abt](http://github.com/Laeger)

## Disclaimer

PFIncrementalStore is not affiliated, associated, authorized,
endorsed by, or in any way officially connected with Parse.com,
Parse Inc., or any of its subsidiaries or its affiliates. The
official Parse web site is available at [www.parse.com](https://www.parse.com). 

## License

PFIncrementalStore is available under the MIT license.
See the LICENSE file for more info.

## Contributing

1. Fork repository on GitHub.
1. Create a feature branch (should indicate intention `add_feature_x` or issue `##_issue_name`).
1. Make changes.
1. Test changes.
1. Ensure all tests pass.
1. Submit pull request using GitHub.

Do not modify `PFIncrementalStore.podspec`, the maintainers will handle those changes.
