//
//  TransitionOperator.swift
//  Drift
//
//  Created by Mikael Hultgren on 04/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import UIKit

class TransitionOperator: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
	private var presented: Bool = false
	private var presenting: Bool = false
	private var interactionInProgress: Bool = false

    weak var navigationController: UINavigationController?

    convenience init(viewController: UIViewController) {
        self.init()

        navigationController = viewController.navigationController
        viewController.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: "handleGesture:"))
    }

	func handleGesture(recognizer: UIPanGestureRecognizer) {
		if let view = recognizer.view {
			let translation = recognizer.translationInView(view)
			let velocity = recognizer.velocityInView(view)
			let percentage = abs(translation.x / CGRectGetWidth(view.bounds))

			switch recognizer.state {
            case .Began:
				if velocity.x > 0 && !presented {
                    if let navigationController = navigationController,
                        let controller = navigationController.storyboard?.instantiateViewControllerWithIdentifier("MenuController") {
                            interactionInProgress = true
                            navigationController.delegate = self
                            navigationController.pushViewController(controller, animated: true)
                    }
                } else if velocity.x < 0 && presented {
                    if let navigationController = navigationController {
                        interactionInProgress = true
                        navigationController.delegate = self
                        navigationController.popViewControllerAnimated(true)
                    }
                }
			case .Changed:
                if !interactionInProgress {
                    return
                }

				updateInteractiveTransition(percentage)
			case .Ended:
                if !interactionInProgress {
                    return
                }

                completionSpeed = 0.5
				if percentage > 0.4 {
					finishInteractiveTransition()
				} else {
					cancelInteractiveTransition()
				}

				interactionInProgress = false
			case .Cancelled:
                if !interactionInProgress {
                    return
                }

                completionSpeed = 0.5
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
	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
		return 0.5
	}

    typealias Animations = () -> Void
    typealias Completion = (Bool) -> Void
    private func animateWithDuration(duration: NSTimeInterval, animations: Animations, completion: Completion) {
        UIView.animateWithDuration(duration, delay: 0, options: [], animations: animations, completion: completion)
    }

	func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let container = transitionContext.containerView() else {
            return
        }

		var toView: UIView?
		if let view = transitionContext.viewForKey(UITransitionContextToViewKey) {
			toView = view
		}

		var fromView: UIView?
		if let view = transitionContext.viewForKey(UITransitionContextFromViewKey) {
			fromView = view
		}

		if presenting,
			let toView = toView,
			let fromView = fromView {
				if interactionInProgress {
					container.addSubview(toView)

					toView.frame.origin.x = -toView.frame.width

					var toEndFrame = toView.frame
					toEndFrame.origin.x = -toView.frame.size.width+100

					var fromEndFrame = fromView.frame
					fromEndFrame.origin.x = 100

                    animateWithDuration(transitionDuration(transitionContext), animations: {
                        fromView.frame = fromEndFrame
                        toView.frame = toEndFrame
                    }, completion: { finished in
                        self.presented = !transitionContext.transitionWasCancelled()
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                        UIApplication.sharedApplication().keyWindow?.addSubview(fromView)
                    })
				} else if let oldFromView = UIApplication.sharedApplication().keyWindow?.subviews.last {
					container.addSubview(toView)

					toView.frame.origin.x = toView.frame.width
					var toEndFrame = toView.frame
					toEndFrame.origin.x = 0

					var oldFromEndFrame = oldFromView.frame
					oldFromEndFrame.origin.x = -oldFromView.frame.width

					var fromEndFrame = fromView.frame
					fromEndFrame.origin.x = -(fromView.frame.width + oldFromView.frame.width)

                    animateWithDuration(transitionDuration(transitionContext), animations: {
                        fromView.frame = fromEndFrame
                        toView.frame = toEndFrame
                        oldFromView.frame = oldFromEndFrame
                        }, completion: { finished in
                            oldFromView.removeFromSuperview()
                            transitionContext.completeTransition(true)
                    })
				}
		} else if let toView = toView,
			let fromView = fromView  {
				container.addSubview(toView)

				toView.frame.origin.x = 100

				var fromEndFrame = fromView.frame
				fromEndFrame.origin.x = -fromView.frame.size.width

				var toEndFrame = toView.frame
				toEndFrame.origin.x = 0

                animateWithDuration(transitionDuration(transitionContext), animations: {
                    fromView.frame = fromEndFrame
                    toView.frame = toEndFrame
                    }, completion: { finished in
                        self.presented = transitionContext.transitionWasCancelled()
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())

                        if transitionContext.transitionWasCancelled() {
                            UIApplication.sharedApplication().keyWindow?.addSubview(toView)
                        }
                })
		}
	}
}
