import UIKit
import CoreData

class EventViewController: UIViewController, EventTimerControlDelegate, CoreDataInjected {
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
    private var selectedEventGuid: String?

    private let state = State()
    private var transitionOperator: TransitionOperator?

    private let calendar = Calendar.autoupdatingCurrent
    private let shortStandaloneMonthSymbols: NSArray = DateFormatter().shortStandaloneMonthSymbols

    override func viewDidLoad() {
        super.viewDidLoad()

        self.transitionOperator = TransitionOperator(viewController: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let eventTimerControl = eventTimerControl, let tag = tag else {
            fatalError("TimerControl or tag is not an instance")
        }

        eventTimerControl.delegate = self

        var tagName: String? = nil
        if let guid = state.selectedEventGUID {
			let predicate = Predicate(format: "guid = %@", argumentArray: [guid])
			let result: Result<Event, FetchError> = fetchFirst(wherePredicate: predicate, inContext: persistentContainer.viewContext)
			do {
				let event = try result.dematerialize()
				selectedEventGuid = event.guid
				tagName = event.inTag?.name
				
				eventTimerControl.initWithStart(event.startDate, andStop: event.stopDate)
				
				if let _ = event.stopDate {
					toggleStartStopButton?.setTitle("START", for: UIControlState())
					animateStopEvent()
				} else {
					toggleStartStopButton?.setTitle("STOP", for: UIControlState())
					animateStartEvent()
				}
			} catch {
				// Error handling
			}
        } else {
            selectedEventGuid = nil
        }

        if let tagName = tagName,
            let font = UIFont(name: "Helvetica Neue", size: 14) {
                let attriString = AttributedString(string:tagName, attributes:
                    [NSFontAttributeName: font])

                tag.setAttributedTitle(attriString, for: UIControlState())
        } else if let font = UIFont(name: "FontAwesome", size: 20) {
            let attriString = AttributedString(string:"\u{f02b}", attributes:
                [NSFontAttributeName: font])

            tag.setAttributedTitle(attriString, for: UIControlState())
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        guard let eventTimerControl = eventTimerControl else {
            fatalError("TimerControl is not an instance")
        }

		eventTimerControl.delegate = nil
		eventTimerControl.stop()
    }

	override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "segueToTagsFromEvent",
			let controller = segue.destinationViewController as? TagsViewController,
            let guid = selectedEventGuid {
				controller.eventGuid = guid
		}
	}

    private func updateStartLabelWithDate(_ date: Date) {
        let unitFlags: Calendar.Unit = [.year, .month, .day, .hour, .minute]

        let components: DateComponents = calendar.components(unitFlags, from: date)

        eventStartTime?.text  = String(format: "%02ld:%02ld", components.hour!, components.minute!)
        eventStartDay?.text  = String(format: "%02ld", components.day!)
        eventStartYear?.text  = String(format: "%04ld", components.year!)
        let index = components.month! - 1
        if let month = shortStandaloneMonthSymbols.object(at: index) as? String {
            eventStartMonth?.text  = month
        }
    }

    private func updateEventTimeFromDate(_ fromDate: Date, toDate: Date) {
        let unitFlags: Calendar.Unit = [.hour, .minute]
        let components: DateComponents = calendar.components(unitFlags, from: fromDate, to: toDate, options: [])

        let hour: Int = abs(components.hour!)
        let minute: Int = abs(components.minute!)

        var timeHours: String = String(format:"%02ld", hour)
        if components.hour < 0 || components.minute < 0 {
            timeHours = String(format:"-%@", timeHours)
        }

        eventTimeHours?.text   = timeHours
        eventTimeMinutes?.text = String(format:"%02ld", minute)
    }

    private func updateStopLabelWithDate(_ date: Date) {
        let unitFlags: Calendar.Unit = [.year, .month, .day, .hour, .minute]

        let components: DateComponents = calendar.components(unitFlags, from: date)

        eventStopTime?.text  = String(format: "%02ld:%02ld", components.hour!, components.minute!)
        eventStopDay?.text  = String(format: "%02ld", components.day!)
        eventStopYear?.text  = String(format: "%04ld", components.year!)
        let index = components.month! - 1
        if let month = shortStandaloneMonthSymbols.object(at: index) as? String {
            eventStopMonth?.text  = month
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

    private func animateEventTransforming(_ eventTimerTransformingEnum: EventTimerTransformingEnum) {
        UIView.animate(withDuration: 0.3, delay: 0.3, options: .curveEaseIn, animations: { () -> Void in
            var eventStartAlpha: CGFloat = 1
            var eventStopAlpha: CGFloat = 1
            var eventTimeAlpha: CGFloat = 1
            var eventStartMonthYearAlpha: CGFloat = 1
            var eventStopMonthYearAlpha: CGFloat = 1

            switch eventTimerTransformingEnum {
            case .startDateTransformingStart:
                eventStartAlpha = 1
                eventStartMonthYearAlpha = 1

                eventStopAlpha = 0.2
                eventStopMonthYearAlpha = 0.2

                eventTimeAlpha = 0.2
            case .startDateTransformingStop:
                if let _ = self.selectedEvent(self.selectedEventGuid)?.stopDate {
                    eventStartAlpha = 0.2
                    eventStopAlpha = 1
                } else {
                    eventStartAlpha = 1
                    eventStopAlpha = 0.2
                }

                eventStartMonthYearAlpha = 1
                eventStopMonthYearAlpha = 1

                eventTimeAlpha = 1
            case .nowDateTransformingStart:
                eventStartAlpha = 0.2
                eventStartMonthYearAlpha = 0.2

                eventStopAlpha = 1
                eventStopMonthYearAlpha = 1

                eventTimeAlpha = 0.2
            case .nowDateTransformingStop:
                if let _ = self.selectedEvent(self.selectedEventGuid)?.stopDate {
                    eventStartAlpha = 0.2
                    eventStopAlpha = 1
                } else {
                    eventStartAlpha = 1
                    eventStopAlpha = 0.2
                }

                eventStartMonthYearAlpha = 1
                eventStopMonthYearAlpha = 1

                eventTimeAlpha = 1
            default:
                break
            }

            self.eventStartDay?.alpha = eventStartAlpha
            self.eventStartMonth?.alpha = eventStartMonthYearAlpha
            self.eventStartTime?.alpha = eventStartAlpha
            self.eventStartYear?.alpha = eventStartMonthYearAlpha

            self.eventStopDay?.alpha = eventStopAlpha
            self.eventStopMonth?.alpha = eventStopMonthYearAlpha
            self.eventStopTime?.alpha = eventStopAlpha
            self.eventStopYear?.alpha = eventStopMonthYearAlpha

            self.eventTimeHours?.alpha = eventTimeAlpha
            self.eventTimeMinutes?.alpha = eventTimeAlpha

            }, completion: nil)
    }

	@IBAction func prepareForUnwind(_ sender: UIStoryboardSegue) {
		DLog()
	}

    @IBAction func showTags(_ sender: UIButton) {
        if selectedEventGuid != nil {
            navigationController?.delegate = nil
            performSegue(withIdentifier: "segueToTagsFromEvent", sender: self)
        }
    }

    @IBAction func toggleEventTouchUpInside(_ sender: UIButton) {
        guard let eventTimerControl = eventTimerControl, let tag = tag else {
            fatalError("TimerControl is not an instance")
        }

        if let guid = selectedEventGuid {
            guard let event = self.selectedEvent(guid) else {
                fatalError("Have guid but cant find the event")
            }

            if let _ = event.stopDate {
				// Event is stoped, so start a new
				let event = Event(persistentContainer.viewContext, startDate: Date())
                selectedEventGuid = event.guid
				state.selectedEventGUID = event.guid

				eventTimerControl.initWithStart(event.startDate as Date, andStop: event.stopDate)

				toggleStartStopButton?.setTitle("STOP", for: UIControlState())

				animateStartEvent()

				if let font = UIFont(name: "FontAwesome", size: 20) {
					let attriString = AttributedString(string:"\u{f02b}", attributes:
						[NSFontAttributeName: font])

					tag.setAttributedTitle(attriString, for: UIControlState())
				}
            } else {
                // Event is started
                eventTimerControl.stop()
                event.stopDate = eventTimerControl.nowDate

                toggleStartStopButton?.setTitle("START", for: UIControlState())
                animateStopEvent()
            }
        } else {
			// No event exists, start a new
			// Event is stoped, so start a new
			let event = Event(persistentContainer.viewContext, startDate: Date())
            selectedEventGuid = event.guid
            state.selectedEventGUID = event.guid

			eventTimerControl.initWithStart(event.startDate as Date, andStop: event.stopDate)

			toggleStartStopButton?.setTitle("STOP", for: UIControlState())

			animateStartEvent()

			if let font = UIFont(name: "FontAwesome", size: 20) {
				let attriString = AttributedString(string:"\u{f02b}", attributes:
					[NSFontAttributeName: font])

				tag.setAttributedTitle(attriString, for: UIControlState())
			}
		}

        do {
			try save(context: persistentContainer.viewContext)
        } catch {
			// TODO: Errorhandling
			print("*** ERROR: [\(#line)] \(#function) Error while executing fetch request:")
        }
    }

    private func selectedEvent(_ guid: String?) -> Event? {
		guard let guid = guid else {
			return nil
        }

		let predicate = Predicate(format: "guid = %@", argumentArray: [guid])
		let result: Result<Event, FetchError> = fetchFirst(wherePredicate: predicate, inContext: persistentContainer.viewContext)
        do {
			return try result.dematerialize()
		} catch {
			// TODO: Errorhandling
            print("*** ERROR: [\(#line)] \(#function) Error while executing fetch request:")
		}

        return nil
    }
}

// MARK: - EventTimerControlDelegate
extension EventViewController {
    func startDateDidUpdate(_ startDate: Date!) {
            updateStartLabelWithDate(startDate)

            if let toDate = eventTimerControl?.nowDate {
                updateEventTimeFromDate(startDate, toDate: toDate)
            }
    }

    func nowDateDidUpdate(_ nowDate: Date!) {
        updateStopLabelWithDate(nowDate)

        if let fromDate = eventTimerControl?.startDate {
            updateEventTimeFromDate(fromDate, toDate: nowDate)
        }
    }

    func transformingDidUpdate(_ transform: EventTimerTransformingEnum) {
        switch transform {
        case .nowDateTransformingStart, .startDateTransformingStart:
            animateEventTransforming(transform)
        case .nowDateTransformingStop:
            guard let event = selectedEvent(selectedEventGuid) else {
                break
            }

            animateEventTransforming(transform)
            event.stopDate = eventTimerControl?.nowDate

			do {
				try save(context: persistentContainer.viewContext)
			} catch {
				// TODO: Errorhandling
				print("*** ERROR: [\(#line)] \(#function) Error while executing fetch request:")
			}
        case .startDateTransformingStop:
            animateEventTransforming(transform)
            if let startDate = eventTimerControl?.startDate {
                guard let event = selectedEvent(selectedEventGuid) else {
                    break
                }
                event.startDate = startDate

				do {
					try save(context: persistentContainer.viewContext)
				} catch {
					// TODO: Errorhandling
					print("*** ERROR: [\(#line)] \(#function) Error while executing fetch request:")
				}
			}
        default:
            break
        }
    }
}
