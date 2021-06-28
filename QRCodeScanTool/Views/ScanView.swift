//
//  ScanView.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/22.
//  Copyright © 2019 sai. All rights reserved.
//

import UIKit

protocol ScanViewDelegate: class {
    func scanViewFlashButtonClick()
    func scanViewTapAction(with point: CGPoint)
    func scanViewPinchAction(with pinch: UIPinchGestureRecognizer)
    func scanViewTapFailureMaskView(with tap: UIGestureRecognizer)
}

class ScanView: UIView {
    
    // MARK: Public Properties
    weak var delegate: ScanViewDelegate?
    ///扫描动画图片
    lazy var scanAnimationImageView: UIImageView = {
        if scanAnimationStyle == .default {
            let scanAnimationImage = imageNamed("scanLine").changeColor(cornerColor)
            return UIImageView(image: scanAnimationImage)
        }else{
            let scanAnimationImage = imageNamed("scanNet").changeColor(cornerColor)
            return UIImageView(image: scanAnimationImage)
        }
    }()
    /// 扫描样式
    var scanAnimationStyle: ScanAnimationStyle = .default {
        didSet {
            if scanAnimationStyle == .default {
                let scanAnimationImage = imageNamed("scanLine").changeColor(cornerColor)
                scanAnimationImageView = UIImageView(image: scanAnimationImage)
            }else{
                let scanAnimationImage = imageNamed("scanNet").changeColor(cornerColor)
                scanAnimationImageView = UIImageView(image: scanAnimationImage)
            }
        }
    }
    
    /// 边角位置, 默认与边框线同中心点
    lazy var cornerLocation: CornerLocation = .default
    
    /// 边框线颜色，默认白色
    lazy var borderColor: UIColor = .white
    
    /// 边框线宽度， 默认0.2
    lazy var borderLineWidth: CGFloat = 0.2
    
    /// 边角颜色， 默认红色
    var cornerColor: UIColor = .green {
        didSet {
            if scanAnimationStyle == .default {
                let scanAnimationImage = imageNamed("scanLine").changeColor(cornerColor)
                scanAnimationImageView = UIImageView(image: scanAnimationImage)
            }else{
                let scanAnimationImage = imageNamed("scanNet").changeColor(cornerColor)
                scanAnimationImageView = UIImageView(image: scanAnimationImage)
            }
        }
    }
    
    /// 边角宽度
    lazy var cornerWidth: CGFloat = 2.0
    
    /// 扫描区周边颜色的alpha值， 默认0.6
    lazy var backgroundAlpha: CGFloat = 0.6
    
    /// 扫描区的宽度跟屏幕宽度的比
    var scanBorderWidthRadio: CGFloat = 0.6 {
        didSet {
            scanBorderWidth = screenWidth * scanBorderWidthRadio
            scanBorderHeight = scanBorderWidth
            scanBorderX = 0.5 * (1 - scanBorderWidthRadio) * screenWidth
            scanBorderY = 0.5 * (screenHeight - scanBorderWidth)
        }
    }
    
    // MARK: Private Properties
    // 扫描框宽
    private var scanBorderWidth: CGFloat
    // 扫描框高度
    private var scanBorderHeight: CGFloat
    
    /// 扫描区的x值
    private var scanBorderX: CGFloat
    
    /// 扫描区的y值
    private var scanBorderY: CGFloat
    
    private var failureView: FailureMaskView?
    
