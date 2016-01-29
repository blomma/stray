import UIKit
import CoreData

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, EventCellDelegate {
    @IBOutlet weak var tableView: UITableView!

    private let shortStandaloneMonthSymbols: NSArray = NSDateFormatter().shortStandaloneMonthSymbols
	private let transitionOperator = TransitionOperator()
    private let calendar = NSCalendar.autoupdatingCurrentCalendar()
	private var selectedEvent: Event?

	private var fetchedResultsController: NSFetchedResultsController?

    override func viewDidLoad() {
        super.viewDidLoad()

		transitionOperator.navigationController = navigationController
        view.addGestureRecognizer(UIPanGestureRecognizer(target: transitionOperator, action: "handleGesture:"))
    }

    override func viewWillAppear(animated: Bool) {
        let fetchRequest = NSFetchRequest(entityName: Event.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        fetchRequest.fetchBatchSize = 20

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: defaultCoreDataStack.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        let error: NSErrorPointer = nil
        do {
            try controller.performFetch()
        } catch let error1 as NSError {
            error.memory = error1
            print("Unresolved error \(error)")
            exit(-1)
        }

        controller.delegate = self
        fetchedResultsController = controller

        let state = State()
        if let guid = state.selectedEventGUID {
            let request = FetchRequest<Event>(context: defaultCoreDataStack.managedObjectContext)
            do {
                let event = try request.fetchFirstWhere("guid", value: guid)
                if let indexPath = fetchedResultsController?.indexPathForObject(event) {
                    selectedEvent = event
                    tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .None)
                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .None, animated: true)
                }
            } catch {
                // TODO: Errorhandling
            }

        }
    }

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "segueToTagsFromEvents",
			let controller = segue.destinationViewController as? TagsViewController,
			let cell = sender as? UITableViewCell,
			let indexPath = tableView?.indexPathForCell(cell),
			let event = fetchedResultsController?.objectAtIndexPath(indexPath) as? Event {
				controller.eventGuid = event.guid
		}
	}

    private func configureCell(cell: EventCell, atIndexPath: NSIndexPath) -> Void {
        if let event = fetchedResultsController?.objectAtIndexPath(atIndexPath) as? Event {
			if selectedEvent?.guid == event.guid {
				showSelectMark(cell)
			}

            if let inTag = event.inTag,
                let name = inTag.name {
                let attributedString = NSAttributedString(string: name, attributes:
                    [NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 14.0)!])
                cell.tagButton.setAttributedTitle(attributedString, forState: .Normal)
            } else {
                let attributedString = NSAttributedString(string: "\u{f02b}", attributes:
                    [NSFontAttributeName: UIFont(name: "FontAwesome", size: 20.0)!])
                cell.tagButton.setAttributedTitle(attributedString, forState: .Normal)
            }

            // StartTime
            let startTimeFlags: NSCalendarUnit = [.Minute, .Hour, .Day, .Month, .Year]
            let startTimeComponents = calendar.components(startTimeFlags, fromDate: event.startDate)

            cell.eventStartTime.text = String(format: "%02ld:%02ld", startTimeComponents.hour, startTimeComponents.minute)
            cell.eventStartDay.text = String(format: "%02ld", startTimeComponents.day)
            cell.eventStartYear.text = String(format: "%04ld", startTimeComponents.year)

            if let startMonth = shortStandaloneMonthSymbols[startTimeComponents.month - 1] as? String {
                cell.eventStartMonth.text = startMonth
            }

            // EventTime
            let stopDate = event.stopDate != nil ? event.stopDate! : NSDate()
            let eventTimeFlags: NSCalendarUnit = [.Minute, .Hour]
            let eventTimeComponents = calendar.components(eventTimeFlags, fromDate: event.startDate, toDate: stopDate, options: NSCalendarOptions(rawValue: 0))

            cell.eventTimeHours.text = String(format: "%02ld", eventTimeComponents.hour)
            cell.eventTimeMinutes.text = String(format: "%02ld", eventTimeComponents.minute)

            // StopTime
            if let stopDate = event.stopDate {
                let stopTimeFlags: NSCalendarUnit = [.Minute, .Hour, .Day, .Month, .Year]
                let stopTimeComponents = calendar.components(stopTimeFlags, fromDate: stopDate)

                cell.eventStopTime.text = String(format: "%02ld:%02ld", stopTimeComponents.hour, stopTimeComponents.minute)
                cell.eventStopDay.text = String(format: "%02ld", stopTimeComponents.day)
                cell.eventStopYear.text = String(format: "%04ld", stopTimeComponents.year)

                if let stopMonth = shortStandaloneMonthSymbols[stopTimeComponents.month - 1] as? String {
                    cell.eventStopMonth.text = stopMonth
                }
            } else {
                cell.eventStopTime.text = ""
                cell.eventStopDay.text = ""
                cell.eventStopYear.text = ""
                cell.eventStopMonth.text = ""
            }

            cell.delegate = self
        }
    }

    @IBAction func prepareForUnwind(sender: UIStoryboardSegue) {
        DLog()
    }

	@IBAction func toggleEdit(sender: UIBarButtonItem) {
		if tableView.editing {
			tableView.setEditing(false, animated: true)
		} else {
			tableView.setEditing(true, animated: true)
		}
	}

	private func showSelectMark(cell: EventCell) {
		UIView.animateWithDuration(0.3, animations: { () -> Void in
			cell.selectedMark.alpha = 1
		})
	}

	private func hideSelectMark(cell: EventCell) {
		UIView.animateWithDuration(0.3, animations: { () -> Void in
			cell.selectedMark.alpha = 0
		})
	}
}

