import Foundation

public extension UIViewController {
	public var sideMenuController: SideMenuController? {
		return sideMenuControllerForViewController(self)
	}

	private func sideMenuControllerForViewController(_ controller : UIViewController) -> SideMenuController?
	{
		if let sideController = controller as? SideMenuController {
			return sideController
		}

		if let parent = controller.parent {
			return sideMenuControllerForViewController(parent)
		} else {
			return nil
		}
	}
}
