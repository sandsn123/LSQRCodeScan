//
//  CreatQRcodeViewController.swift
//  QRCodeScan
//
//  Created by sai on 2019/4/9.
//  Copyright © 2019 sai. All rights reserved.
//

import UIKit
import LSQRCodeScanTool

class CreatQRcodeViewController: UIViewController {

    @IBOutlet weak var contentTextView: UITextField!
    @IBOutlet weak var qrcodeImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func creatQRcode(_ sender: UIButton) {
        guard let codeString = contentTextView.text, !codeString.isEmpty else {
            return
        }
        qrcodeImageView.image = QRCodeScanTool.shared.generateQRCode(codeString: codeString, size: qrcodeImageView.frame.size.width)
    }
}