// MARK: - UITableViewDelegate
typealias EventsViewController_UITableViewDelegate = EventsViewController
extension EventsViewController_UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: false)

		if let event = selectedEvent,
			let indexPath = fetchedResultsController?.indexPathForObject(event),
			let cell = tableView.cellForRowAtIndexPath(indexPath) as? EventCell {
				hideSelectMark(cell)
		}

        if let event = fetchedResultsController?.objectAtIndexPath(indexPath) as? Event,
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? EventCell {
				showSelectMark(cell)
				selectedEvent = event

                let state = State()
                state.selectedEventGUID = event.guid
        }
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let event = fetchedResultsController?.objectAtIndexPath(indexPath) as? Event {
                let state = State()
                if let selectedEventGUID = state.selectedEventGUID where event.guid == selectedEventGUID {
                    state.selectedEventGUID = nil
                }

                deleteObjects([event], inContext: defaultCoreDataStack.managedObjectContext)
                do {
                    try saveContextAndWait(defaultCoreDataStack.managedObjectContext)
                } catch {
                    // TODO: Errorhandling
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
typealias EventsViewController_UITableViewDataSource = EventsViewController
extension EventsViewController_UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController?.sections?[section] {
            return sectionInfo.numberOfObjects
        }

        return 0
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EventCellIdentifier", forIndexPath: indexPath)

        if let cell = cell as? EventCell {
            configureCell(cell, atIndexPath: indexPath)
        }

        return cell
    }
}

// MARK: - EventCellDelegate
typealias EventsViewController_EventCellDelegate = EventsViewController
extension EventsViewController_EventCellDelegate {
    func didPressTag(cell: EventCell) {
        navigationController?.delegate = nil
        performSegueWithIdentifier("segueToTagsFromEvents", sender: cell)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
typealias EventsViewController_NSFetchedResultsControllerDelegate = EventsViewController
extension EventsViewController_NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView?.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = tableView?.cellForRowAtIndexPath(indexPath!) as? EventCell {
                configureCell(cell, atIndexPath: indexPath!)
            }
        case .Move:
            tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView?.endUpdates()
    }
}
