import Foundation

public class SideContainmentSegue: UIStoryboardSegue{

	override public func perform() {
		if let sideController = self.source as? SideMenuController {
			sideController.embed(sideViewController: destination)
		} else {
			fatalError("This type of segue must only be used from a SideMenuController")
		}
	}
}
