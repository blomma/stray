//
//  Animator.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-05.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit

@objc protocol SlideUpTransitioningDelegate : class {
    func proceedToNextViewController()
}

class SlideUpTransitioning: UIPercentDrivenInteractiveTransition, UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning {
    var isPresentation: Bool = false

    lazy var gestureRecogniser: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: "handleGesture:")
        }()
    
    var interactionInProgress: Bool = false
    
    weak var delegate:SlideUpTransitioningDelegate?
    var dimmingView: UIView!

    func handleGesture(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translationInView(recognizer.view!)
        let velocity = recognizer.velocityInView(recognizer.view)
        
        let percentage = abs(translation.x / CGRectGetWidth(recognizer.view!.bounds))
        
        switch recognizer.state {
        case .Began:
            // Panning right
            if velocity.x < 0 {
                interactionInProgress = true
                delegate?.proceedToNextViewController()
            }
        case .Changed:
            // We have gone beyond the bottom barrier of the view where we started
            // stop updating, this happens when we are inside a navigationcontroller
            // that has a bottom component
//            if translation.y > 0 {
//                return
//            }
            
            updateInteractiveTransition(percentage)
        case .Ended:
            if percentage < 0.5 {
                cancelInteractiveTransition()
            } else {
                finishInteractiveTransition()
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

// UIViewControllerTransitioningDelegate
typealias SlideUpUIViewControllerTransitioningDelegate = SlideUpTransitioning
extension SlideUpUIViewControllerTransitioningDelegate {
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresentation = true
        return self
    }
    
    func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionInProgress ? self : nil
    }
}

// UIViewControllerAnimatedTransitioning
typealias SlideUpUIViewControllerAnimatedTransitioning = SlideUpTransitioning
extension SlideUpUIViewControllerAnimatedTransitioning {
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 1
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        var toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        var fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        var containerView = transitionContext.containerView()
        
        if isPresentation {
            containerView.addSubview(toViewController.view)
        }
        
        var presentedController = isPresentation ? toViewController : fromViewController
        var presentedView = presentedController.view

        var presentingController = isPresentation ? fromViewController : toViewController
        var presentingView = presentingController.view
        
        var appearedFrame = transitionContext.finalFrameForViewController(presentedController)
        var dismissedFrame = appearedFrame
        dismissedFrame.origin.x += dismissedFrame.size.width
        
        var initialFrame = dismissedFrame
        var finalFrame = appearedFrame
        
        var presentingViewFinalFrame = appearedFrame
        presentingViewFinalFrame.origin.x -= appearedFrame.size.width
        
        presentedView.frame = initialFrame
        
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: .CurveLinear, animations: { () -> Void in
            presentedView.frame = finalFrame
            presentingView.frame = presentingViewFinalFrame
            }) { (Bool) -> Void in
//                if !self.isPresentation {
//                    fromViewController.view.removeFromSuperview()
//                }
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
    }
}
