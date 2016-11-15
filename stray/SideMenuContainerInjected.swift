import Foundation
import UIKit

protocol SideMenuContainerInjected: class {
	var sideMenuContainerController: SideMenuContainerController { get }
}

extension SideMenuContainerInjected where Self: UIViewController {
	var sideMenuContainerController: SideMenuContainerController {
		get { return sideMenuContainerControllerFor(viewController: self) }
	}

	private func sideMenuContainerControllerFor(viewController controller: UIViewController) -> SideMenuContainerController {
		if let sideMenuContainerController = controller as? SideMenuContainerController {
			return sideMenuContainerController
		}

		if let parent = controller.parent {
			return sideMenuContainerControllerFor(viewController: parent)
		}

		// TODO: Error handling
		fatalError("Missing SideMenuContainerController")
	}
}
