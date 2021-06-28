//
//  QRCodeScanError.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/25.
//  Copyright © 2019 sai. All rights reserved.
//

import Foundation

public enum QRCodeScanError {
    /// 模拟器错误
    case simulatorError
    /// 摄像头授权错误
    case camaraAuthorityError
    /// 未知
    case otherError
}
