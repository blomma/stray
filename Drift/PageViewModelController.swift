//
//  PageViewModelController.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-08.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit

class PageViewModelController: NSObject, UIPageViewControllerDataSource {
    let pageData : [String]
    
    override init() {
        pageData = [
            "EventViewController",
            "EventsViewController",
            "EventStatisticsViewController"
        ]
        
        super.init()
    }
    
    func viewControllerAtIndex(index: Int, storyboard: UIStoryboard) -> UIViewController? {
        if pageData.count == 0 || index >= pageData.count {
            return nil
        }
        
        return storyboard.instantiateViewControllerWithIdentifier(pageData[index]) as? UIViewController
    }
    
    func indexOfViewController(viewController: UIViewController) -> Int? {
        if let identifier: String = viewController.restorationIdentifier,
            let i = find(pageData, identifier) {
                return i
        }
        
        return nil
    }
    
    // MARK: - Page View Controller Data Source
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let index = indexOfViewController(viewController) {
            if index > 0 {
                var beforeIndex = index - 1
                return viewControllerAtIndex(beforeIndex, storyboard: viewController.storyboard!)
            }
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let index = indexOfViewController(viewController) {
            var afterIndex = index + 1
            if afterIndex < pageData.count {
                return viewControllerAtIndex(afterIndex, storyboard: viewController.storyboard!)
            }
        }
        
        return nil
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return pageData.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
