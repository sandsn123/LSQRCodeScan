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

protocol QRCodeScanToolDelegate: NSObjectProtocol {
    /// 扫描成功
    ///
    /// - Parameters: - result: 返回的字符串数组
    func scanQRCodeSuccess(result: [String])
    
    /// 扫描失败
    ///
    /// - Parameters: - error: 错误类型
    func scanQRCodeFailed(error: QRCodeScanError)
    
    
    /// 打开相册
    func scanQRCodeOpenAlbum()
    
    /// 打开相册
    func scanQRCodeExit()
}

class QRCodeScanTool: NSObject {
    static let shared = QRCodeScanTool()
    
    // MARK: - public property
    
    /// 代理
    weak var delegate: QRCodeScanToolDelegate?
    
    public var isScanning: Bool {
        return session.isRunning
    }
    
    
    
    /// 扫描框尺寸宽高(正方形)占比
    var scanBorderWidthRadio: CGFloat {
        get {
            return videoPreView.scanBorderWidthRadio
        }
        set {
            videoPreView.scanBorderWidthRadio = newValue
        }
    }
    /// 扫描动画风格，默认单线
    var scanAnimationStyle: ScanAnimationStyle {
        get {
            return videoPreView.scanAnimationStyle
        }
        set {
            videoPreView.scanAnimationStyle = newValue
        }
    }
    /// 边角位置, 默认与边框线同中心点
    var cornerLocation: CornerLocation {
        get {
            return videoPreView.cornerLocation
        }
        set {
            videoPreView.cornerLocation = newValue
        }
    }
    /// 边框线颜色，默认白色
    var borderColor: UIColor {
        get {
            return videoPreView.borderColor
        }
        set {
            videoPreView.borderColor = newValue
        }
    }
    /// 边框线宽度
    var borderLineWidth: CGFloat {
        get {
            return videoPreView.borderLineWidth
        }
        set {
            videoPreView.borderLineWidth = newValue
        }
    }

    /// 边角宽度
    var cornerWidth: CGFloat {
        get {
            return videoPreView.cornerWidth
        }
        set {
            videoPreView.cornerWidth = newValue
        }
    }
    /// 扫描区周边颜色的alpha值， 默认0.4
    var backgroundAlpha: CGFloat {
        get {
            return videoPreView.backgroundAlpha
        }
        set {
            videoPreView.backgroundAlpha = newValue
        }
    }
    
    var scannerColor:UIColor {
        get {
            return videoPreView.cornerColor
        }
        set {
            videoPreView.cornerColor = newValue
        }
    }
    
    /// 提示消息
    var tips: String {
        get {
            return videoPreView.tips
        }
        set {
            videoPreView.tips = newValue
        }
    }
    
    /// 手电筒提示
    var flashTips: String {
        get {
            return videoPreView.falshTips
        }
        set {
            videoPreView.falshTips = newValue
        }
    }
   
    /// 扫描作用域范围是否为原始view的范围，否则为扫描框的范围
    var isRectOfInterestFillBounds: Bool = false
    /// 相机可视范围  默认原始view的大小
    var isCamaraShowFillBounds: Bool = true
    /// 远距离时是否需要放大扫描
    var isNeedZoom: Bool = false
    /// 是否播放音效
    var isNeedPlaySound: Bool = false
    
    // MARK: - private property
    
    private var isSoundPlayed = false
    private lazy var captureDevice: AVCaptureDevice? = {
        return AVCaptureDevice.default(for: .video)
    }()
    /// 输入
    private var inPut: AVCaptureDeviceInput?
    /// videoData输出流，为了监听光线强弱
    private lazy var videoDataOutput: AVCaptureVideoDataOutput = {
        let videoDataOutput = AVCaptureVideoDataOutput()
        
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        return videoDataOutput
    }()
    /// 输出流
    private lazy var outPut: AVCaptureMetadataOutput = {
        let outPut = AVCaptureMetadataOutput.init()
        outPut.connection(with: .metadata)
        return outPut
    }()
    
