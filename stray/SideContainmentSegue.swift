import Foundation

public class SideContainmentSegue: UIStoryboardSegue {
	override public func perform() {
		guard let sideMenuContainerController = self.source as? SideMenuContainerController else {
			fatalError("This type of segue must only be used from a SideMenuContainerController")
		}

		sideMenuContainerController.embed(sideViewController: destination)
	}
}