    /// pitch手势
    private lazy var pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchCapture))
    
    /// 中间扫描的镂空区域
    lazy var contentView: UIView = {
        let contentView = UIView(frame: CGRect(x: scanBorderX, y: scanBorderY, width: scanBorderWidth, height:scanBorderHeight))
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        if !subviews.contains(contentView) {
            addSubview(contentView)
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(tapGesture:)))
            contentView.addGestureRecognizer(tap)
        }
        return contentView
    }()
    /// 正常提示消息label
    private lazy var tipsLabel: UILabel = {
        let tipsLbl = UILabel.init()
        tipsLbl.text = tips
        tipsLbl.textColor = .white
        tipsLbl.textAlignment = .center
        tipsLbl.font = UIFont.systemFont(ofSize: 13)
        tipsLbl.translatesAutoresizingMaskIntoConstraints = false
        if !subviews.contains(tipsLbl) {
            addSubview(tipsLbl)
        }
        return tipsLbl
    }()
    /// 提示文字
    var tips: String = "QRCode.MainCodePage.Tip".s_localize(fallback: "将二维码放入框内，即可自动扫描") {
        didSet {
            tipsLabel.text = tips
        }
    }
    /// 手电筒提示信息
    var falshTips: String = "QRCode.Flash.Tip".s_localize(fallback: "轻触点亮") {
        didSet {
            flashTipLabel.text = falshTips
        }
    }
    
    /// 手电筒下提示label
    private lazy var flashTipLabel: UILabel = {
        let label = UILabel()
        label.text = falshTips
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        if !subviews.contains(label) {
            addSubview(label)
            label.isHidden = true
        }
        return label
    }()

    /// 手电筒按钮
    private lazy var flashButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(imageNamed("flashOff"), for: .normal)
        button.setImage(imageNamed("flashOn"), for: .selected)
        button.addTarget(self, action: #selector(flashButtonClick), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        if !subviews.contains(button) {
            addSubview(button)
            button.isHidden = true
        }
        return button
    }()
    
    var torchMode: TorchMode {
        didSet {
            switch torchMode {
            case .on:
                flashButton.isSelected = true
            case .off:
                flashButton.isSelected = false
            }
        }
    }
    
    var isShowFlash: Bool = false {
        didSet {
            flashButton.isHidden = !isShowFlash
            flashTipLabel.isHidden = !isShowFlash
        }
    }
    
    override init(frame: CGRect) {
        self.scanBorderWidth = screenWidth * scanBorderWidthRadio
        self.scanBorderHeight = scanBorderWidth
        self.scanBorderX = 0.5 * (1 - scanBorderWidthRadio) * screenWidth
        self.scanBorderY = 0.5 * (screenHeight - scanBorderWidth - topAreaHeight)
        self.torchMode = .off
        self.isShowFlash = false
        super.init(frame: frame)
        
        backgroundColor = .clear
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        drawScan(rect)
        
        var rect:CGRect?
        
        if scanAnimationStyle == .default {
            rect = CGRect(x: 0 , y: -(12 + 20), width: scanBorderWidth , height: 12)
            
        }else{
            rect = CGRect(x: 0, y: -(scanBorderHeight + 20), width: scanBorderWidth, height:scanBorderHeight)
        }

        ScanAnimation.shared.startWith(rect!, contentView, imageView: scanAnimationImageView)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupTips()
        setupFlashTipsLabel()
        setupFlashButton()
    }
}

extension ScanView {
    func startAnimation() {
        
        ScanAnimation.shared.startAnimation()
        
    }
    
    func stopAnimation() {
        ScanAnimation.shared.stopAnimation()
    }
    
    func addPinchGesture() {
        self.addGestureRecognizer(pinchGesture)
    }
    
    func removePinchGesture() {
        self.removeGestureRecognizer(pinchGesture)
    }
    
