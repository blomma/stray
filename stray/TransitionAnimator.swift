import Foundation

public protocol TransitionAnimatable {
	static func performTransition(forView view: UIView, completion: (() -> Void)?)
}

public struct FadeAnimator: TransitionAnimatable {
	public static func performTransition(forView view: UIView, completion: (() -> Void)?) {
		CATransaction.begin()

		CATransaction.setCompletionBlock(completion)
		let fadeAnimation = CABasicAnimation(keyPath: "opacity")
		fadeAnimation.duration = 0.35
		fadeAnimation.fromValue = 0
		fadeAnimation.toValue = 1
		fadeAnimation.fillMode = kCAFillModeForwards
		fadeAnimation.isRemovedOnCompletion = true
		view.layer.add(fadeAnimation, forKey: "fade")

		CATransaction.commit()
	}
}

public struct CircleMaskAnimator: TransitionAnimatable {
	public static func performTransition(forView view: UIView, completion: (() -> Void)?) {
		CATransaction.begin()
		CATransaction.setCompletionBlock(completion)

		let screenSize = UIScreen.main.bounds.size
		let dim = max(screenSize.width, screenSize.height)
		let circleDiameter : CGFloat = 50.0
		let circleFrame = CGRect(x: (screenSize.width - circleDiameter) / 2, y: (screenSize.height - circleDiameter) / 2, width: circleDiameter, height: circleDiameter)
		let circleCenter = CGPoint(x: circleFrame.origin.x + circleDiameter / 2, y: circleFrame.origin.y + circleDiameter / 2)

		let circleMaskPathInitial = UIBezierPath(ovalIn: circleFrame)
		let extremePoint = CGPoint(x: circleCenter.x - dim, y: circleCenter.y - dim)
		let radius = sqrt((extremePoint.x * extremePoint.x) + (extremePoint.y * extremePoint.y))
		let circleMaskPathFinal = UIBezierPath(ovalIn: circleFrame.insetBy(dx: -radius, dy: -radius))

		let maskLayer = CAShapeLayer()
		maskLayer.path = circleMaskPathFinal.cgPath
		view.layer.mask = maskLayer

		let maskLayerAnimation = CABasicAnimation(keyPath: "path")
		maskLayerAnimation.fromValue = circleMaskPathInitial.cgPath
		maskLayerAnimation.toValue = circleMaskPathFinal.cgPath
		maskLayerAnimation.duration = 0.6

		view.layer.mask?.add(maskLayerAnimation, forKey: "circleMask")
		CATransaction.commit()
	}
}
