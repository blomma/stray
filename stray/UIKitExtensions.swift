import Foundation

extension UIView {
	class func panelAnimation(_ duration : TimeInterval, animations : (()->()), completion : (()->())? = nil) {
		UIView.animate(withDuration: duration, animations: animations) { _ -> Void in
			completion?()
		}
	}
}

//public extension UINavigationController {
//	public func addSideMenuButton() {
//		guard let image = SideMenuController.preferences.drawing.menuButtonImage else {
//			return
//		}
//
//		guard let sideMenuController = self.sideMenuController else {
//			return
//		}
//
//		let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
//		button.accessibilityIdentifier = SideMenuController.preferences.interaction.menuButtonAccessibilityIdentifier
//		button.setImage(image, for: UIControlState())
//		button.addTarget(sideMenuController, action: #selector(SideMenuController.toggle), for: UIControlEvents.touchUpInside)
//
//		let item:UIBarButtonItem = UIBarButtonItem()
//		item.customView = button
//
//		let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
//		spacer.width = -10
//
//		if SideMenuController.preferences.drawing.sidePanelPosition.isPositionedLeft {
//			self.topViewController?.navigationItem.leftBarButtonItems = [spacer, item]
//		}else{
//			self.topViewController?.navigationItem.rightBarButtonItems = [spacer, item]
//		}
//	}
//}

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