    func showFailureView(text: String?) {
        if failureView == nil {
            let failureView = FailureMaskView(frame: self.bounds)
            addSubview(failureView)
            failureView.failureMessage = text
            let tap = UITapGestureRecognizer(target: self, action: #selector(onTappedFailureMask(tap:)))
            failureView.addGestureRecognizer(tap)
            self.failureView = failureView
        }
    }
    
    func removeFailureView() {
        failureView?.removeFromSuperview()
        failureView = nil
    }
    
    @objc func onTappedFailureMask(tap: UIGestureRecognizer) {
        removeFailureView()
        delegate?.scanViewTapFailureMaskView(with: tap)
    }
}

private extension ScanView {
    func setupTips() {
        if #available(iOS 9.0, *) {
            NSLayoutConstraint.activate([tipsLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),tipsLabel.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 20),tipsLabel.widthAnchor.constraint(equalToConstant: frame.size.width),tipsLabel.heightAnchor.constraint(equalToConstant: 14)])
        } else {
            
            let height = NSLayoutConstraint(item: tipsLabel, attribute: NSLayoutAttribute.height, relatedBy:NSLayoutRelation.equal, toItem:nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier:0.0, constant:14)
            
            let width = NSLayoutConstraint(item: tipsLabel, attribute: NSLayoutAttribute.width, relatedBy:NSLayoutRelation.equal, toItem:nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier:0.0, constant:frame.size.width)
            
            let topConstraint = NSLayoutConstraint(item: tipsLabel, attribute: NSLayoutAttribute.top, relatedBy:NSLayoutRelation.equal, toItem:contentView, attribute: NSLayoutAttribute.bottom, multiplier:0.0, constant:20)
            
            let cententXConstraint = NSLayoutConstraint(item: tipsLabel, attribute: NSLayoutAttribute.centerX, relatedBy:NSLayoutRelation.equal, toItem:contentView, attribute: NSLayoutAttribute.centerX, multiplier:0, constant:0)
            
            contentView.addConstraints([topConstraint, cententXConstraint])
            tipsLabel.addConstraints([height,width])
        }
    }
    
    func setupFlashTipsLabel() {

        if #available(iOS 9.0, *) {
            
            NSLayoutConstraint.activate([flashTipLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),flashTipLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),flashTipLabel.widthAnchor.constraint(equalTo: contentView.widthAnchor),flashTipLabel.heightAnchor.constraint(equalToConstant: 14)])
        } else {
            let height = NSLayoutConstraint(item: flashTipLabel, attribute: NSLayoutAttribute.height, relatedBy:NSLayoutRelation.equal, toItem:nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier:0, constant:14)
            
            let width = NSLayoutConstraint(item: flashTipLabel, attribute: NSLayoutAttribute.width, relatedBy:NSLayoutRelation.equal, toItem:contentView, attribute: NSLayoutAttribute.width, multiplier:0, constant:0)
            
            let bottomConstraint = NSLayoutConstraint(item: flashTipLabel, attribute: NSLayoutAttribute.bottom, relatedBy:NSLayoutRelation.equal, toItem:contentView, attribute: NSLayoutAttribute.bottom, multiplier:0, constant:-20)
            
            let cententXConstraint = NSLayoutConstraint(item: flashTipLabel, attribute: NSLayoutAttribute.centerX, relatedBy:NSLayoutRelation.equal, toItem:contentView, attribute: NSLayoutAttribute.centerX, multiplier:0, constant:0)
            
            contentView.addConstraints([width, bottomConstraint, cententXConstraint])
            flashTipLabel.addConstraint(height)
        }
    }
    
    func setupFlashButton() {
        if #available(iOS 9.0, *) {
            NSLayoutConstraint.activate([flashButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                                         flashButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40),
                                         flashButton.widthAnchor.constraint(equalToConstant: 32),
                                         flashButton.heightAnchor.constraint(equalToConstant: 32)])
        } else {
            let height = NSLayoutConstraint(item: flashButton, attribute: NSLayoutAttribute.height, relatedBy:NSLayoutRelation.equal, toItem:nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier:0, constant:32)
            
            let width = NSLayoutConstraint(item: flashButton, attribute: NSLayoutAttribute.width, relatedBy:NSLayoutRelation.equal, toItem:nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier:0, constant:32)
            
            let bottomConstraint = NSLayoutConstraint(item: flashButton, attribute: NSLayoutAttribute.bottom, relatedBy:NSLayoutRelation.equal, toItem:contentView, attribute: NSLayoutAttribute.bottom, multiplier:0, constant:-40)
            
            let cententXConstraint = NSLayoutConstraint(item: flashButton, attribute: NSLayoutAttribute.centerX, relatedBy:NSLayoutRelation.equal, toItem:contentView, attribute: NSLayoutAttribute.centerX, multiplier:0, constant:0)
            
            contentView.addConstraints([bottomConstraint, cententXConstraint])
            flashButton.addConstraints([height, width])
        }
        
    }
}

private extension ScanView {
    /// 绘制扫码效果
    func drawScan(_ rect: CGRect) {
        
        /// 空白区域设置
        UIColor.black.withAlphaComponent(backgroundAlpha).setFill()
        
        UIRectFill(rect)
        
        let context = UIGraphicsGetCurrentContext()
        
        // 获取上下文，并设置清空模式
        context?.setBlendMode(.clear)
        
        // 设置空白区
        let bezierPath = UIBezierPath(rect: CGRect(x: scanBorderX + 0.5 * borderLineWidth, y: scanBorderY + 0.5 * borderLineWidth, width: scanBorderWidth - borderLineWidth, height: scanBorderHeight - borderLineWidth))
        bezierPath.fill()
        
        // 设为正常模式
        context?.setBlendMode(.normal)
        
        /// 边框设置
        let borderPath = UIBezierPath(rect: CGRect(x: scanBorderX, y: scanBorderY, width: scanBorderWidth, height: scanBorderHeight))
        
        borderPath.lineCapStyle = .butt
        
        borderPath.lineWidth = borderLineWidth
        
        borderColor.set()
        
        borderPath.stroke()
        
        //角标长度
        let cornerLenght:CGFloat = 20
        
        let insideExcess = 0.5 * (cornerWidth - borderLineWidth)
        
        let outsideExcess = 0.5 * (cornerWidth + borderLineWidth)
        
        /// 左上角角标
        let leftTopPath = UIBezierPath()
        
        leftTopPath.lineWidth = cornerWidth
        
        cornerColor.set()
        
        if cornerLocation == .inside {
            
            leftTopPath.move(to: CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + cornerLenght + insideExcess))
            
            leftTopPath.addLine(to: CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + insideExcess))
            
