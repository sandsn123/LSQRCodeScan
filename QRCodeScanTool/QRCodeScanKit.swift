//
//  QRCodeScanKit.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/25.
//  Copyright © 2019 sai. All rights reserved.
//

import Foundation

public protocol QRCodelcanKitDelegate: class {
    
    /// 自定义扫描样式配置
    func scanStyleCustomConfigation(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController)
    
    /// 扫描成功
    ///
    /// - Parameters: result: 识别的字符串数组
    func scanQrcodeSuccess(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController, result: [String])
    
    /// 扫描错误
    ///
    /// - Parameters: error: 错误类型
    func scanQRCodeFailed(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController, error: QRCodeScanError)
    
    /// 相册识别二维码成功
    ///
    /// - Parameters: codeString: 字符串
    func detecorQRCodeSuccess(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController, codeString: String)
    
    /// 相册识别二维码失败
    ///
    /// - Parameters: codeString: 字符串
    func detecorQRCodeFailed(_ qrcodeScanKit: QRCodeScanKit, from viewController: UIViewController)
    
    /// 获取国际化语言
    ///
    /// - Result: 若返回nil，则按照默认规则
    func qrCodeScanKitGetLocalizeValue() -> String?
}

public extension QRCodelcanKitDelegate {
    func scanQRCodeFailed(error: QRCodeScanError){}
    func qrCodeScanKitGetLocalizeValue() -> String? {
        return nil
    }
}

public class QRCodeScanKit {
    
    public static let sharedInstance = QRCodeScanKit()
    
    public static let bundle = Bundle(for: QRCodeScanKit.self)
    
    public weak var delegate: QRCodelcanKitDelegate?
    
    /// 页面标题
    public var title: String = "二维码扫描"
    
    /// 是否正在扫描
    public var isScanning: Bool {
        return QRCodeScanTool.shared.isScanning
    }
    
    /// 是否开启自动放大
    public var isNeedZoom: Bool {
        get {
            return QRCodeScanTool.shared.isNeedZoom
        }
        set {
             QRCodeScanTool.shared.isNeedZoom = newValue
        }
    }
    
    /// 边角位置, 默认与边框线同中心点
    public var cornerLocation: CornerLocation {
        get {
            return QRCodeScanTool.shared.cornerLocation
        }
        set {
            QRCodeScanTool.shared.cornerLocation = newValue
        }
    }
    /// 边框宽度
    public var borderLineWidth: CGFloat {
        get {
            return QRCodeScanTool.shared.borderLineWidth
        }
        set {
            QRCodeScanTool.shared.borderLineWidth = newValue
        }
    }
    /// 边角宽度
    public var cornerWidth: CGFloat {
        get {
            return QRCodeScanTool.shared.cornerWidth
        }
        set {
            QRCodeScanTool.shared.cornerWidth = newValue
        }
    }
    
    /// 扫描框下常规提示信息
    public var tips: String {
        get {
            return QRCodeScanTool.shared.tips
        }
        set {
            QRCodeScanTool.shared.tips = newValue
        }
    }
    
    /// 手电筒下提示信息
    public var flashTips: String {
        get {
            return QRCodeScanTool.shared.flashTips
        }
        set {
            QRCodeScanTool.shared.flashTips = newValue
        }
    }
    
    /// 扫描样式，默认单线
    public var scanAnimationStyle: ScanAnimationStyle {
        get {
            return QRCodeScanTool.shared.scanAnimationStyle
        }
        set {
            QRCodeScanTool.shared.scanAnimationStyle = newValue
        }
    }
    
    /// 扫描框主题颜色
    public var scanTintColor: UIColor {
        get {
            return QRCodeScanTool.shared.scannerColor
        }
        set {
            QRCodeScanTool.shared.scannerColor = newValue
        }
    }
    
    /// 边框线颜色
    public var borderLineColor: UIColor {
        get {
            return QRCodeScanTool.shared.borderColor
        }
        set {
            QRCodeScanTool.shared.borderColor = newValue
        }
    }
    
    /// 扫描框外的黑色背景透明度
    public var backgroundAlpha: CGFloat {
        get {
            return QRCodeScanTool.shared.backgroundAlpha
        }
        set {
            QRCodeScanTool.shared.backgroundAlpha = newValue
        }
    }
    
    /// 扫描框尺寸和屏幕尺寸比例
    public var scanBorderWidthRadio: CGFloat {
        get {
            return QRCodeScanTool.shared.scanBorderWidthRadio
        }
        set {
            QRCodeScanTool.shared.scanBorderWidthRadio = newValue
        }
    }
    
    /// 扫描作用域范围是否为全屏的范围，否则为扫描框的范围
    public var isRectOfInterestFillBounds: Bool {
        get {
            return QRCodeScanTool.shared.isRectOfInterestFillBounds
        }
        set {
            QRCodeScanTool.shared.isRectOfInterestFillBounds = newValue
        }
    }
    /// 相机可视范围是否全屏
    public var isCamaraShowFillBounds: Bool {
        get {
            return QRCodeScanTool.shared.isCamaraShowFillBounds
        }
        set {
            QRCodeScanTool.shared.isCamaraShowFillBounds = newValue
        }
    }
    /// 是否播放音效
    public var isNeedPlaySound: Bool {
        get {
            return QRCodeScanTool.shared.isNeedPlaySound
        }
        set {
            QRCodeScanTool.shared.isNeedPlaySound = newValue
        }
    }
    
    private init(){}
    
    /// 开启扫描
    public func startScanning() {
        QRCodeScanTool.shared.startScanning()
    }
    
    /// 停止扫描
    public func stopScanning() {
        QRCodeScanTool.shared.stopScanning()
    }
    
    /// 创建扫描控制器
    public func instantiateQRCodeViewController() -> UIViewController {
        let qrCodeController = QRCodeScanViewController()
        return qrCodeController
    }
    
    /// 显示失败蒙版
    public func showFailureMask(text: String? = "QRCode.Fail.Tip".s_localize(fallback: "当前二维码识别失败，请重新扫描")) {
        QRCodeScanTool.shared.showFailureMask(text: text)
    }
}
