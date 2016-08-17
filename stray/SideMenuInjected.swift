import Foundation

protocol SideMenuInjected: class {
	var sideMenuController: SideMenuController { get }
}

extension SideMenuInjected where Self: UIViewController {
	var sideMenuController: SideMenuController {
		get { return sideMenuControllerFor(viewController: self) }
	}

	private func sideMenuControllerFor(viewController controller: UIViewController) -> SideMenuController {
		if let sideController = controller as? SideMenuController {
			return sideController
		}

		if let parent = controller.parent {
			return sideMenuControllerFor(viewController: parent)
		}

		// TODO: Error handling
		fatalError("Missing SideMenuController")
	}
}
