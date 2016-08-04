import Foundation

class CustomSideMenuController: SideMenuController {
	override func viewDidLoad() {
		super.viewDidLoad()
		performSegue(withIdentifier: "showEvent", sender: nil)
		performSegue(withIdentifier: "containSideMenu", sender: nil)
	}
}
