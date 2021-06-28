//
//  FlashMode.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/24.
//  Copyright © 2019 sai. All rights reserved.
//

import Foundation
import AVFoundation

enum TorchMode {
    case on
    case off
}

extension TorchMode {
    var next: TorchMode {
        switch self {
        case .on:
            return .off
        case .off:
            return .on
            
        }
    }
    
    var image: UIImage {
        switch self {
        case .on:
            return imageNamed("flashOn")
        case .off:
            return imageNamed("flashOff")
            
        }
    }
    
    var captureTorchMode: AVCaptureDevice.TorchMode {
        switch self {
        case .on:
            return .on
        case .off:
            return .off
            
        }
    }
}
