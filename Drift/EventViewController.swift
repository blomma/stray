//
//  EventViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 02/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import UIKit
import CoreData

class EventViewController: UIViewController, EventTimerControlDelegate {
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

    private let calendar = NSCalendar.autoupdatingCurrentCalendar()
    private let shortStandaloneMonthSymbols: NSArray = NSDateFormatter().shortStandaloneMonthSymbols

    override func viewDidLoad() {
        super.viewDidLoad()

        self.transitionOperator = TransitionOperator(viewController: self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        guard let eventTimerControl = eventTimerControl, let tag = tag else {
            fatalError("TimerControl or tag is not an instance")
        }

        eventTimerControl.delegate = self

        var tagName: String? = nil
        if let guid = state.selectedEventGUID {
            let request = FetchRequest<Event>(context: defaultCoreDataStack.managedObjectContext)
            do {
                let event = try request.fetchFirstWhere("guid", value: guid)
                selectedEventGuid = event.guid
                tagName = event.inTag?.name

                eventTimerControl.initWithStartDate(event.startDate, andStopDate: event.stopDate)

                if let _ = event.stopDate {
                    toggleStartStopButton?.setTitle("START", forState: .Normal)
                    animateStopEvent()
                } else {
                    toggleStartStopButton?.setTitle("STOP", forState: .Normal)
                    animateStartEvent()
                }
            } catch {
                print("*** ERROR: [\(__LINE__)] \(__FUNCTION__) \(error) Error while executing fetch request:")
            }
        } else {
            selectedEventGuid = nil
        }

        if let tagName = tagName,
            let font = UIFont(name: "Helvetica Neue", size: 14) {
                let attriString = NSAttributedString(string:tagName, attributes:
                    [NSFontAttributeName: font])

                tag.setAttributedTitle(attriString, forState: .Normal)
        } else if let font = UIFont(name: "FontAwesome", size: 20) {
            let attriString = NSAttributedString(string:"\u{f02b}", attributes:
                [NSFontAttributeName: font])

            tag.setAttributedTitle(attriString, forState: .Normal)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        guard let eventTimerControl = eventTimerControl else {
            fatalError("TimerControl is not an instance")
        }

		eventTimerControl.delegate = nil
		eventTimerControl.stop()
    }

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "segueToTagsFromEvent",
			let controller = segue.destinationViewController as? TagsViewController,
            let guid = selectedEventGuid {
				controller.eventGuid = guid
		}
	}

    private func updateStartLabelWithDate(date: NSDate) {
        let unitFlags: NSCalendarUnit = [.Year, .Month, .Day, .Hour, .Minute]

        let components: NSDateComponents = calendar.components(unitFlags, fromDate: date)

        eventStartTime?.text  = String(format: "%02ld:%02ld", components.hour, components.minute)
        eventStartDay?.text  = String(format: "%02ld", components.day)
        eventStartYear?.text  = String(format: "%04ld", components.year)
        let index = components.month - 1
        if let month = shortStandaloneMonthSymbols.objectAtIndex(index) as? String {
            eventStartMonth?.text  = month
        }
    }

    private func updateEventTimeFromDate(fromDate: NSDate, toDate: NSDate) {
        let unitFlags: NSCalendarUnit = [.Hour, .Minute]
        let components: NSDateComponents = calendar.components(unitFlags, fromDate: fromDate, toDate: toDate, options: [])

        let hour: Int = abs(components.hour)
        let minute: Int = abs(components.minute)

        var timeHours: String = String(format:"%02ld", hour)
        if components.hour < 0 || components.minute < 0 {
            timeHours = String(format:"-%@", timeHours)
        }

        eventTimeHours?.text   = timeHours
        eventTimeMinutes?.text = String(format:"%02ld", minute)
    }

    private func updateStopLabelWithDate(date: NSDate) {
        let unitFlags: NSCalendarUnit = [.Year, .Month, .Day, .Hour, .Minute]

        let components: NSDateComponents = calendar.components(unitFlags, fromDate: date)

        eventStopTime?.text  = String(format: "%02ld:%02ld", components.hour, components.minute)
        eventStopDay?.text  = String(format: "%02ld", components.day)
        eventStopYear?.text  = String(format: "%04ld", components.year)
        let index = components.month - 1
        if let month = shortStandaloneMonthSymbols.objectAtIndex(index) as? String {
            eventStopMonth?.text  = month
        }
    }

    private func animateStartEvent() {
        UIView.animateWithDuration(0.3, delay: 0.3, options: .CurveEaseIn, animations: { () -> Void in
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
        UIView.animateWithDuration(0.3, delay: 0.3, options: .CurveEaseIn, animations: { () -> Void in
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

    private func animateEventTransforming(eventTimerTransformingEnum: EventTimerTransformingEnum) {
        UIView.animateWithDuration(0.3, delay: 0.3, options: .CurveEaseIn, animations: { () -> Void in
            var eventStartAlpha: CGFloat = 1
            var eventStopAlpha: CGFloat = 1
            var eventTimeAlpha: CGFloat = 1
            var eventStartMonthYearAlpha: CGFloat = 1
            var eventStopMonthYearAlpha: CGFloat = 1

            switch eventTimerTransformingEnum {
            case .StartDateTransformingStart:
                eventStartAlpha = 1
                eventStartMonthYearAlpha = 1

                eventStopAlpha = 0.2
                eventStopMonthYearAlpha = 0.2

                eventTimeAlpha = 0.2
            case .StartDateTransformingStop:
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
            case .NowDateTransformingStart:
                eventStartAlpha = 0.2
                eventStartMonthYearAlpha = 0.2

                eventStopAlpha = 1
                eventStopMonthYearAlpha = 1

                eventTimeAlpha = 0.2
            case .NowDateTransformingStop:
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

	@IBAction func prepareForUnwind(sender: UIStoryboardSegue) {
		DLog()
	}

    @IBAction func showTags(sender: UIButton) {
        if selectedEventGuid != nil {
            sender.animate()
            navigationController?.delegate = nil
            performSegueWithIdentifier("segueToTagsFromEvent", sender: self)
        }
    }

    @IBAction func toggleEventTouchUpInside(sender: UIButton) {
        guard let eventTimerControl = eventTimerControl, let tag = tag else {
            fatalError("TimerControl is not an instance")
        }

        if let guid = selectedEventGuid {
            guard let event = self.selectedEvent(guid) else {
                fatalError("Have guid but cant find the event")
            }

            if let _ = event.stopDate {
				// Event is stoped, so start a new
				let event = Event(defaultCoreDataStack.managedObjectContext, startDate: NSDate())
                selectedEventGuid = event.guid
				state.selectedEventGUID = event.guid

				eventTimerControl.initWithStartDate(event.startDate, andStopDate: event.stopDate)

				toggleStartStopButton?.setTitle("STOP", forState: .Normal)

				animateStartEvent()

				if let font = UIFont(name: "FontAwesome", size: 20) {
					let attriString = NSAttributedString(string:"\u{f02b}", attributes:
						[NSFontAttributeName: font])

					tag.setAttributedTitle(attriString, forState: .Normal)
				}
            } else {
                // Event is started
                eventTimerControl.stop()
                event.stopDate = eventTimerControl.nowDate

                toggleStartStopButton?.setTitle("START", forState: .Normal)
                animateStopEvent()
            }
        } else {
			// No event exists, start a new
			// Event is stoped, so start a new
			let event = Event(defaultCoreDataStack.managedObjectContext, startDate: NSDate())
            selectedEventGuid = event.guid
            state.selectedEventGUID = event.guid

			eventTimerControl.initWithStartDate(event.startDate, andStopDate: event.stopDate)

			toggleStartStopButton?.setTitle("STOP", forState: .Normal)

			animateStartEvent()

			if let font = UIFont(name: "FontAwesome", size: 20) {
				let attriString = NSAttributedString(string:"\u{f02b}", attributes:
					[NSFontAttributeName: font])

				tag.setAttributedTitle(attriString, forState: .Normal)
			}
		}

        sender.animate()

        do {
            try saveContextAndWait(defaultCoreDataStack.managedObjectContext)
        } catch {
            // TODO: Errorhandling
        }
    }

    private func selectedEvent(guid: String?) -> Event? {
        guard let guid = guid else {
            return nil
        }

        let request = FetchRequest<Event>(context: defaultCoreDataStack.managedObjectContext)

        do {
            return try request.fetchFirstWhere("guid", value: guid)
        } catch {
            print("*** ERROR: [\(__LINE__)] \(__FUNCTION__) Error while executing fetch request:")
        }

        return nil
    }
}

// MARK: - EventTimerControlDelegate
extension EventViewController {
    func startDateDidUpdate(startDate: NSDate!) {
            updateStartLabelWithDate(startDate)

            if let toDate = eventTimerControl?.nowDate {
                updateEventTimeFromDate(startDate, toDate: toDate)
            }
    }

    func nowDateDidUpdate(nowDate: NSDate!) {
        updateStopLabelWithDate(nowDate)

        if let fromDate = eventTimerControl?.startDate {
            updateEventTimeFromDate(fromDate, toDate: nowDate)
        }
    }

    func transformingDidUpdate(transform: EventTimerTransformingEnum) {
        switch transform {
        case .NowDateTransformingStart, .StartDateTransformingStart:
            animateEventTransforming(transform)
        case .NowDateTransformingStop:
            guard let event = selectedEvent(selectedEventGuid) else {
                break
            }

            animateEventTransforming(transform)
            event.stopDate = eventTimerControl?.nowDate

            do {
                try saveContextAndWait(defaultCoreDataStack.managedObjectContext)
            } catch {
                // TODO: Errorhandling
            }
        case .StartDateTransformingStop:
            animateEventTransforming(transform)
            if let startDate = eventTimerControl?.startDate {
                guard let event = selectedEvent(selectedEventGuid) else {
                    break
                }
                event.startDate = startDate

                do {
                    try saveContextAndWait(defaultCoreDataStack.managedObjectContext)
                } catch {
                    // TODO: Errorhandling
                }
			}
        default:
            break
        }
    }
}
