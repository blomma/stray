import Foundation
import UIKit

class TransitionOperator: UIPercentDrivenInteractiveTransition {
	private var presented: Bool = false
	private var presenting: Bool = false
	private var interactionInProgress: Bool = false

    weak var navigationController: UINavigationController?

    convenience init(viewController: UIViewController) {
        self.init()

        navigationController = viewController.navigationController
		viewController.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handleGesture(_:))))
    }

	func handleGesture(_ recognizer: UIPanGestureRecognizer) {
		if let view = recognizer.view {
			let translation = recognizer.translation(in: view)
			let velocity = recognizer.velocity(in: view)
			let percentage = abs(translation.x / view.bounds.width)

			switch recognizer.state {
            case .began:
				if velocity.x > 0 && !presented {
                    if let navigationController = navigationController,
                        let controller = navigationController.storyboard?.instantiateViewController(withIdentifier: "MenuController") {
                            interactionInProgress = true
                            navigationController.delegate = self
                            navigationController.pushViewController(controller, animated: true)
                    }
                } else if velocity.x < 0 && presented {
                    if let navigationController = navigationController {
                        interactionInProgress = true
                        navigationController.delegate = self
                        navigationController.popViewController(animated: true)
                    }
                }
			case .changed:
                if !interactionInProgress {
                    return
                }

				update(percentage)
			case .ended:
                if !interactionInProgress {
                    return
                }

                completionSpeed = 0.5
				if percentage > 0.4 {
					finish()
				} else {
					cancel()
				}

				interactionInProgress = false
			case .cancelled:
                if !interactionInProgress {
                    return
                }

                completionSpeed = 0.5
				cancel()

				interactionInProgress = false
			default:
				break
			}
		}
	}
}

// MARK: - UINavigationControllerDelegate
extension TransitionOperator: UINavigationControllerDelegate {
	func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		switch operation {
		case .push:
			presenting = true
		default:
			presenting = false
		}

		return self
	}

	func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return interactionInProgress ? self : .none
	}
}

// MARK: - UIViewControllerTransitioningDelegate
extension TransitionOperator: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		self.presenting = true

		return self
	}

	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		presenting = false

		return self
	}

	func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		return interactionInProgress ? self : .none
	}

	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) ->
		UIViewControllerInteractiveTransitioning? {
		return interactionInProgress ? self : .none
	}
}

// MARK: - UIViewControllerAnimatedTransitioning
extension TransitionOperator: UIViewControllerAnimatedTransitioning {
	func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 0.5
	}

    typealias Animations = () -> Void
    typealias Completion = (Bool) -> Void
    private func animateWithDuration(_ duration: TimeInterval, animations: Animations, completion: Completion) {
        UIView.animate(withDuration: duration, delay: 0, options: [], animations: animations, completion: completion)
    }

	func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView

		var toView: UIView?
		if let view = transitionContext.view(forKey: UITransitionContextToViewKey) {
			toView = view
		}

		var fromView: UIView?
		if let view = transitionContext.view(forKey: UITransitionContextFromViewKey) {
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

                    animateWithDuration(transitionDuration(using: transitionContext), animations: {
                        fromView.frame = fromEndFrame
                        toView.frame = toEndFrame
                    }, completion: { finished in
                        self.presented = !transitionContext.transitionWasCancelled
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                        UIApplication.shared.keyWindow?.addSubview(fromView)
                    })
				} else if let oldFromView = UIApplication.shared.keyWindow?.subviews.last {
					container.addSubview(toView)

					toView.frame.origin.x = toView.frame.width
					var toEndFrame = toView.frame
					toEndFrame.origin.x = 0

					var oldFromEndFrame = oldFromView.frame
					oldFromEndFrame.origin.x = -oldFromView.frame.width

					var fromEndFrame = fromView.frame
					fromEndFrame.origin.x = -(fromView.frame.width + oldFromView.frame.width)

                    animateWithDuration(transitionDuration(using: transitionContext), animations: {
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

                animateWithDuration(transitionDuration(using: transitionContext), animations: {
                    fromView.frame = fromEndFrame
                    toView.frame = toEndFrame
                    }, completion: { finished in
                        self.presented = transitionContext.transitionWasCancelled
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

                        if transitionContext.transitionWasCancelled {
                            UIApplication.shared.keyWindow?.addSubview(toView)
                        }
                })
		}
	}
}
