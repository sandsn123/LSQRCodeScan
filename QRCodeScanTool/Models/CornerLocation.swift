//
//  CornerLocation.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/22.
//  Copyright © 2019 sai. All rights reserved.
//

import Foundation

public enum CornerLocation {
    /// 默认与边框线同中心点
    case `default`
    /// 在边框线内部
    case inside
    /// 在边框线外部
    case outside
}