            leftTopPath.addLine(to: CGPoint(x: scanBorderX + cornerLenght + insideExcess, y: scanBorderY + insideExcess))
            
        }else if cornerLocation == .outside{
            
            leftTopPath.move(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY + cornerLenght - outsideExcess))
            
            leftTopPath.addLine(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY - outsideExcess))
            
            leftTopPath.addLine(to: CGPoint(x: scanBorderX + cornerLenght - outsideExcess, y: scanBorderY - outsideExcess))
            
        }else{
            
            leftTopPath.move(to: CGPoint(x: scanBorderX, y: scanBorderY + cornerLenght))
            
            leftTopPath.addLine(to: CGPoint(x: scanBorderX, y: scanBorderY))
            
            leftTopPath.addLine(to: CGPoint(x: scanBorderX + cornerLenght, y: scanBorderY))
            
        }
        
        leftTopPath.stroke()
        
        /// 左下角角标
        let leftBottomPath = UIBezierPath()
        
        leftBottomPath.lineWidth = cornerWidth
        
        cornerColor.set()
        
        if cornerLocation == .inside {
            
            leftBottomPath.move(to: CGPoint(x: scanBorderX + cornerLenght + insideExcess, y: scanBorderY + scanBorderHeight - insideExcess))
            
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX + insideExcess, y: scanBorderY + scanBorderHeight - insideExcess))
            
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX +  insideExcess, y: scanBorderY + scanBorderHeight - cornerLenght - insideExcess))
            
        }else if cornerLocation == .outside{
            
            leftBottomPath.move(to: CGPoint(x: scanBorderX + cornerLenght - outsideExcess, y: scanBorderY + scanBorderHeight + outsideExcess))
            
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY + scanBorderHeight + outsideExcess))
            
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX - outsideExcess, y: scanBorderY + scanBorderHeight - cornerLenght + outsideExcess))
            
        }else{
            
            leftBottomPath.move(to: CGPoint(x: scanBorderX + cornerLenght, y: scanBorderY + scanBorderHeight))
            
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX, y: scanBorderY + scanBorderHeight))
            
            leftBottomPath.addLine(to: CGPoint(x: scanBorderX, y: scanBorderY + scanBorderHeight - cornerLenght))
            
        }
        
        leftBottomPath.stroke()
        
        /// 右上角小图标
        let rightTopPath = UIBezierPath()
        
        rightTopPath.lineWidth = cornerWidth
        
        cornerColor.set()
        
        if cornerLocation == .inside {
            
            rightTopPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght - insideExcess, y: scanBorderY + insideExcess))
            
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - insideExcess, y: scanBorderY + insideExcess))
            
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - insideExcess, y: scanBorderY + cornerLenght + insideExcess))
            
        } else if cornerLocation == .outside {
            
            rightTopPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght + outsideExcess, y: scanBorderY - outsideExcess))
            
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth + outsideExcess, y: scanBorderY - outsideExcess))
            
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth + outsideExcess, y: scanBorderY + cornerLenght - outsideExcess))
            
        } else {
            
            rightTopPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght, y: scanBorderY))
            
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth, y: scanBorderY))
            
            rightTopPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth, y: scanBorderY + cornerLenght))
            
        }
        
        rightTopPath.stroke()
        
        /// 右下角小图标
        let rightBottomPath = UIBezierPath()
        
        rightBottomPath.lineWidth = cornerWidth
        
        cornerColor.set()
        
        if cornerLocation == .inside {
            
            rightBottomPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth - insideExcess, y: scanBorderY + scanBorderHeight - cornerLenght - insideExcess))
            
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - insideExcess, y: scanBorderY + scanBorderHeight - insideExcess))
            
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght - insideExcess, y: scanBorderY + scanBorderHeight - insideExcess))
            
        } else if cornerLocation == .outside {
            
            rightBottomPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth + outsideExcess, y: scanBorderY + scanBorderHeight - cornerLenght + outsideExcess))
            
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth + outsideExcess, y: scanBorderY + scanBorderHeight + outsideExcess))
            
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght + outsideExcess, y: scanBorderY + scanBorderHeight + outsideExcess))
            
        } else {
            
            rightBottomPath.move(to: CGPoint(x: scanBorderX + scanBorderWidth, y: scanBorderY + scanBorderHeight - cornerLenght))
            
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth, y: scanBorderY + scanBorderHeight))
            
            rightBottomPath.addLine(to: CGPoint(x: scanBorderX + scanBorderWidth - cornerLenght, y: scanBorderY + scanBorderHeight))
            
        }
        
        rightBottomPath.stroke()
        
    }
}

/// 监听
private extension ScanView {
    @objc func flashButtonClick() {
        torchMode = torchMode.next
        delegate?.scanViewFlashButtonClick()
    }
    
    @objc func tapAction(tapGesture: UIGestureRecognizer) {
        let point = tapGesture.location(in: self)
        delegate?.scanViewTapAction(with: point)
    }
    
    @objc func pinchCapture(recogniser: UIGestureRecognizer) {
        guard let pinch = recogniser as? UIPinchGestureRecognizer else {
            return
        }
        delegate?.scanViewPinchAction(with: pinch)
    }
}
