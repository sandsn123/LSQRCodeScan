//
//  ScanAnimation.swift
//  QRCodeScanTool
//
//  Created by sai on 2019/4/22.
//  Copyright © 2019 sai. All rights reserved.
//

import Foundation

class ScanAnimation:NSObject{
    
    static let shared:ScanAnimation = {
        
        let instance = ScanAnimation()
        
        return instance
    }()
    
    lazy var animationImageView = UIImageView()
    
    var displayLink:CADisplayLink?
    
    var tempFrame:CGRect?
    
    var contentHeight:CGFloat?
    
    func startWith(_ rect:CGRect, _ parentView:UIView, imageView:UIImageView) {
        
        tempFrame = rect
        
        imageView.frame = tempFrame ?? CGRect.zero
        
        animationImageView = imageView
        
        contentHeight = parentView.bounds.height
        
        if !parentView.subviews.contains(imageView) {
            parentView.addSubview(imageView)
        }
    }
    
    
    @objc func animation() {
        
        if animationImageView.frame.maxY > contentHeight! + 20 {
            animationImageView.frame = tempFrame ?? CGRect.zero
        }
        
        animationImageView.transform = CGAffineTransform(translationX: 0, y: 2).concatenating(animationImageView.transform)
        
    }
    
    
    func setupDisplayLink() {
        
        displayLink = CADisplayLink(target: self, selector: #selector(animation))
        
        displayLink?.add(to: .main, forMode: .commonModes)
        
        displayLink?.isPaused = true
        
    }
    
    
    func startAnimation() {
        if displayLink == nil {
            setupDisplayLink()
        }
        displayLink?.isPaused = false
    }
    
    
    func stopAnimation() {
        displayLink?.remove(from: .main, forMode: .commonModes)
        displayLink?.invalidate()
        displayLink = nil
    }
    
}
