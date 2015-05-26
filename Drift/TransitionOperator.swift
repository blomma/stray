//
//  TransitionOperator.swift
//  Drift
//
//  Created by Mikael Hultgren on 04/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import Foundation
import UIKit

class TransitionOperator: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    var presenting: Bool = false

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.5
    }

    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView()

        if self.presenting,
            let toView = transitionContext.viewForKey(UITransitionContextToViewKey) {
                container.addSubview(toView)

                // Shadow
                toView.layer.shadowOffset = CGSizeMake(1, 1)
                toView.layer.shadowColor = UIColor.blackColor().CGColor
                toView.layer.shadowRadius = 3
                toView.layer.shadowOpacity = 0.4
                toView.layer.shadowPath = UIBezierPath(rect: toView.layer.bounds).CGPath

                // Initial position
                toView.frame = CGRectMake(-toView.frame.size.width, toView.frame.origin.y, toView.frame.size.width, toView.frame.size.height)
                let toEndFrame = CGRectMake(-toView.frame.size.width+100, toView.frame.origin.y, toView.frame.size.width, toView.frame.size.height)

                let duration = self.transitionDuration(transitionContext)
                UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: nil, animations: {
                    toView.frame = toEndFrame
                    }, completion: { finished in
                        transitionContext.completeTransition(true)
                })
        } else if let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey) {
            let fromEndFrame = CGRectMake(-fromView.frame.size.width, fromView.frame.origin.y, fromView.frame.size.width, fromView.frame.size.height)

            let duration = self.transitionDuration(transitionContext)
            UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: nil, animations: {
                fromView.frame = fromEndFrame
                }, completion: { finished in
                    transitionContext.completeTransition(true)
            })
        }
    }

    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = true
        return self
    }

    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.presenting = false
        return self
    }
}