    /// session
    private lazy var session: AVCaptureSession = {
        let session = AVCaptureSession.init()
        if session.canSetSessionPreset(.high){
            session.sessionPreset = .high
        }
        return session
    }()
    
    /// 打开/关闭手电筒
    private var torchMode: TorchMode {
        return videoPreView.torchMode
    }
    /// 是否显示手电筒
    private var isShowFlash: Bool {
        get {
            return videoPreView.isShowFlash
        }
        set {
            videoPreView.isShowFlash = newValue
        }
    }
    
    /// 相机视图
    private lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    /// 是否已经进行放大
    private var isHadZoomed: Bool = false
    
    /// 记录最后的缩放比例
    private lazy var currentZoomFator: CGFloat = 0
    
    /// 接收的预览View
    private weak var originalView: UIView? {
        didSet {
            guard let view = originalView else { return }
            view.backgroundColor = .black
            if !view.subviews.contains(videoPreView) {
                videoPreView = ScanView(frame: view.bounds)
                videoPreView.delegate = self
                view.addSubview(videoPreView)
            }
        }
    }
    
    /// 真正展示录像的view
    private var videoPreView: ScanView = ScanView()
    
    private var loadingView: ScanLoadingView?
    
    // MARK: - LifeCycle
    private override init(){
        super.init()
        #if targetEnvironment(simulator)
            delegate?.scanQRCodeFailed(error: .simulatorError)
            return
        #endif
        guard let device = captureDevice  else {
            delegate?.scanQRCodeFailed(error: .otherError)
            return
        }
        
        do {
            inPut = try AVCaptureDeviceInput.init(device: device)
        } catch  {
      
            delegate?.scanQRCodeFailed(error: .otherError)
        }
        
        outPut.setMetadataObjectsDelegate(self as AVCaptureMetadataOutputObjectsDelegate, queue: DispatchQueue.main)
        videoPreviewLayer.session = session
        videoPreviewLayer.videoGravity = .resizeAspectFill

    }
    
    /// 开启扫描前的配置(viewDidLoad调用)
    func setupScan(_ view: UIView) {
        
        /// 添加真的显示录像的view
        self.originalView = view
        
        
        /// 设置自动对焦和曝光
        resetAutoFocusAndExposure()
        
    }
    
    /// 停止扫描(viewDidDisAppear调用)
    public func stopScanning() {
        guard isScanning else { return }
        session.stopRunning()
        
        // 移除输入输出流
        if let inPut = inPut {
            session.removeInput(inPut)
        }
        session.removeOutput(outPut)
        session.removeOutput(videoDataOutput)
        
        videoPreviewLayer.removeFromSuperlayer()
        // 恢复缩放属性
        isHadZoomed = false
        
        videoPreView.removePinchGesture()
        // 停止动画
        videoPreView.stopAnimation()
        // 删除通知
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
    }
    
