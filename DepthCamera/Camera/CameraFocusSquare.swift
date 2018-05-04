//
//  CameraFocusSquare.swift
//  DepthCamera
//
//  Created by Fabio on 03.01.18.
//  Copyright © 2018 Fabio Morbec. All rights reserved.
//
// NOTE: Adapted from this thread - https://stackoverflow.com/a/36327183

import UIKit

class CameraFocusSquare: UIView {
    
    // MARK: Properties
    private let kSelectionAnimation = "selectionAnimation"
    private let squareLenght: CGFloat = 80.0
    fileprivate var selectionBlink: CABasicAnimation!
    
    // MARK: - Inits
    convenience init(touchPoint: CGPoint) {
        self.init()
        self.updatePoint(touchPoint)
        self.backgroundColor = UIColor.clear
        self.layer.borderWidth = 2.0
        self.layer.borderColor = UIColor.white.cgColor
        
        // creating the blink animation
        self.selectionBlink = CABasicAnimation(keyPath: "borderColor")
        self.selectionBlink.toValue = UIColor.black.cgColor
        self.selectionBlink.repeatCount = 3
        self.selectionBlink.duration = 0.4
        self.selectionBlink.delegate = self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Functions
    func updatePoint(_ touchPoint: CGPoint) {
        let frame: CGRect = CGRect(x: touchPoint.x - squareLenght/2,
                                   y: touchPoint.y - squareLenght/2,
                                   width: squareLenght,
                                   height: squareLenght)
        self.frame = frame
    }
    
    func animateFocusingAction() {
        self.alpha = 1.0
        self.isHidden = false
        self.layer.add(selectionBlink!, forKey: kSelectionAnimation)
    }
}

// MARK: - CAAnimationDelegate
extension CameraFocusSquare: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        self.alpha = 0.5
    }
}
