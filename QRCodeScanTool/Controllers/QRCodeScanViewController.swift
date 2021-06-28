//
//  QRCodeScanViewController.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/22.
//  Copyright © 2019 sai. All rights reserved.
//

import UIKit
import Photos
import RSKImageCropper

class QRCodeScanViewController: UIViewController {
    
    private lazy var photoLibraryVC: UIImagePickerController = {
        let libraryVC = UIImagePickerController()
        libraryVC.sourceType = .photoLibrary
        libraryVC.delegate = self
        libraryVC.allowsEditing = false
        return libraryVC
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "相册", style: .plain, target: self, action: #selector(openAlbum))
        
        // 初始化配置
        QRCodeScanTool.shared.setupScan(self.view)
        QRCodeScanTool.shared.delegate = self
        // 自定义配置
    
        QRCodeScanKit.sharedInstance.delegate?.scanStyleCustomConfigation(QRCodeScanKit.sharedInstance, from: self)
        
        self.navigationItem.title = QRCodeScanKit.sharedInstance.title
        QRCodeScanTool.shared.startScanning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        QRCodeScanTool.shared.stopScanning()
    }
    
}
// 监听item点击
private extension QRCodeScanViewController {
    @objc func openAlbum() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized: // 允许
                DispatchQueue.main.async {
                    self.present(self.photoLibraryVC, animated: true, completion: nil)
                }
            case .notDetermined: // 不确定
                PHPhotoLibrary.requestAuthorization { [weak self] (state) in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.present(self.photoLibraryVC, animated: true, completion: nil)
                    }
                }
            case .restricted: // 访问受限
                showAuthAlert()
            case .denied:    // 拒绝访问
                showAuthAlert()
            case .limited:
                ()
            @unknown default:
                ()
            }
        }
    }
    
    private func showAuthAlert() {
        DispatchQueue.main.async {
            guard let settingUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            
            let alertVC = UIAlertController(title: "QRCode.Album.NotAuth.Title".s_localize(fallback: "相册访问受限"), message: "QRCode.Album.NotAuth.Title".s_localize(fallback: "当前设备不能访问相册"), preferredStyle: .alert)
            let cancle = UIAlertAction(title: "QRCode.Camera.NotAuth.Cancel".s_localize(fallback: "取消"), style: .cancel, handler: nil)
            let set = UIAlertAction(title: "QRCode.Camera.NotAuth.GoSet".s_localize(fallback: "去设置"), style: .default) { _ in
                UIApplication.shared.openURL(settingUrl)
            }
            alertVC.addAction(cancle)
            alertVC.addAction(set)
            self.present(alertVC, animated: true, completion: nil)
        }
    }
}

// MARK: QRCodeScanToolDelegate
extension QRCodeScanViewController: QRCodeScanToolDelegate {
    func scanQRCodeExit() {
        guard let naviVc = self.navigationController else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        naviVc.popViewController(animated: true)
    }
    
    func scanQRCodeOpenAlbum() {
        openAlbum()
    }
    
    public func scanQRCodeSuccess(result: [String]) {
        QRCodeScanKit.sharedInstance.delegate?.scanQrcodeSuccess(QRCodeScanKit.sharedInstance, from: self, result: result)
    }
    
    public func scanQRCodeFailed(error: QRCodeScanError) {
        
        switch error {
        case .simulatorError:
            QRCodeScanTool.shared.stopScanning()
        case .camaraAuthorityError:
            
            QRCodeScanTool.shared.stopScanning()
  
            guard let settingUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                return
            }
            var appName = Bundle.main.infoDictionary?["CFBundleDisplayName"]
            if appName == nil {
                appName = Bundle.main.infoDictionary?["CFBundleName"]
            }
            guard let name = appName as? String else { return }
            let msg = "QRCode.Auth.Not.Message".s_localize(fallback: "请允许" + name + "访问相机")
            let aletrVC = UIAlertController(title: "QRCode.Camera.NotAuth.Title".s_localize(fallback: "相机访问受限"), message: msg, preferredStyle: .alert)
            let cancle = UIAlertAction(title: "QRCode.Camera.NotAuth.Cancel".s_localize(fallback: "取消"), style: .cancel, handler: nil)
            let set = UIAlertAction(title: "QRCode.Camera.NotAuth.GoSet".s_localize(fallback: "去设置"), style: .default) { _ in
                UIApplication.shared.openURL(settingUrl)
            }
            aletrVC.addAction(cancle)
            aletrVC.addAction(set)
            self.present(aletrVC, animated: true, completion: nil)
        case .otherError:
            QRCodeScanTool.shared.stopScanning()
        }
        QRCodeScanKit.sharedInstance.delegate?.scanQRCodeFailed(error: error)
    }
}

