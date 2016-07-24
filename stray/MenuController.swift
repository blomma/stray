import UIKit

class MenuController: UIViewController {
    @IBAction func presentEvent(_ sender: UIButton) {
		if let navigationController = navigationController {
			if let _ = navigationController.viewControllers.first as? EventViewController {
				navigationController.popViewController(animated: true)
			} else if let controller = storyboard?.instantiateViewController(withIdentifier: "EventViewController") {
				navigationController.setViewControllers([controller], animated: true)
			}
		}
    }

    @IBAction func presentEvents(_ sender: UIButton) {
		if let navigationController = navigationController {
			if let _ = navigationController.viewControllers.first as? EventsViewController {
				navigationController.popViewController(animated: true)
			} else if let controller = storyboard?.instantiateViewController(withIdentifier: "EventsViewController") {
				navigationController.setViewControllers([controller], animated: true)
			}
		}
    }
}
