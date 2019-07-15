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

1. First, import eNotesSDKLukso where you will use the SDK methods

```
import eNotesSDKLukso
```

2. Call methods

Get public key

```
/// callback return the hex string value
CardReaderManager.shared.readBlockchainPublicKey { publicKey in
    print(publicKey)  
}
```

Verify public key, call this method you should get public key first
```
/// callback return bool value
CardReaderManager.shared.verifyPublicKeyAction { success in
    print(success)       
}
```

Get signature count

```
/// callback return int value
CardReaderManager.shared.readTransactionSignCounter { count in
    print(count)  
}
```

Sign transaction hash, call this method you should get public key first

```
/// Example value
let to = "0x18BDF4f15FDF3f53Ed0c1D7d81e1d9e09Ec28691"
let value = "0x16345785d8a0000"
let gasPrice = "0x0165A0BC00"
let estimateGas = "0x5208"
let nonce: UInt = 1

/// callback return signed raw transaction
CardReaderManager.shared.signTransactionHash(toAddress: to, value: value, gasPrice: gasPrice, estimateGas: estimateGas, nonce: nonce, chainId: 42) { r, s, v, rawTx in
    print("r: \(r) \ns: \(s) \nv: \(v) \nrawTx: \(rawTx)")
}
```

## Author

eNotes

## License

eNotesSDKLukso is available under the MIT license. See the LICENSE file for more info.
