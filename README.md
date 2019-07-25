# eNotes iOS SDK for LUKSO

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

## Example

To run the example project, download the code and replace your team configure, please notice that NFC support must be opened.

## Author

[eNotes.io](https://enotes.io)

## License

eNotesSDKLukso is available under the MIT license. See the LICENSE file for more info.
