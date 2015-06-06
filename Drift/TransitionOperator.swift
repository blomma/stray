//
//  TransitionOperator.swift
//  Drift
//
//  Created by Mikael Hultgren on 04/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import UIKit

protocol TransitionOperatorDelegate : class {
	func transitionControllerInteractionDidStart(havePresented: Bool)
}

class TransitionOperator: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
	var presented: Bool = false

	var presenting: Bool = false
	var interactionInProgress: Bool = false

	weak var delegate:TransitionOperatorDelegate?

	lazy var gestureRecogniser: UIPanGestureRecognizer = {
		var recognizer = UIPanGestureRecognizer(target: self, action: "handleGesture:")
		return recognizer
		}()

	func handleGesture(recognizer: UIPanGestureRecognizer) {
		if let view = recognizer.view {
			let translation = recognizer.translationInView(view)
			let velocity = recognizer.velocityInView(view)
			let percentage = abs(translation.x / CGRectGetWidth(view.bounds))

			switch recognizer.state {
			case .Began:
				if velocity.x > 0 && !presented {
					interactionInProgress = true
					delegate?.transitionControllerInteractionDidStart(presented)
				} else if velocity.x < 0 && presented {
					interactionInProgress = true
					delegate?.transitionControllerInteractionDidStart(presented)
				}
			case .Changed:
				updateInteractiveTransition(percentage)
			case .Ended:
				if percentage > 0.4 {
					finishInteractiveTransition()
				} else {
					cancelInteractiveTransition()
				}

				interactionInProgress = false
			case .Cancelled:
				cancelInteractiveTransition()

				interactionInProgress = false
			default:
				break
			}
		}
	}
}

// MARK: - UINavigationControllerDelegate
typealias TransitionOperatorUINavigationControllerDelegate = TransitionOperator
extension TransitionOperatorUINavigationControllerDelegate {
	func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		switch operation {
		case .Push:
			presenting = true
		default:
			presenting = false
		}

		return self
	}

	func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return interactionInProgress ? self : .None
	}
}

// MARK: - UIViewControllerTransitioningDelegate
typealias TransitionOperatorUIViewControllerTransitioningDelegate = TransitionOperator
extension TransitionOperatorUIViewControllerTransitioningDelegate {
	func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		self.presenting = true

		return self
	}

	func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		presenting = false

		return self
	}

	func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return interactionInProgress ? self : .None
	}

	func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) ->
		UIViewControllerInteractiveTransitioning? {
		return interactionInProgress ? self : .None
	}
}

// MARK: - UIViewControllerAnimatedTransitioning
typealias TransitionOperatorUIViewControllerAnimatedTransitioning = TransitionOperator
extension TransitionOperatorUIViewControllerAnimatedTransitioning {
	func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
		return 0.5
	}

	func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
		DLog()
		let container = transitionContext.containerView()
		let duration = transitionDuration(transitionContext)

		var toView: UIView?
		if let view = transitionContext.viewForKey(UITransitionContextToViewKey) {
			toView = view
		}

		var fromView: UIView?
		if let view = transitionContext.viewForKey(UITransitionContextFromViewKey) {
			fromView = view
		}

		DLog("toView \(toView)")
		DLog("fromView \(fromView)")
		DLog("container \(container)")
		DLog("container subviews \(container.subviews)")
		DLog("keyWindow subviews \(UIApplication.sharedApplication().keyWindow?.subviews)")

		if presenting,
			let toView = toView,
			let fromView = fromView {
				if interactionInProgress {
					DLog("interaction")

					container.addSubview(toView)

					toView.frame.origin.x = -toView.frame.width

					var toEndFrame = toView.frame
					toEndFrame.origin.x = -toView.frame.size.width+100

					var fromEndFrame = fromView.frame
					fromEndFrame.origin.x = 100

					UIView.animateWithDuration(duration, delay: 0, options: nil, animations: {
						fromView.frame = fromEndFrame
						toView.frame = toEndFrame
						}, completion: { [unowned self] finished in
							self.presented = !transitionContext.transitionWasCancelled()
							transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
							UIApplication.sharedApplication().keyWindow?.addSubview(fromView)
						})
				} else if let oldFromView = UIApplication.sharedApplication().keyWindow?.subviews.last as? UIView {
					container.addSubview(toView)
					container.addSubview(oldFromView)

					DLog("animation")
					toView.frame.origin.x = toView.frame.width
					var toEndFrame = toView.frame
					toEndFrame.origin.x = 0

					var oldFromEndFrame = oldFromView.frame
					oldFromEndFrame.origin.x = -oldFromView.frame.width

					var fromEndFrame = fromView.frame
					fromEndFrame.origin.x = -(fromView.frame.width + oldFromView.frame.width)

					UIView.animateWithDuration(duration, delay: 0, options: nil, animations: {
						fromView.frame = fromEndFrame
						toView.frame = toEndFrame
						oldFromView.frame = oldFromEndFrame
						}, completion: { [unowned self] finished in
							self.presented = !transitionContext.transitionWasCancelled()
							transitionContext.completeTransition(true)
							DLog("keyWindow subviews \(UIApplication.sharedApplication().keyWindow?.subviews)")
						})
				}
		} else if let toView = toView,
			let fromView = fromView  {
				DLog("dismiss")
				container.addSubview(toView)

				toView.frame.origin.x = 100

				var fromEndFrame = fromView.frame
				fromEndFrame.origin.x = -fromView.frame.size.width

				var toEndFrame = toView.frame
				toEndFrame.origin.x = 0

				UIView.animateWithDuration(duration, delay: 0, options: nil, animations: {
					fromView.frame = fromEndFrame
					toView.frame = toEndFrame
					}, completion: { [unowned self] finished in
						self.presented = transitionContext.transitionWasCancelled()
						transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
						DLog("keyWindow subviews \(UIApplication.sharedApplication().keyWindow?.subviews)")
					})
		}
	}
}
