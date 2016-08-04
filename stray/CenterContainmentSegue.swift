import Foundation

public class CenterContainmentSegue: UIStoryboardSegue{

	override public func perform() {
		if let sideController = self.source as? SideMenuController {
			guard let destinationController = destination as? UINavigationController else {
				fatalError("Destination controller needs to be an instance of UINavigationController")
			}
			sideController.embed(centerViewController: destinationController)
		} else {
			fatalError("This type of segue must only be used from a SideMenuController")
		}
	}
}
