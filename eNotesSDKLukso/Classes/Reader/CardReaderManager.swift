//
//  CardReaderManager.swift
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

import UIKit
import CoreNFC

public protocol ReaderNFCReadable: class {
    func didDetectNFC()
    func didNFCErrorOccurred(description: String?)
}

public class CardReaderManager: NSObject {
    /// get public key callback - return public key  data
    public typealias PublicKeyClosure = ((Data) -> ())?
    /// verify public key callback - return success if verify passed
    public typealias VerifyClosure = ((Bool) -> ())?
    /// signature count callback - return int type
    public typealias CountClosure = ((Int32) -> ())?
    /// sign tx callback - return r, s
    public typealias SignTxHashClosure = ((Data, Data) -> ())?
    
    public weak var delegate: ReaderNFCReadable?
    
    // NFC
    private var nfcTagReaderSession: NFCTagReaderSession?
    private var nfcTag: NFCISO7816Tag?
    /// NFC detect callback - private use
    private var nfcDetectClosure: (() -> ())?
    private var publicKeyClosure: PublicKeyClosure
    private var verifyClosure: VerifyClosure
    private var countClosure: CountClosure
    private var signTxHashClosure: SignTxHashClosure
    private var _signTxHashClosure: ((String, String) -> ())?
    
    // MARK: - Apdu handle
    private var apdu: Apdu = .publicKey
    private var random = ""
    private var publicKey: Data?
    private var status = ""
    private var certP1 = 0
    private var cert = Data()
    private var txSignature = ""
    private var card = Card()
}

// MARK: - Public
extension CardReaderManager {
    
    public func activateNFC() {
        nfcTagReaderSession = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self)
        nfcTagReaderSession?.begin()
    }
    
    public func invlideNFC() {
        nfcTagReaderSession?.invalidate()
        nfcTagReaderSession = nil
    }
    
    /// Get public key
    public func readBlockchainPublicKey(closure: PublicKeyClosure) {
        guard nfcTagReaderSession != nil else { return }
        _getPublicKey(closure: closure)
    }
    
    /// Verify public key
    public func verifyBlockchainPublicKey(closure: VerifyClosure) {
        guard nfcTagReaderSession != nil else { return }
        _verifyPublicKey(closure: closure)
    }
    
    /// Get signature count
    public func readTransactionSignCounter(closure: CountClosure) {
        guard nfcTagReaderSession != nil else { return }
        _getCount(closure: closure)
    }
    
    /// Get ethereum raw transaction before send raw transaction
    ///
    /// - Parameters:
    ///  - toAddress: receiver address
    ///  - value: available ethereum balance
    ///  - gasPrice: gas price
    ///  - estimateGas: estimate gas
    ///  - nonce: nonce
    ///  - data: transfer data if send an ERC20 token
    ///  - chainId: chainId
    ///  - closure:
    ///   - String: r
    ///   - String: s
    ///   - UInt8:  v
    ///   - String: signed tx
    public func signTransactionHash(hashData: Data?, closure: SignTxHashClosure) {
        
        func signEthRawTx(hashData: Data?, closure: SignTxHashClosure) {
            
            guard let hashData = hashData, hashData.count == 32 else { return }
            
            let hexHash = hashData.toHexString()
            
            signTxHash(hashStr: hexHash)
            _signTxHashClosure = { address, signedHash in
                let rStr = signedHash.subString(to: 64)
                let sStr = signedHash.subString(from: 64)
                guard let bigR = BTCBigNumber(hexString: rStr), let bigS = BTCBigNumber(hexString: sStr) else {
                    return
                }
                // MARK: be careful, use the unsafe pointer cast!!! check it!!!
                let s = unsafeBitCast(bigS.bignum, to: UnsafeMutablePointer<BIGNUM>.self)
                
                let ctx = BN_CTX_new()
                BN_CTX_start(ctx)
                
                let group = EC_GROUP_new_by_curve_name(714) // NID_secp256k1 -> 714 define in 'OpenSSL-Universal' -> 'obj_mac.h'
                let order = BN_CTX_get(ctx)
                let halfOrder = BN_CTX_get(ctx)
                EC_GROUP_get_order(group, order, ctx)
                BN_rshift1(halfOrder, order)
                
                if BN_cmp(s, halfOrder) > 0 {
                    BN_sub(s, order, s)
                }
                BN_CTX_end(ctx)
                BN_CTX_free(ctx)
                EC_GROUP_free(group)
                
                guard let rData = BTCBigNumber(bignum: bigR.bignum).unsignedBigEndian, let sData = BTCBigNumber(bignum: bigS.bignum).unsignedBigEndian else {
                    return
                }
                closure?(rData, sData)
            }
        }
        
        guard nfcTagReaderSession != nil else { return }
        signEthRawTx(hashData: hashData, closure: closure)
    }
}

// MARK: - NFCTagReaderSessionDelegate
extension CardReaderManager: NFCTagReaderSessionDelegate {
    
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        invlideNFC()
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        for tag in tags {
            switch tag {
            case .iso7816(let tag7816):
                session.connect(to: tag) { [weak self] (error) in
                    guard error == nil else { return }
                    guard !tag7816.initialSelectedAID.isEmpty else { return }
                    self?.nfcTag = tag7816
                    self?.nfcDetectClosure?()
                    self?.delegate?.didDetectNFC()
                }
            default: ()
            }
        }
    }
}

// MARK: - Private
extension CardReaderManager {
    
    private func _getPublicKey(closure: PublicKeyClosure) {
        sendApdu(apdu: .publicKey)
        publicKeyClosure = {
            closure?($0)
        }
    }
    