    /// 开启扫描(ViewDidAppear调用)
    public func startScanning() {
        
        guard let input = inPut  else { return }
        guard !isScanning else { return }
        isSoundPlayed = false
        // 添加预览图层
        let flag = originalView?.layer.sublayers?.contains(videoPreviewLayer)
        if flag == false || flag == nil {
            /// 相机可视范围
            self.videoPreviewLayer.frame = isCamaraShowFillBounds ? videoPreView.bounds : videoPreView.contentView.frame
            originalView?.layer.insertSublayer(videoPreviewLayer, at: 0)
        }
  
        // 检测相机权限
        checkCameraAuth()
        
        // 配置session
        if session.canAddInput(input) && session.canAddOutput(outPut) && session.canAddOutput(videoDataOutput) {
            session.addInput(input)
            session.addOutput(outPut)
            session.addOutput(videoDataOutput)
            // 设置元数据处理类型(注意, 一定要将设置元数据处理类型的代码添加到  会话添加输出之后)
            outPut.metadataObjectTypes = [.aztec, .qr]
            
        }else{
            // delegate错误回调
            delegate?.scanQRCodeFailed(error: .otherError)
            return
        }

        // 恢复缩放属性为未放大
        isHadZoomed = false

        // 设置扫描作用范围
        setRectOfInterest(videoPreView.bounds)
        // 启动会话
        session.startRunning()
        /// 为videoPreView添加捏合手势
        videoPreView.addPinchGesture()
        // 开启动画
        videoPreView.startAnimation()
        // 恢复相机原始焦距
        setVideoScale(1)
        // 添加扫描区域变化的监听，为了手动对焦后恢复自动对焦
        NotificationCenter.default.addObserver(self, selector: #selector(deviceSubjectAreaDidChange(notofication:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: nil)
    }
    /// 转菊花
    func starActivity() {
        if let window = UIApplication.shared.keyWindow, loadingView == nil {
            let loadingView = ScanLoadingView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            window.addSubview(loadingView)
            loadingView.backgroundColor = .clear
            loadingView.center = window.center
            self.loadingView = loadingView
        }
    }
    /// 停止转菊花
    func stopActivity() {

        self.loadingView?.removeFromSuperview()
        self.loadingView = nil
    }
    /// 播放系统音效
    func playSystemSound() {
        guard !isSoundPlayed else {
            return
        }
        let soundID: SystemSoundID = 1007
        AudioServicesPlaySystemSound(soundID)
        isSoundPlayed = true
    }
    
    /// 显示失败蒙版
    func showFailureMask(text: String?) {
        videoPreView.showFailureView(text: text)
        guard self.isScanning else {
            return
        }
        self.stopActivity()
        self.stopScanning()
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
        let rect = isRectOfInterestFillBounds ? origalRect : videoPreView.contentView.frame
        let intertRect = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: rect)
        outPut.rectOfInterest = intertRect
    }
}
// MARK: 对焦, 曝光, 焦距
private extension QRCodeScanTool {
    /// 自动对焦和曝光
    func resetAutoFocusAndExposure() {
        guard let device = captureDevice  else {
            return
        }
        /// 设置自动对焦
        do {
            try device.lockForConfiguration()
        } catch {}
        device.isSubjectAreaChangeMonitoringEnabled = true
        let centerPoint = CGPoint(x: 0.5, y: 0.5)
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
            device.focusPointOfInterest = centerPoint
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
            device.exposurePointOfInterest = centerPoint
        }
        device.unlockForConfiguration()
    }
    /// 手动对焦曝光
    func focusAndExposure(with point: CGPoint) {
        guard let device = captureDevice  else {
            return
        }
        do {
            try device.lockForConfiguration()
        } catch {}
        if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
            device.focusPointOfInterest = point
            device.focusMode = .autoFocus
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposurePointOfInterest = point
            device.exposureMode = .continuousAutoExposure
        }
        device.unlockForConfiguration()
    }
    
    // 拉大扫描
    func scanCamaraZoom(with objc: AVMetadataMachineReadableCodeObject) {
        let corners = objc.corners
        // corners存着二维码的四个点(上左、下左、下右、上右)
        if corners.count > 2 {
            let point1 = corners[1]
            let point2 = corners[2]
            let scace = 80 / (point2.x - point1.x)
            if scace > 1 {
                self.setVideoScale(scace)
            }
        }
    }
    // 设置相机放大
    func setVideoScale(_ scale: CGFloat) {
        guard let captureDevice = captureDevice else { return }
        var minZoomFactor: CGFloat = 1.0
        if #available(iOS 11.0, *) {
            minZoomFactor = captureDevice.minAvailableVideoZoomFactor
        }
        guard scale > minZoomFactor else { return }
        var fator = scale
        if scale > captureDevice.activeFormat.videoMaxZoomFactor {
            fator = captureDevice.activeFormat.videoMaxZoomFactor
        }
        do {
            try captureDevice.lockForConfiguration()
        } catch {
            delegate?.scanQRCodeFailed(error: .otherError)
            return
        }
        captureDevice.ramp(toVideoZoomFactor: fator, withRate: 10.0)
        
        captureDevice.unlockForConfiguration()
    }
    
    /// 监听扫描区域变化
    @objc func deviceSubjectAreaDidChange(notofication: Notification) {
        guard let device = captureDevice else { return }
        if device.isSubjectAreaChangeMonitoringEnabled && device.focusMode == .locked {
            resetAutoFocusAndExposure()
        }
    }
    
    func delayExecution(_ metadataObjects: [AVMetadataObject]) {
        self.stopActivity()
        self.stopScanning()
        
        var resultStrs = [String]()
        
        for obj in metadataObjects {
            
            if let codeObj = obj as? AVMetadataMachineReadableCodeObject, let codeString = codeObj.stringValue {
                resultStrs.append(codeString)
            }
        }
        self.delegate?.scanQRCodeSuccess(result: resultStrs)

    }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate 捕获到数据

