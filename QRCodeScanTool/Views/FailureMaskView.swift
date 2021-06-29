//
//  FailureMaskView.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/30.
//  Copyright © 2019 sai. All rights reserved.
//

import UIKit

class FailureMaskView: UIView {
    
    var failureMessage: String? = "QRCode.Fail.Tip".s_localize(fallback: "当前二维码识别失败，请重新扫描") {
        didSet {
            messageLabel.text = failureMessage
        }
    }

    private lazy var tapLabel: UILabel = {
        let lab = UILabel()
        lab.text = "QRCode.Tap.ReScan.Tip".s_localize(fallback: "轻触屏幕继续扫描")
        lab.textColor = UIColor.gray
        lab.font = UIFont.systemFont(ofSize: 12)
        lab.numberOfLines = 0
        lab.textAlignment = .center
        return lab
    }()
    
    private lazy var messageLabel: UILabel = {
        let lab = UILabel()
        lab.textColor = UIColor.white
        lab.font = UIFont.systemFont(ofSize: 13)
        lab.textAlignment = .center
        return lab
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tapLabel)
        addSubview(messageLabel)
        
        tapLabel.width = frame.size.width - 20
        tapLabel.height = 24
        tapLabel.centerX = self.centerX
        tapLabel.y = self.centerY - tapLabel.height
        
        messageLabel.width = screenWidth
        messageLabel.height = 24
        messageLabel.centerX = self.centerX
        messageLabel.y = tapLabel.y - messageLabel.height
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
