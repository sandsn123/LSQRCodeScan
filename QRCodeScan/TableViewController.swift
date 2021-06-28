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
        dealwith(code: code, scanKit: qrcodeScanKit, from: viewController, failureMessage: "不是球友圈二维码")
    }
    
    func scanQRCodeFailed(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController, error: QRCodeScanError) {
        print("扫描出错")
    }
    
    func detecorQRCodeSuccess(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController, codeString: String) {
        dealwith(code: codeString, scanKit: qrcodeScanKit, from: viewController, failureMessage: "未识别，请选择球友圈二维码类型的图片")
    }
    
    func detecorQRCodeFailed(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController) {
        qrcodeScanKit.showFailureMask(text: "不是二维码")
    }

}

private extension TableViewController {
    func dealwith(code: String, scanKit: QRCodeScanKit, from viewController: UIViewController, failureMessage: String?) {
        /// 解析字符串
        guard let url = URL(string: code) else {
            scanKit.showFailureMask(text: failureMessage)
            return
        }
        guard let components = url.query?.components(separatedBy: "&"), components.count > 0 else {
            scanKit.showFailureMask(text: failureMessage)
            return
        }
        var dict = [String : String]()
        for component in components {
            let arr = component.components(separatedBy: "=")
            if arr.count == 2 {
                dict[arr[0]] = arr[1]
            }
        }
        guard let channel = dict["channel"],
            channel == "ball_friends",
            let idString = dict["groupID"],
            let id = Int(idString) else {
                scanKit.showFailureMask(text: failureMessage)
                return
        }
        print(id)
    }
}
