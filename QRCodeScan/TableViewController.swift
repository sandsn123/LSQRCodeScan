//
//  TableViewController.swift
//  QRCodeScan
//
//  Created by sai on 2019/4/25.
//  Copyright © 2019 sai. All rights reserved.
//

import UIKit
import QRCodeScanTool

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        QRCodeScanKit.sharedInstance.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let vc = QRCodeScanKit.sharedInstance.instantiateQRCodeViewController()
            self.show(vc, sender: nil)
        }
    }

}

extension TableViewController: QRCodelcanKitDelegate {
    func qrCodeScanKitGetLocalizeValue(for value: String) -> String? {
        return nil
    }
    
    
    func scanStyleCustomConfigation(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController) {
//        QRCodeScanKit.sharedInstance.flashTips = "flashTips"
//        QRCodeScanKit.sharedInstance.tips = "tips"
//        QRCodeScanKit.sharedInstance.title = "扫描"
//        QRCodeScanKit.sharedInstance.scanTintColor = .green
//        QRCodeScanKit.sharedInstance.borderLineColor = .yellow
//        QRCodeScanKit.sharedInstance.borderLineWidth = 3.0
//        QRCodeScanKit.sharedInstance.isCamaraShowFillBounds = true
//        QRCodeScanKit.sharedInstance.isRectOfInterestFillBounds = true
        QRCodeScanKit.sharedInstance.isNeedZoom = true
//         QRCodeScanKit.sharedInstance.scanAnimationStyle = .default
        QRCodeScanKit.sharedInstance.isNeedPlaySound = true
    }
    
    func scanQrcodeSuccess(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController, result: [String]) {
        guard let code = result.first else {
            qrcodeScanKit.startScanning()
            return
        }
        dealwith(code: code, scanKit: qrcodeScanKit, from: viewController, failureMessage: "不是合法的二维码")
    }
    
    func scanQRCodeFailed(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController, error: QRCodeScanError) {
        print("扫描出错")
    }
    
    func detecorQRCodeSuccess(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController, codeString: String) {
        dealwith(code: codeString, scanKit: qrcodeScanKit, from: viewController, failureMessage: "未识别，请选择合法的二维码类型的图片")
    }
    
    func detecorQRCodeFailed(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController) {
        qrcodeScanKit.showFailureMask(text: "不是二维码")
    }

}

private extension TableViewController {
    func dealwith(code: String, scanKit: QRCodeScanKit, from viewController: UIViewController, failureMessage: String?) {
        /// 解析字符串
        /// 解析字符串
        if let url = URL(string: code), url.relativePath.contains("m/recharge") {
            guard let query = url.query, let code = query.components(separatedBy: "=").last else {
                return
            }
            let cardVc = TestViewController()
            cardVc.title = "recharge"
            cardVc.view.backgroundColor = .white
            viewController.navigationController?.pushViewController(cardVc, animated: true)
            print(code)
        } else if let url = URL(string: code), url.relativePath.contains("m/download") {
            guard let query = url.query, let skuCode = query.components(separatedBy: "=").last else {
                return
            }
            print(skuCode)
            let cardVc = TestViewController()
            cardVc.view.backgroundColor = .white
            cardVc.title = "download"
            viewController.navigationController?.pushViewController(cardVc, animated: true)
        } else if code.hasPrefix("/m/coupon") {
            let webVC = TestViewController()
            webVC.title = "coupon"
            webVC.view.backgroundColor = .white
            viewController.navigationController?.pushViewController(webVC, animated: true)
        } else {
            scanKit.showFailureMask(text: failureMessage)
        }
    }
}

class TestViewController: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
}
