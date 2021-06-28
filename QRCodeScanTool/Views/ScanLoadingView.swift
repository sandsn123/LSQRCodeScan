//
//  ScanLoadingView.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/29.
//  Copyright © 2019 sai. All rights reserved.
//

import UIKit

class ScanLoadingView: UIView {

    /// 提示消息
    lazy var promptLabel: UILabel = {
        let lab = UILabel()
        lab.text = "QRCode.Detecor.Tip".s_localize(fallback: "正在处理..")
        lab.textColor = .white
        lab.font = UIFont.systemFont(ofSize: 13)
        lab.textAlignment = .center
        return lab
    }()
    
    /// 菊花
    lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(promptLabel)
        addSubview(indicatorView)
        
        indicatorView.centerX = self.centerX
        indicatorView.y = self.y
        
        promptLabel.width = 90
        promptLabel.height = 28
        promptLabel.centerX = self.centerX
        promptLabel.y = indicatorView.y + indicatorView.height + 10
        
        indicatorView.startAnimating()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
