//
//  MenuController.swift
//  Drift
//
//  Created by Mikael Hultgren on 05/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import UIKit

class MenuController: UIViewController {
    let transitionManager = TransitionOperator()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.transitioningDelegate = self.transitionManager
    }

    @IBAction func presentEvent(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)

        // Only replace controller if it is a new one
        if let navigation = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController
            where (navigation.viewControllers.first as? EventViewController == nil),
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("EventViewController") as? UIViewController {
                self.dismissViewControllerAnimated(true, completion: nil)
                navigation.setViewControllers([controller], animated: true)
        }
    }

    @IBAction func presentEvents(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)

        // Only replace controller if it is a new one
        if let navigation = UIApplication.sharedApplication().keyWindow?.rootViewController as? UINavigationController
            where (navigation.viewControllers.first as? EventsViewController == nil),
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("EventsViewController") as? UIViewController {
                self.dismissViewControllerAnimated(true, completion: nil)
                navigation.setViewControllers([controller], animated: true)
        }
    }
}
