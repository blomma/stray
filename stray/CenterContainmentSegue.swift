import Foundation

public class CenterContainmentSegue: UIStoryboardSegue {
	override public func perform() {
		guard let sideMenuContainerController = source as? SideMenuContainerController else {
			fatalError("This type of segue must only be used from a SideMenuContainerController")
		}

		guard let destinationController = destination as? UINavigationController else {
			fatalError("Destination controller needs to be an instance of UINavigationController")
		}

		sideMenuContainerController.embed(centerViewController: destinationController)
	}
}
