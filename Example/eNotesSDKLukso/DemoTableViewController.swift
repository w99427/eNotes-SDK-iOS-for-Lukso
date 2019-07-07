//
//  BluetoothTableViewController.swift
//  eNotesSDKTest
//
//  Created by Smiacter on 2018/10/18.
//  Copyright © 2018 eNotes. All rights reserved.
//

import UIKit
import eNotesSDKLukso

class DemoTableViewController: UITableViewController {
    @IBOutlet weak var publicKeyLbl: UILabel!
    @IBOutlet weak var publicKeyVerifyStatusLbl: UILabel!
    @IBOutlet weak var countLbl: UILabel!
    @IBOutlet weak var txLbl: UILabel!
    private var publicKey: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /// 获取公钥
    @IBAction func getPublicKeyAction(_ sender: UIButton) {
        CardReaderManager.shared.getPublicKey { [weak self] publicKey in
            DispatchQueue.main.async {
                self?.publicKey = publicKey
                self?.publicKeyLbl.text = publicKey
            }
        }
    }
    
    /// 验证公钥
    @IBAction func verifyPublicKeyAction(_ sender: Any) {
        guard publicKey != nil else {
            showAlert()
            return
        }
        CardReaderManager.shared.verify { [weak self] success in
            DispatchQueue.main.async {
            self?.publicKeyVerifyStatusLbl.text = "status: \(success ? "success" : "fail")"
            }
        }
    }
    
    /// 获取交易签名次数
    @IBAction func getCountAction(_ sender: UIButton) {
        CardReaderManager.shared.getCount { [weak self] count in
            DispatchQueue.main.async {
                self?.countLbl.text = "count: \(count)"
            }
        }
    }
    
    /// 交易签名
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
        
        CardReaderManager.shared.getEthRawTransaction(toAddress: to, value: value, gasPrice: gasPrice, estimateGas: estimateGas, nonce: nonce) { (rawTx) in
            DispatchQueue.main.async {
                self.txLbl.text = "raw tx: \(rawTx)"
            }
        }
    }
    
    private func showAlert() {
        let alertVC = UIAlertController(title: nil, message: "You must get public key first", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
}
