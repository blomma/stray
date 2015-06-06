//
//  EventViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 02/04/15.
//  Copyright (c) 2015 Artsoftheinsane. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

class EventViewController: UIViewController, EventTimerControlDelegate, TransitionOperatorDelegate {
    // MARK: IBOutlet
    @IBOutlet var eventTimerControl: EventTimerControl?
    @IBOutlet var toggleStartStopButton: UIButton?

    @IBOutlet var eventStartTime: UILabel?
    @IBOutlet var eventStartDay: UILabel?
    @IBOutlet var eventStartMonth: UILabel?
    @IBOutlet var eventStartYear: UILabel?

    @IBOutlet var eventTimeHours: UILabel?
    @IBOutlet var eventTimeMinutes: UILabel?

    @IBOutlet var eventStopTime: UILabel?
    @IBOutlet var eventStopDay: UILabel?
    @IBOutlet var eventStopMonth: UILabel?
    @IBOutlet var eventStopYear: UILabel?

    @IBOutlet var tag: UIButton?

    // MARK: Private properties
    private var selectedEvent: Event?

	private let stack: CoreDataStack? = defaultCoreDataStack()
    private let state: State = State()
	private let transitionOperator: TransitionOperator = TransitionOperator()

    private let calendar = NSCalendar.autoupdatingCurrentCalendar()
    private let shortStandaloneMonthSymbols: NSArray = NSDateFormatter().shortStandaloneMonthSymbols

    override func viewDidLoad() {
        super.viewDidLoad()
		DLog()

		transitionOperator.delegate = self
		view.addGestureRecognizer(self.transitionOperator.gestureRecogniser)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
		DLog()
        eventTimerControl?.delegate = self

        if let guid = state.selectedEventGUID,
            let moc = stack?.managedObjectContext {
                let request = FetchRequest<Event>(moc: moc, attribute: "guid", value: guid)
                let result = fetch(request)

                if result.success,
                    let event = result.objects.first {
                    selectedEvent = event

                    eventTimerControl?.initWithStartDate(event.startDate, andStopDate: event.stopDate)

                    if let _ = event.stopDate {
                        toggleStartStopButton?.setTitle("START", forState: .Normal)
                        animateStopEvent()
                    } else {
                        toggleStartStopButton?.setTitle("STOP", forState: .Normal)
                        animateStartEvent()
                    }
                } else {
                    println("*** ERROR: [\(__LINE__)] \(__FUNCTION__) Error while executing fetch request: \(result.error)")
                }
        } else {
            selectedEvent = nil
        }

        if let name = selectedEvent?.inTag?.name,
            let font = UIFont(name: "Helvetica Neue", size: 14) {
                let attriString = NSAttributedString(string:name, attributes:
                    [NSFontAttributeName: font])

                tag?.setAttributedTitle(attriString, forState: .Normal)
        } else if let font = UIFont(name: "FontAwesome", size: 20) {
            let attriString = NSAttributedString(string:"\u{f02b}", attributes:
                [NSFontAttributeName: font])

            tag?.setAttributedTitle(attriString, forState: .Normal)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
		DLog()
    }

	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		DLog()

		eventTimerControl?.delegate = nil
		eventTimerControl?.stop()
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		super.prepareForSegue(segue, sender: sender)
		DLog()
		if segue.identifier == "segueToTagsFromEvent",
			let controller = segue.destinationViewController as? TagsViewController {
				controller.didDismiss = {
					dispatch_async(dispatch_get_main_queue(), { [unowned self] in
						self.dismissViewControllerAnimated(true, completion: nil)
						})
				}
		}
	}

    private func updateStartLabelWithDate(date: NSDate) {
        let unitFlags: NSCalendarUnit = .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute

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
        let unitFlags: NSCalendarUnit = .CalendarUnitHour | .CalendarUnitMinute
        let components: NSDateComponents = calendar.components(unitFlags, fromDate: fromDate, toDate: toDate, options: nil)

        let hour: Int = abs(components.hour)
        let minute: Int = abs(components.minute)

        var eventTimeHours: String = String(format:"%02ld", hour)
        if components.hour < 0 || components.minute < 0 {
            eventTimeHours = String(format:"-%@", eventTimeHours)
        }

        self.eventTimeHours?.text   = eventTimeHours
        eventTimeMinutes?.text = String(format:"%02ld", minute)
    }

