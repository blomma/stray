import Foundation

public class SideContainmentSegue: UIStoryboardSegue {
	override public func perform() {
		guard let sideController = self.source as? SideMenuController else {
			fatalError("This type of segue must only be used from a SideMenuController")
		}
		
		sideController.embed(sideViewController: destination)
	}
}
