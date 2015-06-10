//
//  MenuController.swift
//  Drift
//
//  Created by Mikael Hultgren on 05/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import UIKit

class MenuController: UIViewController {
    @IBAction func presentEvent(sender: UIButton) {
		if let navigationController = navigationController {
			if let _ = navigationController.viewControllers.first as? EventViewController {
				navigationController.popViewControllerAnimated(true)
			} else if let controller = storyboard?.instantiateViewControllerWithIdentifier("EventViewController") as? UIViewController {
				navigationController.setViewControllers([controller], animated: true)
			}
		}
    }

    @IBAction func presentEvents(sender: UIButton) {
		if let navigationController = navigationController {
			if let _ = navigationController.viewControllers.first as? EventsViewController {
				navigationController.popViewControllerAnimated(true)
			} else if let controller = storyboard?.instantiateViewControllerWithIdentifier("EventsViewController") as? UIViewController {
				navigationController.setViewControllers([controller], animated: true)
			}
		}
    }
}