    private func updateStopLabelWithDate(date: NSDate) {
        let unitFlags: NSCalendarUnit = .CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour | .CalendarUnitMinute

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
                if let _ = self.selectedEvent?.stopDate {
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
                if let _ = self.selectedEvent?.stopDate {
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

    @IBAction func showTags(sender: UIButton) {
        if selectedEvent != nil {
            sender.animate()
            performSegueWithIdentifier("segueToTagsFromEvent", sender: self)
        }
    }

    @IBAction func toggleEventTouchUpInside(sender: UIButton) {
        if let selectedEvent = selectedEvent {
            if let _ = selectedEvent.stopDate {
                if let moc = stack?.managedObjectContext {
                    // Event is stoped, so start a new
                    let event = Event(moc, startDate: NSDate())
                    self.selectedEvent = event
                    
                    state.selectedEventGUID = event.guid
                    
                    eventTimerControl?.initWithStartDate(event.startDate, andStopDate: event.stopDate)
                    
                    toggleStartStopButton?.setTitle("STOP", forState: .Normal)
                    
                    animateStartEvent()
                    
                    if let font = UIFont(name: "FontAwesome", size: 20) {
                        let attriString = NSAttributedString(string:"\u{f02b}", attributes:
                            [NSFontAttributeName: font])
                        
                        tag?.setAttributedTitle(attriString, forState: .Normal)
                    }
                }
            } else {
                // Event is started
                eventTimerControl?.stop()
                selectedEvent.stopDate = eventTimerControl?.nowDate
                
                toggleStartStopButton?.setTitle("START", forState: .Normal)
                animateStopEvent()
            }
        } else {
            // No event exists, start a new
            if let moc = stack?.managedObjectContext {
                // Event is stoped, so start a new
                let event = Event(moc, startDate: NSDate())
                self.selectedEvent = event
                
                state.selectedEventGUID = event.guid
                
                eventTimerControl?.initWithStartDate(event.startDate, andStopDate: event.stopDate)
                
                toggleStartStopButton?.setTitle("STOP", forState: .Normal)
                
                animateStartEvent()
                
                if let font = UIFont(name: "FontAwesome", size: 20) {
                    let attriString = NSAttributedString(string:"\u{f02b}", attributes:
                        [NSFontAttributeName: font])
                    
                    tag?.setAttributedTitle(attriString, forState: .Normal)
                }
            }
        }
        
        sender.animate()
        if let moc = stack?.managedObjectContext {
            saveContextAndWait(moc)
        }
    }
}

// MARK: - TransitionOperatorDelegate
typealias EventViewControllerTransitionOperatorDelegate = EventViewController
extension EventViewControllerTransitionOperatorDelegate {
	func transitionControllerInteractionDidStart(havePresented: Bool) {
		DLog()
		if let navigationController = self.navigationController {
			navigationController.delegate = self.transitionOperator

			if havePresented {
				navigationController.popViewControllerAnimated(true)
			} else if let controller = self.storyboard?.instantiateViewControllerWithIdentifier("MenuController") as? UIViewController {
				navigationController.pushViewController(controller, animated: true)
			}
		}
	}
}

// MARK: - EventTimerControlDelegate
typealias EventViewController_EventTimerControlDelegate = EventViewController
extension EventViewController_EventTimerControlDelegate {
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
            animateEventTransforming(transform)
            selectedEvent?.stopDate = eventTimerControl?.nowDate

            if let moc = stack?.managedObjectContext {
                saveContextAndWait(moc)
            }
        case .StartDateTransformingStop:
            animateEventTransforming(transform)
            if let startDate = eventTimerControl?.startDate {
                selectedEvent?.startDate = startDate

                if let moc = stack?.managedObjectContext {
                    saveContextAndWait(moc)
                }
            }
        default:
            break
        }
    }
}
