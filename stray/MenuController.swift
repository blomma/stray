import UIKit

class MenuController: UITableViewController, SideMenuContainerInjected {
	let segues = ["showEvent", "showEvents", "showCenterController3"]
	private var previousIndex: IndexPath?

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return segues.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell")!
		cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 15)
		cell.textLabel?.text = "Switch to controller \((indexPath as NSIndexPath).row + 1)"

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let index = previousIndex {
			tableView.deselectRow(at: index, animated: true)
		}

		previousIndex = indexPath
		sideMenuContainerController.performSegue(withIdentifier: segues[(indexPath as NSIndexPath).row], sender: nil)
	}
}
