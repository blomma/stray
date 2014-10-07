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
        
        let percentage = abs(translation.y / CGRectGetHeight(recognizer.view!.bounds))
        
        switch recognizer.state {
        case .Began:
            // Panning down
            if velocity.y > 0 {
                return
            }
            
            interactionInProgress = true
            delegate?.proceedToNextViewController()
        case .Changed:
            // We have gone beyond the bottom barrier of the view where we started
            // stop updating, this happens when we are inside a navigationcontroller
            // that has a bottom component
            if translation.y > 0 {
                return
            }
            
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
        return self
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
        
        dimmingView = UIView()
        dimmingView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        dimmingView.alpha = 0
        dimmingView.frame = containerView.bounds
        
        containerView.addSubview(dimmingView)
        
        if isPresentation {
            containerView.addSubview(toViewController.view)
        }
        
        var animatingController = isPresentation ? toViewController : fromViewController
        var animatingView = animatingController.view
        
        var appearedFrame = transitionContext.finalFrameForViewController(animatingController)
        var dismissedFrame = appearedFrame
        dismissedFrame.origin.y += dismissedFrame.size.height
        
        var initialFrame = isPresentation ? dismissedFrame : appearedFrame
        var finalFrame = isPresentation ? appearedFrame : dismissedFrame
        
        animatingView.frame = initialFrame
        
        var layer = toViewController.view.layer
        layer.shadowOffset = CGSizeMake(1, 1)
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowRadius = 4.0
        layer.shadowOpacity = 0.80
        layer.shadowPath = UIBezierPath(rect: layer.bounds).CGPath
        
        UIView.animateWithDuration(transitionDuration(transitionContext), delay: 0, options: .CurveLinear, animations: { () -> Void in
            self.dimmingView.alpha = 1
            animatingView.frame = finalFrame
            }) { (Bool) -> Void in
                if !self.isPresentation {
                    fromViewController.view.removeFromSuperview()
                }
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
        }
    }
}
