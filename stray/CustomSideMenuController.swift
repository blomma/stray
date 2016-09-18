import Foundation

class CustomSideMenuContainerController: SideMenuContainerController {
	override func viewDidLoad() {
		super.viewDidLoad()

		performSegue(withIdentifier: "showEvent", sender: nil)
		performSegue(withIdentifier: "containSideMenu", sender: nil)
	}
}
