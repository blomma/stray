import UIKit

class EventViewController: UIViewController {
    // MARK: IBOutlet
    @IBOutlet weak var eventTimerControl: EventTimerControl?
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
	fileprivate var modelView: EventViewModel = EventViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

		self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		modelView.startDidUpdate = { [unowned self]
			(value: Start) in

			self.eventStartTime?.text = value.time
			self.eventStartDay?.text  = value.day
			self.eventStartMonth?.text = value.month
			self.eventStartYear?.text = value.year
		}

		modelView.stopDidUpdate = { [unowned self]
			(value: Stop) in

			self.eventStopTime?.text = value.time
			self.eventStopDay?.text  = value.day
			self.eventStopYear?.text = value.year
			self.eventStopMonth?.text = value.month
		}

		modelView.runningDidUpdate = { [unowned self]
			(value: Running) in

			self.eventTimeMinutes?.text = value.minute
			self.eventTimeHours?.text = value.hour
		}

		modelView.tagDidUpdate = { [unowned self]
			(tag: String?) in

			if let tag = tag,
				let font = UIFont(name: "Helvetica Neue", size: 14) {
				let attriString = NSAttributedString(string:tag, attributes: [NSFontAttributeName: font])
				self.tag?.setAttributedTitle(attriString, for: UIControlState())
			} else if let font = UIFont(name: "FontAwesome", size: 20) {
				let attriString = NSAttributedString(string:"\u{f02b}", attributes: [NSFontAttributeName: font])
				self.tag?.setAttributedTitle(attriString, for: UIControlState())
			}
		}

		modelView.isRunningDidUpdate = { [unowned self]
			(value: IsRunning) in

			self.toggleStartStopButton?.setTitle(value.startStop, for: UIControlState())

			if value.isRunning {
				self.eventTimerControl?.initWithStart(value.startDate, andStop: value.stopDate)
				self.animateStartEvent()
			} else {
				self.eventTimerControl?.stop(value.stopDate)
				self.animateStopEvent()
			}
		}

		modelView.setup()

		eventTimerControl?.delegate = self
    }

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		eventTimerControl?.delegate = nil
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "segueToTagsFromEvent",
			let controller = segue.destination as? TagsViewController {
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

// MARK: - EventTimerControlDelegate
extension EventViewController: EventTimerControlDelegate {
	func startDateDidUpdate(_ startDate: Date) {
		modelView.updateStart(with: startDate)
	}

	func runningDateDidUpdate(from fromDate: Date, to toDate: Date?) {
		modelView.updateRunning(from: fromDate, to: toDate)
	}

	func stopDateDidUpdate(_ stopDate: Date?) {
		modelView.updateStop(with: stopDate)
	}

	func transformingDidUpdate(_ transform: EventTimerTransformingEnum, with date: Date) {
		switch transform {
		case .startDateDidChange:
			modelView.updateStart(with: date)
		case .stopDateDidChange:
			modelView.updateStop(with: date)
		}
	}
}
