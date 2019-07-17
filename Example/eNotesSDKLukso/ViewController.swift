//
//  ViewController.swift
//  eNotesSDKLukso_Example
//
//  Created by Smiacter on 2019/7/17.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import eNotesSDKLukso
import ethers

/// Eth params

let to = "0x18BDF4f15FDF3f53Ed0c1D7d81e1d9e09Ec28691"
let value1 = "0x16345785d8a0000"
let gasPrice = "0x0165A0BC00"
let estimateGas = "0x5208"
let nonce: UInt = 1
let chainId: UInt8 = 42

class ViewController: UIViewController {
    @IBOutlet weak var publicKeyTextView: UITextView!
    @IBOutlet weak var verifyPublicResultLabel: UILabel!
    @IBOutlet weak var signCounterLabel: UILabel!
    @IBOutlet weak var signTransactionHashTextView: UITextView!
    
    private var reader = CardReaderManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        reader.delegate = self
    }
    
    @IBAction func startAction(_ sender: UIButton) {
        reader.activateNFC()
    }
    
    private func ethTx() -> Transaction {
        
        let transaction = Transaction()
        transaction.toAddress = Address(string: to)
        transaction.gasPrice = BigNumber(hexString: gasPrice)
        transaction.gasLimit = BigNumber(hexString: estimateGas)
        transaction.nonce = nonce
        transaction.chainId = ChainId(rawValue: chainId)
        
        if let balanceNum = BigNumber(hexString: value1), let valueNum = balanceNum.sub(transaction.gasPrice.mul(transaction.gasLimit)) {
            transaction.value = valueNum
        }
        
        return transaction
    }
    
    private func showAlert(message: String?) {
        DispatchQueue.main.async {
            let alertVC = UIAlertController(title: "Warning", message: "There are some method not complete because NFC connect lost, Click Start to read again", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
        }
    }
}

extension ViewController: ReaderNFCReadable {
    
    func didDetectNFC() {
        reader.readTransactionSignCounter { [weak self] count in
            DispatchQueue.main.async {
                self?.signCounterLabel.text = "\(count)"
            }
        }
        
        reader.readBlockchainPublicKey { [weak self] publicKey in
            DispatchQueue.main.async {
                self?.publicKeyTextView.text = publicKey.toHexString().addHexPrefix()
            }
        }
        
        reader.verifyBlockchainPublicKey(closure: { [weak self] result in
            DispatchQueue.main.async {
                self?.verifyPublicResultLabel.text = "\(result ? "success" : "fail")"
            }
        })
        
        let transaction = ethTx()
        let serializeData = transaction.unsignedSerialize()
        let hashData = SecureData.keccak256(serializeData)
        
        reader.signTransactionHash(hashData: hashData) { [weak self] (r, s) in
            self?.reader.invlideNFC()
            
            transaction.populateSignature(withR: r, s: s, address: Address(string: "0x75CF0C2881D6371fAcEeaA76152231Ea91119C06"))
            let serialize = transaction.serialize()
            let rawtx = "0x" + BTCHexFromData(serialize)
            
            let rHex = "0x" + (transaction.signature?.r.toHexString() ?? "")
            let sHex = "0x" + (transaction.signature?.s.toHexString() ?? "")
            var v = UInt8(transaction.signature?.v ?? 0)
            if chainId > 0 {
                v = v + chainId * 2 + 35
            } else {
                v = v + 27
            }
            
            DispatchQueue.main.async {
                self?.signTransactionHashTextView.text = "r: \(rHex) \ns: \(sHex) \nv: \(v) \nrawTx: \(rawtx)"
            }
        }
    }
    
    func didNFCErrorOccurred(description: String?) {
        showAlert(message: description)
    }
}
