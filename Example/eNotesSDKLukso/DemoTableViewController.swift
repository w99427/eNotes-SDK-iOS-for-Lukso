//
//  BluetoothTableViewController.swift
//  eNotesSDKTest
//
//  Created by Smiacter on 2018/10/18.
//  Copyright © 2018 eNotes. All rights reserved.
//

import UIKit
import eNotesSDKLukso
import ethers

class DemoTableViewController: UITableViewController {
    @IBOutlet weak var publicKeyLbl: UILabel!
    @IBOutlet weak var publicKeyVerifyStatusLbl: UILabel!
    @IBOutlet weak var countLbl: UILabel!
    @IBOutlet weak var txLbl: UILabel!
    private var publicKey: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func getPublicKeyAction(_ sender: UIButton) {
        CardReaderManager.shared.readBlockchainPublicKey { [weak self] publicKey in
            DispatchQueue.main.async {
                self?.publicKey = publicKey
                self?.publicKeyLbl.text = publicKey
            }
        }
    }
    
    @IBAction func verifyPublicKeyAction(_ sender: Any) {
        guard publicKey != nil else {
            showAlert()
            return
        }
        CardReaderManager.shared.verifyBlockchainPublicKey { [weak self] success in
            DispatchQueue.main.async {
            self?.publicKeyVerifyStatusLbl.text = "status: \(success ? "success" : "fail")"
            }
        }
    }
    
    @IBAction func getCountAction(_ sender: UIButton) {
        CardReaderManager.shared.readTransactionSignCounter { [weak self] count in
            DispatchQueue.main.async {
                self?.countLbl.text = "count: \(count)"
            }
        }
    }
    
    @IBAction func generateTxAction(_ sender: UIButton) {
        guard publicKey != nil else {
            showAlert()
            return
        }
        
        let to = "0x18BDF4f15FDF3f53Ed0c1D7d81e1d9e09Ec28691"
        let value = "0x16345785d8a0000"
        let gasPrice = "0x0165A0BC00"
        let estimateGas = "0x5208"
        let nonce: UInt = 1
        let chainId: UInt8 = 42
        
        let transaction = Transaction()
        transaction.toAddress = Address(string: to)
        transaction.gasPrice = BigNumber(hexString: gasPrice)
        transaction.gasLimit = BigNumber(hexString: estimateGas)
        transaction.nonce = nonce
        transaction.chainId = ChainId(rawValue: chainId)
        
        if let balanceNum = BigNumber(hexString: value), let valueNum = balanceNum.sub(transaction.gasPrice.mul(transaction.gasLimit)) {
            transaction.value = valueNum
        }
        
        let serializeData = transaction.unsignedSerialize()
        let hashData = SecureData.keccak256(serializeData)
        
        CardReaderManager.shared.signTransactionHash(hashData: hashData) { (r, s) in
            
            // TODO: 问辉哥发送地址是否需要SDK帮忙算
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
                self.txLbl.text = "r: \(rHex) \ns: \(sHex) \nv: \(v) \nrawTx: \(rawtx)"
            }
        }
    }
    
    private func showAlert() {
        let alertVC = UIAlertController(title: "Warning", message: "You must get public key first", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
}