extension QRCodeScanTool: AVCaptureMetadataOutputObjectsDelegate {
     public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard metadataObjects.count > 0 else { return }
        DispatchQueue.global().sync {
            // 转菊花
            starActivity()
            // 播放音效
            if isNeedPlaySound {
                playSystemSound()
            }
            
            DispatchQueue.main.async { [unowned self] in
                if self.isNeedZoom {
                    if !self.isHadZoomed {
                        if let obj = self.videoPreviewLayer.transformedMetadataObject(for: metadataObjects.last!) as? AVMetadataMachineReadableCodeObject {
                            self.scanCamaraZoom(with: obj)
                        }
                        self.isHadZoomed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.delayExecution(metadataObjects)
                        }
                    }
                    
                } else {
                    
                    self.delayExecution(metadataObjects)
                    
                }
            }
        }
    }
    
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension QRCodeScanTool: AVCaptureVideoDataOutputSampleBufferDelegate{
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let metadataDict = CMCopyDictionaryOfAttachments(nil,sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        
        guard let metadata = metadataDict as? [String:Any],
            let exifMetadata = metadata[kCGImagePropertyExifDictionary as String] as? [String:Any],
            let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? Double else{
                return
        }
        
        // 判断光线强弱
        if brightnessValue < -2.0 {
            
            isShowFlash = true
            
        }else{
            if torchMode == .on{
                isShowFlash = true
            }else{
               isShowFlash = false
            }
        }
        
    }
}

// MARK: - ScanViewDelegate
extension QRCodeScanTool: ScanViewDelegate {
    func scanViewTapBack() {
        delegate?.scanQRCodeExit()
    }
    
    func scanViewTapOpenAlbum() {
        delegate?.scanQRCodeOpenAlbum()
    }
    
    /// 手势调整焦距拉近拉远镜头
    func scanViewPinchAction(with pinch: UIPinchGestureRecognizer) {
        switch pinch.state {
        case .began: currentZoomFator = captureDevice?.videoZoomFactor ?? 1
        case .changed:
            let currentZoomFactor = currentZoomFator * pinch.scale
            setVideoScale(currentZoomFactor)
        default:()
        }
    }
    /// 实现点击扫描区域自动对焦
    func scanViewTapAction(with point: CGPoint) {
        let capturePoint = videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: point)
        focusAndExposure(with: capturePoint)
    }
    
    /// 点击手电筒打开或者关闭
    func scanViewFlashButtonClick() {
        guard let captureDevice = captureDevice,
            captureDevice.hasFlash else {
                return
        }
        guard captureDevice.isTorchModeSupported(torchMode.captureTorchMode) else{
            return
        }
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.torchMode = torchMode.captureTorchMode
        }catch{ return }
        captureDevice.unlockForConfiguration()
    }
    
    /// 点击失败蒙版
    func scanViewTapFailureMaskView(with tap: UIGestureRecognizer) {
        startScanning()
    }
}


