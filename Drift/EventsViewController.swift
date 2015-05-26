//
//  EventsViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-13.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, EventCellDelegate {
    @IBOutlet var tableView: UITableView?

    private lazy var shortStandaloneMonthSymbols: [AnyObject] = {
        return NSDateFormatter().shortStandaloneMonthSymbols
    }()

    private lazy var shortStandaloneWeekdaySymbols: [AnyObject]! = {
        return NSDateFormatter().shortStandaloneWeekdaySymbols
    }()

    private let editingCommitLength: CGFloat = 60

    var stack: CoreDataStack?
    let state: State = State()

    private var fetchedResultsController: NSFetchedResultsController?

    let calendar = NSCalendar.autoupdatingCurrentCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()

        let model = CoreDataModel(name: "CoreDataModel", bundle: NSBundle.mainBundle())
        self.stack = CoreDataStack(model: model)

        if let guid = self.state.selectedEventGUID,
            let moc = self.stack?.managedObjectContext,
            let entity = NSEntityDescription.entityForName(Event.entityName, inManagedObjectContext: moc) {

                let request = FetchRequest<Event>(moc: moc, attribute: "guid", value: guid)
                let result = fetch(request)

                if result.success,
                    let indexPath = self.fetchedResultsController?.indexPathForObject(result.objects[0]) {
                        self.tableView?.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
                }
        }
    }

    override func viewWillAppear(animated: Bool) {
        if let moc = self.stack?.managedObjectContext {
            var fetchRequest = NSFetchRequest(entityName: "Event")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
            fetchRequest.fetchBatchSize = 20

            var controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
            controller.delegate = self

            var error: NSErrorPointer = NSErrorPointer()
            if !controller.performFetch(error) {
                println("Unresolved error \(error)")
                exit(-1)
            }

            self.fetchedResultsController =  controller
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueToTagsFromEvents",
            let controller = segue.destinationViewController as? TagsViewController,
            let cell = sender as? UITableViewCell,
            let indexPath = self.tableView?.indexPathForCell(cell),
            let event = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? Event {

                controller.didDismiss = {
                    dispatch_async(dispatch_get_main_queue(), { [unowned self] in
                        self.dismissViewControllerAnimated(true, completion: nil)
                        })
                }
        }
    }

    func configureCell(cell: EventCell, atIndexPath: NSIndexPath) -> Void {
        if let event = self.fetchedResultsController?.objectAtIndexPath(atIndexPath) as? Event {
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
            let startTimeFlags: NSCalendarUnit = .CalendarUnitMinute | .CalendarUnitHour | .CalendarUnitDay | .CalendarUnitMonth | .CalendarUnitYear
            let startTimeComponents = self.calendar.components(startTimeFlags, fromDate: event.startDate)

            cell.eventStartTime.text = String(format: "%02ld:%02ld", startTimeComponents.hour, startTimeComponents.minute)
            cell.eventStartDay.text = String(format: "%02ld", startTimeComponents.day)
            cell.eventStartYear.text = String(format: "%04ld", startTimeComponents.year)

            if let startMonth = shortStandaloneMonthSymbols[startTimeComponents.month - 1] as? String {
                cell.eventStartMonth.text = startMonth
            }

            // EventTime
            let stopDate = event.stopDate != nil ? event.stopDate! : NSDate()
            let eventTimeFlags: NSCalendarUnit = .CalendarUnitMinute | .CalendarUnitHour
            let eventTimeComponents = self.calendar.components(eventTimeFlags, fromDate: event.startDate, toDate: stopDate, options: NSCalendarOptions(0))

            cell.eventTimeHours.text = String(format: "%02ld", eventTimeComponents.hour)
            cell.eventTimeMinutes.text = String(format: "%02ld", eventTimeComponents.minute)

            // StopTime
            if let stopDate = event.stopDate {
                let stopTimeFlags: NSCalendarUnit = .CalendarUnitMinute | .CalendarUnitHour | .CalendarUnitDay | .CalendarUnitMonth | .CalendarUnitYear
                let stopTimeComponents = self.calendar.components(stopTimeFlags, fromDate: stopDate)

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
}

// MARK: - UITableViewDelegate
typealias EventsViewController_UITableViewDelegate = EventsViewController
extension EventsViewController_UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let event = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? Event,
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? EventCell {
                cell.setSelected(true, animated: true)
                self.state.selectedEventGUID = event.guid
        }
    }

    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? EventCell {
            cell.setSelected(false, animated: true)
        }
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let event = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? Event,
            let moc = self.stack?.managedObjectContext {
                if let selectedEventGUID = self.state.selectedEventGUID where event.guid == selectedEventGUID {
                    self.state.selectedEventGUID = nil
                }

                moc.deleteObject(event)
                saveContextAndWait(moc)
            }
        }
    }
}

// MARK: - UITableViewDataSource
typealias EventsViewController_UITableViewDataSource = EventsViewController
extension EventsViewController_UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = self.fetchedResultsController?.sections?[section] as? NSFetchedResultsSectionInfo {
            return sectionInfo.numberOfObjects
        }

        return 0
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController?.sections?.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: EventCell = tableView.dequeueReusableCellWithIdentifier("EventCellIdentifier") as! EventCell
        configureCell(cell, atIndexPath: indexPath)

        return cell
    }
}

// MARK: - EventCellDelegate
typealias EventsViewController_EventCellDelegate = EventsViewController
extension EventsViewController_EventCellDelegate {
    func didDeleteEventCell(cell: EventCell) {
        if let indexPath = self.tableView?.indexPathForCell(cell),
            let event = self.fetchedResultsController?.objectAtIndexPath(indexPath) as? Event,
            let moc = self.stack?.managedObjectContext {
                if event.guid == self.state.selectedEventGUID {
                    self.state.selectedEventGUID = nil
                }

                moc.deleteObject(event)
                saveContextAndWait(moc)
        }
    }

    func didPressTag(cell: EventCell) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.performSegueWithIdentifier("segueToTagsFromEvents", sender: cell)
        })
    }
}

// MARK: - NSFetchedResultsControllerDelegate
typealias EventsViewController_NSFetchedResultsControllerDelegate = EventsViewController
extension EventsViewController_NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView?.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            self.tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            self.tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = self.tableView?.cellForRowAtIndexPath(indexPath!) as? EventCell {
                configureCell(cell, atIndexPath: indexPath!)
            }
        case .Move:
            self.tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            self.tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView?.endUpdates()
    }
}
