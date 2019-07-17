# eNotesSDKLukso

[![CI Status](https://img.shields.io/travis/Smiacter/eNotesSDKLukso.svg?style=flat)](https://travis-ci.org/Smiacter/eNotesSDKLukso)
[![Version](https://img.shields.io/cocoapods/v/eNotesSDKLukso.svg?style=flat)](https://cocoapods.org/pods/eNotesSDKLukso)
[![License](https://img.shields.io/cocoapods/l/eNotesSDKLukso.svg?style=flat)](https://cocoapods.org/pods/eNotesSDKLukso)
[![Platform](https://img.shields.io/cocoapods/p/eNotesSDKLukso.svg?style=flat)](https://cocoapods.org/pods/eNotesSDKLukso)

## Example

To run the example project, download the code and replace your team configure, you must open NFC support

## Requirements

- iOS 13.0+
- Xcode 11+
- Swift 4.2+

## Installation

- Download all frameworks in `Frameworks` folder, and add them to `Embedded Frameworks` at target -> General
- TODO: CocoaPods, Upcoming, eNotesSDKLukso will be available through [CocoaPods](https://cocoapods.org) after iOS 13 official release.

## Usage

First, import eNotesSDKLukso where you will use the SDK methods

```
import eNotesSDKLukso
```

New a reader object

```
var reader = CardReaderManager()
```

Set delegate

```
reader.delegate = self
```
Activate the NFC, that will call `didDetectNFC` delegate
```
reader.activateNFC()
```
Call methods `readTransactionSignCounter` `readBlockchainPublicKey` `verifyBlockchainPublicKey` `signTransactionHash` in delegate
```
/// call sdk card interaction methods in this delegate
func didDetectNFC() {
    // for example, readTransactionSignCounter
    reader.readTransactionSignCounter { count in
        print(count)
    }
}
```

## Author

eNotes

## License

eNotesSDKLukso is available under the MIT license. See the LICENSE file for more info.
