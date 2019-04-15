//
//  ScanDemoViewController.swift
//  QRCodeScan
//
//  Created by sai on 2019/4/11.
//  Copyright © 2019 sai. All rights reserved.
//

import UIKit
import Photos
import LSQRCodeScanTool

class ScanDemoViewController: UIViewController {
    
    private lazy var photoLibraryVC: UIImagePickerController = {
        let libraryVC = UIImagePickerController()
        libraryVC.sourceType = .photoLibrary
        libraryVC.delegate = self
        libraryVC.allowsEditing = true
        return libraryVC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "相册", style: .plain, target: self, action: #selector(openAlbum))
        setupScanConfigation()
    
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       
    }

    func setupScanConfigation() {
        
        QRCodeScanTool.shared.delegate = self
        QRCodeScanTool.shared.startScan(self.view)
    }
}
// 监听item点击
private extension ScanDemoViewController {
    @objc func openAlbum() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized: // 允许
                self.present(self.photoLibraryVC, animated: true, completion: nil)
            case .notDetermined: // 不确定
                PHPhotoLibrary.requestAuthorization { [weak self] (state) in
                    guard let self = self else { return }
                    self.present(self.photoLibraryVC, animated: true, completion: nil)
                }
            case .restricted: // 访问受限
                ()
            case .denied:    // 拒绝访问
                let alertVC = UIAlertController(title: "访问失败", message: "当前设备不能访问", preferredStyle: .alert)
                self.present(alertVC, animated: true, completion: nil)
            @unknown default:
                ()
            }
        }
    }
    
}

// MARK: QRCodeScanToolDelegate
extension ScanDemoViewController: QRCodeScanToolDelegate {
    func scanQRCodeSuccess(result: [String]) {
        guard result.count > 0 else { return }
        let alertVC = UIAlertController(title: nil, message: result.first, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "确认", style: .cancel) { [unowned self] _ in
            QRCodeScanTool.shared.startScan(self.view)
        }
        alertVC.addAction(cancel)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func scanQRCodeFailed(error: LSQRCodeScanError) {
        
        switch error {
        case .simulatorError:
            print("模拟器错误")
        case .camaraAuthorityError:
            print("相机未授权")
            QRCodeScanTool.shared.stopScan()
            self.navigationController?.popViewController(animated: true)

            guard let settingUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            var appName = Bundle.main.infoDictionary?["CFBundleDisplayName"]
            if appName == nil {
                appName = Bundle.main.infoDictionary?["CFBundleName"]
            }
            guard let name = appName as? String else { return }
            let aletrVC = UIAlertController(title: "相机访问受限", message: "请允许" + name + "访问相机", preferredStyle: .alert)
            let cancle = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            let set = UIAlertAction(title: "设置", style: .default) { _ in
                UIApplication.shared.openURL(settingUrl)
            }
            aletrVC.addAction(cancle)
            aletrVC.addAction(set)
            self.present(aletrVC, animated: true, completion: nil)
        case .otherError:
            print("未知错误")
        }
    }
}

// MARK: UIImagePickerControllerDelegate
extension ScanDemoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        // 取出所选照片
        guard let pickImage = info[.editedImage] as? UIImage else { return }
        guard let data = pickImage.pngData() else { return }
        guard let ciImage = CIImage(data: data) else { return }
        
        // 创建探测器
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])
        guard let features = detector?.features(in: ciImage), features.count > 0 else { return }
        
        let qrFeature = features.first as! CIQRCodeFeature
        
        picker.dismiss(animated: true) { [unowned self] in
            
            if let message = qrFeature.messageString, !message.isEmpty,
                let url = URL(string: message),
                UIApplication.shared.canOpenURL(url) {
                
                UIApplication.shared.openURL(url)
            } else {
                let alertVC = UIAlertController(title: nil, message: qrFeature.messageString ?? "未识别", preferredStyle: .alert)
                let cancel = UIAlertAction(title: "确认", style: .cancel, handler: nil)
                alertVC.addAction(cancel)
                self.present(alertVC, animated: true, completion: nil)
            }
        }
    }
}
