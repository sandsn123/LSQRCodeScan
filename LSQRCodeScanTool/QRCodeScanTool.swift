//
//  QRCodeScanTool.swift
//  QRCodeScan
//
//  Created by sai on 2019/4/9.
//  Copyright © 2019 sai. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

public enum LSQRCodeScanError {
    /// 模拟器错误
    case simulatorError
    /// 摄像头授权错误
    case camaraAuthorityError
    /// 未知
    case otherError
}

public protocol QRCodeScanToolDelegate: NSObjectProtocol {
    /// 扫描成功
    ///
    /// - Parameters: - result: 返回的字符串数组
    func scanQRCodeSuccess(result: [String])
    
    /// 扫描失败
    ///
    /// - Parameters: - error: 错误类型
    func scanQRCodeFailed(error: LSQRCodeScanError)
}

open class QRCodeScanTool: NSObject {
    public static let shared = QRCodeScanTool()
    
    // MARK: - public property
    
    /// 代理
    open weak var delegate: QRCodeScanToolDelegate?
    
    /// 是否开启蒙版
    open var isShowMask: Bool = true
    /// 蒙板层 默认黑色 alpha 0.5
    open var maskColor = UIColor(white: 0, alpha: 0.5)
    /// 扫描框尺寸宽高(正方形)
    open var scanCenterWH: CGFloat = UIScreen.main.bounds.size.width - 100
   
    /// 扫描作用域范围是否为原始view的范围，否则为扫描框的范围
    open var isRectOfInterestFillBounds: Bool = false
    /// 相机可视范围  默认原始view的大小
    open var isCamaraShowFillBounds: Bool = true
    /// 远距离时是否需要放大扫描
    open var isNeedZoom: Bool = true
    
    // MARK: - private property
    /// 输入
    private var inPut: AVCaptureDeviceInput?
    
    /// 输出
    private let outPut: AVCaptureMetadataOutput = {
        let outPut = AVCaptureMetadataOutput.init()
        outPut.connection(with: .metadata)
        return outPut
    }()
    
    /// session
    private let session: AVCaptureSession = {
        let session = AVCaptureSession.init()
        if session.canSetSessionPreset(.high){
            session.sessionPreset = .high
        }
        return session
    }()
    /// 拍照
    private let stillImageOutput: AVCaptureStillImageOutput = {
        let stillOutput = AVCaptureStillImageOutput()
        let setting: [String : Any] = [AVVideoCodecKey : AVVideoCodecJPEG]
        stillOutput.outputSettings = setting
        return stillOutput
    }()
    
    /// 相机视图
    private let videoPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    /// 需要删除的layers
    private var deleteLayers = [CAShapeLayer]()
    
    /// 是否已经进行放大
    private var isHadZoomed: Bool = false
    
    /// 接收的预览View
    private weak var originalView: UIView!
    
    /// 真正展示录像的view
    private weak var videoPreView: UIView!
    
    /// 扫描框View
    private var scanCenterView = UIView()
    
    // MARK: - LifeCycle
    private override init(){
        super.init()
        guard let device = AVCaptureDevice.default(for: .video)  else {
            return
        }
        do {
            inPut = try AVCaptureDeviceInput.init(device: device)
        } catch  {
            print(error)
            delegate?.scanQRCodeFailed(error: .otherError)
        }
        
        outPut.setMetadataObjectsDelegate(self as AVCaptureMetadataOutputObjectsDelegate, queue: DispatchQueue.main)
        videoPreviewLayer.session = session
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }
    
    /// 开启扫描
    public func startScan(_ view: UIView) {
        self.originalView = view
        /// 创建真正显示录像的view
        let videoView = UIView(frame: view.bounds)
        videoView.backgroundColor = UIColor.clear
        self.originalView.insertSubview(videoView, at: 0)
        self.videoPreView = videoView
        
        // 添加中间红色扫描框
        scanCenterView.frame = getScanRect(view.bounds)
        scanCenterView.layer.borderWidth = 1
        scanCenterView.layer.borderColor = UIColor.red.cgColor
        view.addSubview(scanCenterView)
        #if targetEnvironment(simulator)
        delegate?.scanQRCodeFailed(error: .simulatorError)
        #endif
        
        checkCameraAuth()
        
        guard let input = inPut  else {
            return
        }
        
        if session.canAddInput(input) && session.canAddOutput(outPut) {
            session.addInput(input)
            session.addOutput(outPut)
            // 设置元数据处理类型(注意, 一定要将设置元数据处理类型的代码添加到  会话添加输出之后)
            outPut.metadataObjectTypes = [.ean13, .ean8, .upce, .code39, .code93, .code128, .code39Mod43, .qr]
            
        }else{
            // delegate错误回调
            delegate?.scanQRCodeFailed(error: .otherError)
            return
        }
        
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
        
        // 添加预览图层
        let flag = videoPreView.layer.sublayers?.contains(videoPreviewLayer)
        if flag == false || flag == nil {
            self.videoPreviewLayer.frame = isCamaraShowFillBounds ? videoPreView.bounds : getScanRect(videoPreView.bounds)
            videoPreView.layer.insertSublayer(videoPreviewLayer, at: 0)
        }
        
        // 蒙版层
        if isShowMask{
            
            let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: videoPreView.frame.size.width, height: videoPreView.frame.size.height))
            // 默认view的中心
            let centerPath = UIBezierPath(rect: getScanRect(videoPreView.bounds))

