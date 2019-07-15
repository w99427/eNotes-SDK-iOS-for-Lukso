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
        
        CardReaderManager.shared.signTransactionHash(toAddress: to, value: value, gasPrice: gasPrice, estimateGas: estimateGas, nonce: nonce, chainId: 42) { [weak self] r, s, v, rawTx in
            DispatchQueue.main.async {
                self?.txLbl.text = "r: \(r) \ns: \(s) \nv: \(v) \nrawTx: \(rawTx)"
            }
        }
    }
    
    private func showAlert() {
        let alertVC = UIAlertController(title: "Warning", message: "You must get public key first", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true, completion: nil)
    }
}