// MARK: UIImagePickerControllerDelegate
extension QRCodeScanViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let viewController = RSKImageCropViewController(image: image, cropMode: .square)
            viewController.delegate = self
            viewController.alwaysBounceVertical = true
            viewController.alwaysBounceHorizontal = true
            if let navigationCntroller = self.navigationController {
                navigationCntroller.pushViewController(viewController, animated: true)
            } else {
                self.present(viewController, animated: true, completion: nil)
            }
            picker.dismiss(animated: false, completion: nil)
        } else {
            picker.dismiss(animated: true, completion: nil)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - RSKImageCropViewControllerDelegate

extension QRCodeScanViewController: RSKImageCropViewControllerDelegate {
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        
        DispatchQueue.global().sync {
            QRCodeScanTool.shared.starActivity()
            
            DispatchQueue.main.async { [unowned self] in
                guard let data = UIImagePNGRepresentation(croppedImage) else {
                    
                    QRCodeScanTool.shared.stopActivity()
                    if let navigationCntroller = controller.navigationController {
                        navigationCntroller.popViewController(animated: true)
                    } else {
                        controller.dismiss(animated: true, completion: nil)
                    }
                    QRCodeScanKit.sharedInstance.delegate?.detecorQRCodeFailed(QRCodeScanKit.sharedInstance, from: self)
                    return
                }
                guard let ciImage = CIImage(data: data) else {
                    QRCodeScanTool.shared.stopActivity()
                    if let navigationCntroller = controller.navigationController {
                        navigationCntroller.popViewController(animated: true)
                    } else {
                        controller.dismiss(animated: true, completion: nil)
                    }
                    QRCodeScanKit.sharedInstance.delegate?.detecorQRCodeFailed(QRCodeScanKit.sharedInstance, from: self)
                    return
                }
                
                // 创建探测器
                let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
                guard let features = detector?.features(in: ciImage), features.count > 0 else {
                    QRCodeScanTool.shared.stopActivity()
                    
                    if let navigationCntroller = controller.navigationController {
                        navigationCntroller.popViewController(animated: true)
                    } else {
                        controller.dismiss(animated: true, completion: nil)
                    }
                    QRCodeScanKit.sharedInstance.delegate?.detecorQRCodeFailed(QRCodeScanKit.sharedInstance, from: self)
                    return
                }
                
                if let qrFeature = features.first as? CIQRCodeFeature, let message = qrFeature.messageString, !message.isEmpty {
                    QRCodeScanTool.shared.stopActivity()
                    if let navigationCntroller = controller.navigationController {
                        navigationCntroller.popViewController(animated: true)
                    } else {
                        controller.dismiss(animated: true, completion: nil)
                    }
                    QRCodeScanKit.sharedInstance.delegate?.detecorQRCodeSuccess(QRCodeScanKit.sharedInstance, from: self, codeString: message)
                } else {
                    QRCodeScanTool.shared.stopActivity()
                    if let navigationCntroller = controller.navigationController {
                        navigationCntroller.popViewController(animated: true)
                    } else {
                        controller.dismiss(animated: true, completion: nil)
                    }
                    QRCodeScanKit.sharedInstance.delegate?.detecorQRCodeFailed(QRCodeScanKit.sharedInstance, from: self)
                }
            }
        }
    }
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        if let navigationCntroller = controller.navigationController {
            navigationCntroller.popViewController(animated: true)
        } else {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