            path.append(centerPath.reversing())
            let rectLayer = CAShapeLayer()
            rectLayer.path = path.cgPath
            rectLayer.fillColor = maskColor.cgColor
            videoPreView.layer.addSublayer(rectLayer)
            deleteLayers.append(rectLayer)
        }
        // 启动会话
        session.startRunning()
        setVideoScale(1)
        // 设置扫描作用范围
        setRectOfInterest(videoPreView.bounds)
    }
    
    public func stopScan() {
        session.stopRunning()
        if let inPut = inPut {
            session.removeInput(inPut)
        }
        session.removeOutput(outPut)
        removeShapLayer()
        isHadZoomed = false
    }
}

private extension QRCodeScanTool {
    /// 检查相机权限
    ///
    /// - Returns: 是否
    func checkCameraAuth() {
        
        let state = AVCaptureDevice.authorizationStatus(for: .video)
        switch state {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] (granted) in
                DispatchQueue.main.async(execute: {
                    if granted {}
                    else {
                        self.delegate?.scanQRCodeFailed(error: .camaraAuthorityError)
                    }
                })
            }
        case .denied, .restricted:
            delegate?.scanQRCodeFailed(error: .camaraAuthorityError)
        case .authorized:()
        }
        
    }
    /// 设置扫描作用范围(非相机可视范围)
    func setRectOfInterest(_ origalRect: CGRect) {
        let rect = isRectOfInterestFillBounds ? origalRect : getScanRect(origalRect)
        let intertRect = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: rect)
        outPut.rectOfInterest = intertRect
    }
    /// 获取扫描框尺寸
    func getScanRect(_ origalRect: CGRect) -> CGRect {
       return CGRect(x: (origalRect.size.width - scanCenterWH) / 2, y: (origalRect.size.height - scanCenterWH) / 2, width: scanCenterWH, height: scanCenterWH)
    }
    
    /// 移除所有图层
    func removeShapLayer() {
        for layer in deleteLayers {
            layer.removeFromSuperlayer()
        }
        deleteLayers.removeAll()
    }
    
    // 拉大扫描
    func scanCamaraZoom(with objc: AVMetadataMachineReadableCodeObject) {
        let corners = objc.corners
        // corners存着二维码的四个点(上左、下左、下右、上右)
        if corners.count > 2 {
            let point1 = corners[1]
            let point2 = corners[2]
            let scace = 150 / (point2.x - point1.x)
            if scace > 1 {
                self.setVideoScale(scace)
            }
        }
    }
    // 设置相机放大
    func setVideoScale(_ scale: CGFloat) {
        do {
            try inPut?.device.lockForConfiguration()
        } catch {
            print(error)
            return
        }
        guard let connection = getConnections(AVMediaType.video.rawValue, fromConnections: stillImageOutput.connections) else {
            return
        }
        guard let maxScale = stillImageOutput.connection(with: AVMediaType.video)?.videoMaxScaleAndCropFactor else {
            return
        }
        var curentScale = scale
        if scale > maxScale {
            curentScale = maxScale
        }
        let zoom = curentScale / connection.videoScaleAndCropFactor
        connection.videoScaleAndCropFactor = curentScale
        inPut?.device.unlockForConfiguration()
        
        UIView.animate(withDuration: 1.0) { [unowned self] in
            self.videoPreView.transform = CGAffineTransform.init(scaleX: zoom, y: zoom)
        }
    }
    
    func getConnections(_ mediaType: String, fromConnections: [AVCaptureConnection]) -> AVCaptureConnection? {
        for connection in fromConnections {
            for port in connection.inputPorts {
                if port.mediaType.rawValue == mediaType {
                    return connection
                }
            }
        }
        return nil
    }
}

private extension String {
    /// 生成CIImage
    ///
    /// - Parameters: - size: 大小
    /// - Returns: CIImage
    func generateCIImage(size: CGFloat) -> CIImage? {
        
        //1.二维码滤镜
        let contentData = self.data(using: String.Encoding.utf8)
        let fileter = CIFilter(name: "CIQRCodeGenerator")
        
        fileter?.setValue(contentData, forKey: "inputMessage")
        fileter?.setValue("H", forKey: "inputCorrectionLevel")
    
        //2.生成处理
        guard let outImage = fileter?.outputImage else {
            return nil
        }
        let scale = size / outImage.extent.size.width;
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let transformImage = fileter?.outputImage?.transformed(by: transform)
        
        return transformImage
    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate

extension QRCodeScanTool: AVCaptureMetadataOutputObjectsDelegate {
     public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard metadataObjects.count > 0 else { return }
        var resultStrs = [String]()
        
        for obj in metadataObjects {
            
            if let codeObj = obj as? AVMetadataMachineReadableCodeObject, let codeString = codeObj.stringValue {
                resultStrs.append(codeString)
            }
        }
        if isNeedZoom && !isHadZoomed {
            if let obj = videoPreviewLayer.transformedMetadataObject(for: metadataObjects.last!) as? AVMetadataMachineReadableCodeObject {
                scanCamaraZoom(with: obj)
            }
            isHadZoomed = true
            return
        }
        stopScan()
        delegate?.scanQRCodeSuccess(result: resultStrs)
    }
}

public extension QRCodeScanTool {
    /// 图片识别
    func recognizeQRCode(_ image: UIImage) -> String? {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        let features = detector?.features(in: CIImage.init(image: image)!)
        guard (features?.count)! > 0 else {
            return nil
        }
        let feature = features?.first as? CIQRCodeFeature
        return feature?.messageString
    }
    

     /// 生成二维码
    /// - parameter codeString: 接收的字符串 size:大小
     /// - returns: 自定义二维码
    func generateQRCode(codeString: String, size: CGFloat = 200) -> UIImage? {
        
        guard let ciImage = codeString.generateCIImage(size: size) else {
            return nil
        }
        let image = UIImage(ciImage: ciImage)
        return image
    }
}


