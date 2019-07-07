//
//  CardReaderDefinition.swift
//  eNotesSdk
//
//  Created by Smiacter on 2018/9/27.
//  Copyright © 2018 eNotes. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

let VersionCertificate: Int = 1
let VersionApdu = "1.2.0"

/// NFC device master key, used to authenticate the deivce
let MasterKey = "41435231323535552D4A312041757468"

/// The data field of APDUs are encoded in SIMPLE-TLV which is defined in ISO/IEC 7816-4, Tag definition here
let TagDeviceCertificate = "30"
let TagDevicePrivateKey = "52"
let TagBlockChainPrivateKey = "54"
let TagBlockChainPublicKey = "55"
let TagChallenge = "70"
let TagSalt = "71"
let TagVerificationSignature = "73"
let TagTransactionSignatureCounter = "90"
let TagTransactionHash = "91"
let TagTransactionSignature = "92"
let TagApduVersion = "12"
let TagFreeze = "93"
let TagFreezeStatus = "94"
let TagUnFreezeLeftCount = "95"

/// error in card read processing
///
/// none: everything is ok, on error there
/// deviceNotFound: no bluetooth or reader device found
/// absent: card absent when connecting
/// parsing: card is in apdu parsing
/// apduReaderError: apdu command read error
/// apduVersionTooLow: version of the apdu protocol is too low
/// verifyError: verify certificate, device or blockchain error
public enum CardReaderError {
    case none
    case deviceNotFound
    case absent
    case absentLimit
    case parsing
    case apduReaderError
    case apduVersionTooLow
    case verifyError
}

/// All apdu command
///
/// none: everything is ok, on error there
/// aid: Application id in device which you can identify your application to send apdu
/// version: support apdu protocol version
/// publicKey: blockchain public key, get it by send apdu command
/// cardStatus: safe or danger
/// certificate: card certificate, need verify, get public key by 'call'(public key -> certificate private key)
///  - String: buffer offset index of device certificate, 0x00 ~ 0x07
/// verifyDevice: public key stored in card when 'verifyCertificate'(public key -> device private key)
/// verifyBlockchain: public key get from send 'publicKey' command(public key -> blockchain private key)
/// signPrivateKey: use transaction info(has been hashed) and private key(stored in device, nobody kown) to sign to get final transaction data
public enum Apdu: Equatable {
    case publicKey
    case cardStatus
    case certificate(String)
    case verifyDevice
    case verifyBlockchain
    case signPrivateKey
    
    var value: String {
        switch self {
        case .publicKey:
            return "00CA0055"
        case .certificate(let p1):
            return "00CA0\(p1)30"
        case .cardStatus:
            return "00CA0090"
        case .verifyDevice:
            return "0088520022"
        case .verifyBlockchain:
            return "0088540022"
        case .signPrivateKey:
            return "00A0540022"
        }
    }
}

public struct Card {
    // readed card info by asn1 decoder
    public var tbsCertificateAndSig = Data()
    public var tbsCertificate = Data()
    public var issuer = ""
    public var issueTime = Date()
    public var deno = 0
    public var blockchain: Blockchain = .bitcoin
    public var network: Network = .testnet
    public var contract: String?
    public var publicKey = ""
    public var serialNumber = ""
    public var manufactureBatch = ""
    public var manufactureTime = Date()
    public var r = ""
    public var s = ""
    // custom info
    public var address = ""
    public var isSafe = true
    public var publicKeyData: Data?
    public var isFrozen: Bool?
    // ERC20 token info
    public var name: String?
    public var symbol: String?
    public var decimals = 0
    
    public init() {}
}

/// card type, we support btc and eth for now
public enum Blockchain: Int {
    case bitcoin
    case ethereum
}

public enum Network: Int {
    case mainnet
    case testnet
    case ethereum
    case kovan
    case ropsten
    case rinkeby
}
