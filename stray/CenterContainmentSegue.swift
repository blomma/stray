import Foundation

public class CenterContainmentSegue: UIStoryboardSegue {
	override public func perform() {
		guard let sideController = source as? SideMenuController else {
			fatalError("This type of segue must only be used from a SideMenuController")
		}

		guard let destinationController = destination as? UINavigationController else {
			fatalError("Destination controller needs to be an instance of UINavigationController")
		}

		sideController.embed(centerViewController: destinationController)
	}
}
