import UIKit

protocol EventCellDelegate : class {
	func didPressTag(_ cell:EventCell)
}

class EventCell: UITableViewCell {
	@IBOutlet weak var eventStartTime: UILabel!
	@IBOutlet weak var eventStartDay: UILabel!
	@IBOutlet weak var eventStartMonth: UILabel!
	@IBOutlet weak var eventStartYear: UILabel!

	@IBOutlet weak var eventTimeHours: UILabel!
	@IBOutlet weak var eventTimeMinutes: UILabel!

	@IBOutlet weak var eventStopTime: UILabel!
	@IBOutlet weak var eventStopDay: UILabel!
	@IBOutlet weak var eventStopMonth: UILabel!
	@IBOutlet weak var eventStopYear: UILabel!

	@IBOutlet weak var selectedMark: UIView!
	@IBOutlet weak var tagButton: UIButton!

	weak var delegate:EventCellDelegate?

	override func prepareForReuse() {
		selectedMark.alpha = 0
	}

	// IBActions
	@IBAction func editTag(_ sender: UIButton, forEvent event: UIEvent) {
		self.delegate?.didPressTag(self)
	}
}
