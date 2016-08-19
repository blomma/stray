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
	fileprivate var calendar = Calendar.autoupdatingCurrent

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

		modelView.startDidUpdate = { [unowned self]
			(start: StartComponents?) in

			guard let start = start else {
				self.eventStartTime?.text = ""
				self.eventStartDay?.text  = ""
				self.eventStartMonth?.text = ""
				self.eventStartYear?.text = ""

				return
			}

			let index = start.month - 1
			let shortMonth = self.calendar.shortStandaloneMonthSymbols[index]

			self.eventStartTime?.text = String(format: "%02ld:%02ld", start.hour, start.minute)
			self.eventStartDay?.text  = String(format: "%02ld", start.day)
			self.eventStartMonth?.text = shortMonth
			self.eventStartYear?.text = String(format: "%04ld", start.year)
		}

		modelView.stopDidUpdate = { [unowned self]
			(stop: StopComponents?) in

			guard let stop = stop else {
				self.eventStopTime?.text = ""
				self.eventStopDay?.text  = ""
				self.eventStopYear?.text = ""
				self.eventStopMonth?.text = ""

				return
			}

			let index = stop.month - 1
			let shortMonth = self.calendar.shortStandaloneMonthSymbols[index]

			self.eventStopTime?.text = String(format: "%02ld:%02ld", stop.hour, stop.minute)
			self.eventStopDay?.text  = String(format: "%02ld", stop.day)
			self.eventStopYear?.text = String(format: "%04ld", stop.year)
			self.eventStopMonth?.text = shortMonth
		}

		modelView.runningDidUpdate = { [unowned self]
			(running: RunningComponents?) in

			// Initial state
			guard let running = running else {
				self.eventTimeHours?.text = String(format:"%02ld", 0)
				self.eventTimeMinutes?.text = String(format:"%02ld", 0)

				return
			}

			let isFuture: Bool = running.hour < 0 || running.minute < 0

			self.eventTimeHours?.text = isFuture ? String(format:"-%02ld", abs(running.hour)) : String(format:"%02ld", abs(running.hour))
			self.eventTimeMinutes?.text = String(format:"%02ld", abs(running.minute))
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
			(isRunning: Bool, startDate: Date?, stopDate: Date?) in

			if isRunning {
				self.eventTimerControl?.initWithStart(startDate, andStop: stopDate)
				self.toggleStartStopButton?.setTitle("STOP", for: UIControlState())
				self.animateStartEvent()
			} else {
				self.eventTimerControl?.stop()
				self.toggleStartStopButton?.setTitle("START", for: UIControlState())
				self.animateStopEvent()
			}
		}

		modelView.setup()

		eventTimerControl?.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
}

// MARK: - EventTimerControlDelegate
extension EventViewController: EventTimerControlDelegate {
	func startDateDidUpdate(_ startDate: Date!) {
		modelView.updateStart(with: startDate)
	}

	func nowDateDidUpdate(_ nowDate: Date) {
		modelView.updateRunning(with: nowDate)
	}

	func transformingDidUpdate(_ transform: EventTimerTransformingEnum, withStart startDate: Date, andStop stopDate: Date) {
		switch transform {
		case .nowDateDidStart, .startDateDidStart:
			break
			// animateEventTransforming(transform)
		case .nowDateDidStop:
			// animateEventTransforming(transform)
			modelView.updateStop(with: stopDate)
		case .startDateDidStop:
			// animateEventTransforming(transform)
			modelView.updateStart(with: startDate)
		default:
			break
		}
	}
}
