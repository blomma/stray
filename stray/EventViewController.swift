import UIKit

class EventViewController: UIViewController {
	// MARK: IBOutlet
	@IBOutlet weak var eventTimer: EventTimer?
	@IBOutlet weak var toggleStartStopButton: UIButton?

	@IBOutlet weak var eventStartTime: UILabel?
	@IBOutlet weak var eventStartDay: UILabel?
	@IBOutlet weak var eventStartMonth: UILabel?
	@IBOutlet weak var eventStartYear: UILabel?

	@IBOutlet weak var eventTimeHours: UILabel?
	@IBOutlet weak var eventTimeMinutes: UILabel?

	@IBOutlet weak var eventStopTime: UILabel?
	@IBOutlet weak var eventStopDay: UILabel?
	@IBOutlet weak var eventStopMonth: UILabel?
	@IBOutlet weak var eventStopYear: UILabel?

	@IBOutlet weak var tag: UIButton?

	// MARK: Private properties
	private var modelView: EventViewModel = EventViewModel()

	override func viewDidLoad() {
		super.viewDidLoad()

		self.setNeedsStatusBarAppearanceUpdate()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		modelView.startDidUpdate = { [weak self]
			(value: Start) in
			
			guard
				let eventStartTime = self?.eventStartTime,
				let eventStartDay = self?.eventStartDay,
				let eventStartMonth = self?.eventStartMonth,
				let eventStartYear = self?.eventStartYear
				else { return }
			
			eventStartTime.text = value.time
			eventStartDay.text  = value.day
			eventStartMonth.text = value.month
			eventStartYear.text = value.year
		}

		modelView.stopDidUpdate = { [weak self]
			(value: Stop) in
			
			guard
				let eventStopTime = self?.eventStopTime,
				let eventStopDay = self?.eventStopDay,
				let eventStopYear = self?.eventStopYear,
				let eventStopMonth = self?.eventStopMonth
				else { return }
			
			eventStopTime.text = value.time
			eventStopDay.text  = value.day
			eventStopYear.text = value.year
			eventStopMonth.text = value.month
		}

		modelView.runningDidUpdate = { [weak self]
			(value: Running) in
			
			guard
				let eventTimeMinutes = self?.eventTimeMinutes,
				let eventTimeHours = self?.eventTimeHours
				else { return }
			
			eventTimeMinutes.text = value.minute
			eventTimeHours.text = value.hour
		}

		modelView.tagDidUpdate = { [weak self]
			(value: String?) in
			
			guard
				let tag = self?.tag
				else { return }
			
			if let value = value, let font = UIFont(name: "Helvetica Neue", size: 14) {
				let attriString = NSAttributedString(string:value, attributes: [NSAttributedStringKey.font: font])
				tag.setAttributedTitle(attriString, for: UIControlState())
			} else if let font = UIFont(name: "FontAwesome", size: 20) {
				let attriString = NSAttributedString(string:"\u{f02b}", attributes: [NSAttributedStringKey.font: font])
				tag.setAttributedTitle(attriString, for: UIControlState())
			}
		}

		modelView.isRunningDidUpdate = { [weak self]
			(value: IsRunning) in
			
			guard
				let toggleStartStopButton = self?.toggleStartStopButton,
				let eventTimer = self?.eventTimer
				else { return }
				
			toggleStartStopButton.setTitle(value.startStop, for: UIControlState())

			if value.isRunning {
                if let startDate = value.startDate {
                    eventTimer.setup(with: startDate, and: value.stopDate)
                }
				self?.animateStartEvent()
			} else {
                if let stopDate = value.stopDate {
                    eventTimer.stop(with: stopDate)
                }
				self?.animateStopEvent()
			}
		}

		eventTimer?.delegate = self

		modelView.setup()
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "segueToTagsFromEvent", let controller = segue.destination as? TagsViewController {
			controller.eventID = modelView.selectedEventID
		}
	}

	private func animateStartEvent() {
		UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseIn, animations: { () -> Void in
			self.eventStartTime?.alpha = 1
			self.eventStartDay?.alpha = 1
			self.eventStartMonth?.alpha = 1
			self.eventStartYear?.alpha = 1

			self.eventStopTime?.alpha = 0.2
			self.eventStopDay?.alpha = 0.2
			self.eventStopMonth?.alpha = 1
			self.eventStopYear?.alpha = 1
		}, completion: nil)
	}

	private func animateStopEvent() {
		UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseIn, animations: { () -> Void in
			self.eventStartTime?.alpha = 0.2
			self.eventStartDay?.alpha = 0.2
			self.eventStartMonth?.alpha = 1
			self.eventStartYear?.alpha = 1

			self.eventStopTime?.alpha = 1
			self.eventStopDay?.alpha = 1
			self.eventStopMonth?.alpha = 1
			self.eventStopYear?.alpha = 1
		}, completion: nil)
	}

	@IBAction func prepareForUnwind(_ sender: UIStoryboardSegue) {
		DLog()
	}

	@IBAction func showTags(_ sender: UIButton) {
		if modelView.selectedEventID != nil {
			performSegue(withIdentifier: "segueToTagsFromEvent", sender: self)
		}
	}

	@IBAction func toggleEventTouchUpInside(_ sender: UIButton) {
		modelView.toggleEventRunning()
	}

	override var prefersStatusBarHidden: Bool {
		return true
	}
}

// MARK: EventTimerDelegate
extension EventViewController: EventTimerDelegate {
	func updatedStart(to: Date, whileEditing: Bool) {
		modelView.updateStart(with: to, isTransforming: whileEditing)
	}

	func updatedStop(to: Date, whileEditing: Bool) {
		modelView.updateStop(with: to, isTransforming: whileEditing)
	}

	func updatedRunningWith(start: Date, stop: Date) {
		modelView.updateRunning(from: start, to: stop)
	}
}
