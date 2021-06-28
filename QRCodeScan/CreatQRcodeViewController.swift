//
//  CreatQRcodeViewController.swift
//  QRCodeScan
//
//  Created by sai on 2019/4/9.
//  Copyright © 2019 sai. All rights reserved.
//

import UIKit
import Photos
import QRCodeScanTool
import RSKImageCropper

class CreatQRcodeViewController: UIViewController {

    @IBOutlet weak var contentTextView: UITextField!
    @IBOutlet weak var qrcodeImageView: UIImageView!
    private lazy var photoLibraryVC: UIImagePickerController = {
        let libraryVC = UIImagePickerController()
        libraryVC.sourceType = .photoLibrary
        libraryVC.delegate = self
        libraryVC.allowsEditing = false
        return libraryVC
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "相册", style: .plain, target: self, action: #selector(openAlbum))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func creatQRcode(_ sender: UIButton) {
        guard let codeString = contentTextView.text, !codeString.isEmpty else {
            return
        }
        let image = UIImage.generateQRCode(codeString, qrcodeImageView.frame.size.width)
        qrcodeImageView.image = image
    }
}
// 监听item点击
private extension CreatQRcodeViewController {
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
                let alertVC = UIAlertController(title: "访问失败", message: "当前设备不能访问相册", preferredStyle: .alert)
                self.present(alertVC, animated: true, completion: nil)
            @unknown default:
                ()
            }
        }
    }
    
}
// MARK: UIImagePickerControllerDelegate
extension CreatQRcodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let viewController = RSKImageCropViewController(image: image, cropMode: .square)
            viewController.delegate = self
            viewController.alwaysBounceHorizontal = true
            viewController.alwaysBounceVertical = true
            self.navigationController?.pushViewController(viewController, animated: true)
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

extension CreatQRcodeViewController: RSKImageCropViewControllerDelegate {
    func imageCropViewController(_ controller: RSKImageCropViewController, didCropImage croppedImage: UIImage, usingCropRect cropRect: CGRect, rotationAngle: CGFloat) {
        
        controller.navigationController?.popViewController(animated: true)
        self.qrcodeImageView.image = croppedImage
    }
    
    func imageCropViewControllerDidCancelCrop(_ controller: RSKImageCropViewController) {
        controller.navigationController?.popViewController(animated: true)
    }
}
