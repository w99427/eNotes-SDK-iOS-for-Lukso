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

/// All apdu command
///
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
    public var blockchain: String?
    public var network: Int?
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
    // ERC20 token info
    public var name: String?
    public var symbol: String?
    public var decimals = 0
    
    public init() {}
}
