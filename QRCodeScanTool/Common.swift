//
//  Common.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/22.
//  Copyright © 2019 sai. All rights reserved.
//

import Foundation

let bundle = Bundle(for: QRCodeScanTool.self)

let screenWidth = UIScreen.main.bounds.width

let screenHeight = UIScreen.main.bounds.height

let statusHeight = UIApplication.shared.statusBarFrame.height

let topAreaHeight: CGFloat = statusHeight == 44 ? 88.0 : 64.0


public func imageNamed(_ name:String)-> UIImage{
    
    guard let image = UIImage(named: name, in: bundle, compatibleWith: nil) else{
        return UIImage()
    }
    
    return image
    
}

public extension String {
  func s_localize(fallback: String) -> String {
    let string = NSLocalizedString(self, comment: "")
    return string == self ? fallback : string
  }
}
