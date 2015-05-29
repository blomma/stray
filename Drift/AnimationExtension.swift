//
//  AnimationExtension.swift
//  Drift
//
//  Created by Mikael Hultgren on 29/05/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation

extension UIButton {
    func animate() {
        var pathFrame: CGRect = CGRectMake(-CGRectGetMidY(bounds), -CGRectGetMidY(bounds), bounds.size.height, bounds.size.height)
        var path: UIBezierPath = UIBezierPath(roundedRect: pathFrame, cornerRadius:pathFrame.size.height / 2)
        
        var shapePosition: CGPoint = convertPoint(center, fromView:superview)
        
        var circleShape: CAShapeLayer = CAShapeLayer.new()
        circleShape.path        = path.CGPath;
        circleShape.position    = shapePosition;
        circleShape.fillColor   = UIColor.clearColor().CGColor
        circleShape.opacity     = 0;
        circleShape.strokeColor = titleLabel?.textColor.CGColor;
        circleShape.lineWidth   = 2;
        
        layer.addSublayer(circleShape)
        
        var scaleAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
        scaleAnimation.toValue   = NSValue(CATransform3D:CATransform3DMakeScale(3, 3, 1))
        
        var alphaAnimation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 1;
        alphaAnimation.toValue   = 0;
        
        var animation: CAAnimationGroup = CAAnimationGroup.new()
        animation.delegate = self
        animation.animations     = [scaleAnimation, alphaAnimation]
        animation.duration       = 0.5
        
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        circleShape.addAnimation(animation, forKey: nil)
    }
}