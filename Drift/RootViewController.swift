//
//  RootViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-08.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UIPageViewControllerDelegate {
    let modelController: PageViewModelController = PageViewModelController()
    
    var pageViewController: UIPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        self.pageViewController.delegate = self
        
        if let startingViewController = modelController.viewControllerAtIndex(0, storyboard: self.storyboard!) {
            let viewControllers: NSArray = [startingViewController]
            self.pageViewController.setViewControllers(viewControllers, direction: .Forward, animated: false, completion: {done in })
        }
        
        self.pageViewController.dataSource = self.modelController
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)

        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        var pageViewRect = self.view.bounds
        self.pageViewController.view.frame = pageViewRect
        
        self.pageViewController.didMoveToParentViewController(self)
        
        // Add the page view controller's gesture recognizers to the view controller's view so that the gestures are started more easily.
        self.view.gestureRecognizers = self.pageViewController.gestureRecognizers
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        NSNotificationCenter
            .defaultCenter()
            .postNotificationName("rootViewDidAppear", object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
