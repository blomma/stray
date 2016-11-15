import Foundation
import UIKit

extension UIButton {
    func animate() {
        let pathFrame: CGRect = CGRect(x: -bounds.midY, y: -bounds.midY, width: bounds.size.height, height: bounds.size.height)
        let path: UIBezierPath = UIBezierPath(roundedRect: pathFrame, cornerRadius:pathFrame.size.height / 2)

        let shapePosition: CGPoint = convert(center, from:superview)

        let circleShape: CAShapeLayer = CAShapeLayer()
        circleShape.path        = path.cgPath
        circleShape.position    = shapePosition
        circleShape.fillColor   = UIColor.clear.cgColor
        circleShape.opacity     = 0
        circleShape.strokeColor = titleLabel?.textColor.cgColor
        circleShape.lineWidth   = 2

        layer.addSublayer(circleShape)

        let scaleAnimation: CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
        scaleAnimation.toValue   = NSValue(caTransform3D:CATransform3DMakeScale(3, 3, 1))

        let alphaAnimation: CABasicAnimation = CABasicAnimation(keyPath: "opacity")
        alphaAnimation.fromValue = 1
        alphaAnimation.toValue   = 0

        let animation: CAAnimationGroup = CAAnimationGroup()
        animation.animations     = [scaleAnimation, alphaAnimation]
        animation.duration       = 0.5

        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        circleShape.add(animation, forKey: nil)
    }
}