    private func _verifyPublicKey(closure: VerifyClosure) {
        sendApdu(apdu: .verifyBlockchain)
        verifyClosure = {
            closure?($0)
        }
    }
    
    private func _getCount(closure: CountClosure) {
        sendApdu(apdu: .cardStatus)
        countClosure = {
            closure?($0)
        }
    }
    
    private func sendApdu(apdu: Apdu) {
        
        var apduData: Data?
        switch apdu {
        case .verifyDevice:
            apduData = getApduData(tag: TagChallenge, apdu: apdu)
        case .verifyBlockchain:
            apduData = getApduData(tag: TagChallenge, apdu: apdu)
        default:
            apduData = Data(hex: apdu.value)
        }
        
        guard let data = apduData else { return }
        guard let apdu7816 = NFCISO7816APDU(data: data) else { return }
        guard let nfcTag = self.nfcTag else { return }
        nfcTag.sendCommand(apdu: apdu7816) { [weak self] (data, _, _, error) in
            guard error == nil else {
                self?.invlideNFC()
                self?.delegate?.didNFCErrorOccurred(description: error?.localizedDescription)
                return
            }
            switch apdu {
            case .publicKey:
                self?.savePublicKey(rawApdu: data)
            case .cardStatus:
                self?.saveCardStatus(rawApdu: data)
            case .verifyBlockchain:
                self?.verifyBlockchain(rawApdu: data)
            case .certificate:
                self?.judgeCertificate(rawApdu: data)
            default: break
            }
        }
    }
    
    /// Get apdu data, for type verifyDevice, verifyBlockchain
    ///
    /// - Parameters:
    ///  - tag: TLV's T: tag
    ///  - apdu: type verifyDevice, verifyBlockchain
    private func getApduData(tag: String, apdu: Apdu) -> Data? {
        do {
            random = try SecRandom.generate(bytes: 32).toHexString()
            let serialData = Tlv.encode(tv: Tlv.generate(tag: Data(hex: tag), value: Data(hex: random)))
            let apduStr = apdu.value + serialData.toHexString()
            let apduData = Data(hex: apduStr)
            return apduData
        } catch {}
        
        return nil
    }
    
    private func getTv(rawApdu: Data) -> Tv? {
        return Tlv.decode(data: rawApdu)
    }
    
    /// Save public key for global use
    private func savePublicKey(rawApdu: Data) {
        guard let tv = getTv(rawApdu: rawApdu) else { return }
        let tag = Data(hex: TagBlockChainPublicKey)
        guard let publicKey = tv[tag] else { return }
        self.publicKey = publicKey
        publicKeyClosure?(publicKey)
    }
    
    /// Save card safe status for global use
    private func saveCardStatus(rawApdu: Data) {
        guard let tv = getTv(rawApdu: rawApdu) else { return }
        let tag = Data(hex: TagTransactionSignatureCounter)
        guard let status = tv[tag] else { return }
        self.status = status.toHexString()
        
        let signCounter = BTCBigNumber(string: "0x\(self.status)", base: 16).int32value
        countClosure?(signCounter)
    }
    
    private func verifyBlockchain(rawApdu: Data) {
        guard let tv = getTv(rawApdu: rawApdu) else { return }
        let typeSignature = Data(hex: TagVerificationSignature), typeSalt = Data(hex: TagSalt)
        guard let signature = tv[typeSignature], let salt = tv[typeSalt], let publicKey = publicKey else {
            return
        }
        let org = random.appending(salt.toHexString())
        let r = signature.subdata(in: 0..<32).toHexString()
        let s = signature.subdata(in: 32..<signature.count).toHexString()
        guard Verification.verify(r: r, s: s, org: org, publicKey: publicKey.toHexString()) else {
            verifyClosure?(false)
            return
        }
        
        verifyClosure?(true)
    }
    
    private func signTxHash(hashStr: String) {
        apdu = .signPrivateKey
        let tv = Tlv.generate(tag: Data(hex: TagTransactionHash), value: Data(hex: hashStr))
        let serialData = Tlv.encode(tv: tv)
        let apduStr = apdu.value + serialData.toHexString()
        let data = Data(hex: apduStr)
        guard let apdu7816 = NFCISO7816APDU(data: data) else { return }
        nfcTag?.sendCommand(apdu: apdu7816) { [weak self] (data, _, _, error) in
            guard error == nil else {
                self?.invlideNFC()
                self?.delegate?.didNFCErrorOccurred(description: error?.localizedDescription)
                return
            }
            self?.signTxHash(rawApdu: data)
        }
    }
    
    private func signTxHash(rawApdu: Data) {
        guard let tv = getTv(rawApdu: rawApdu) else { return }
        let tag = Data(hex: TagTransactionSignature)
        guard let signature = tv[tag], let privateStr = BTCHexFromData(signature) else {
            return
        }
        
        txSignature = privateStr
        sendApdu(apdu: .certificate("\(self.certP1)"))
    }
    
    private func judgeCertificate(rawApdu: Data) {
        cert.append(rawApdu)
        if rawApdu.count < 255 {
            let tv = Tlv.decode(data: cert)
            let tag = Data(hex: TagDeviceCertificate)
            guard let certValue = tv[tag] else { return }
            cert = certValue
            getAddress()
        } else {
            sendApdu(apdu: .certificate("\(certP1 + 1)"))
        }
    }
    
    private func getAddress() {
        guard !cert.isEmpty else { return }
        guard let certParser = CertificateParser(hexCert: cert.toBase64String()) else { return }
        card = certParser.toCard()
        let address = EnoteFormatter.address(publicKey: publicKey)
        
        _signTxHashClosure?(address, txSignature)
    }
}
