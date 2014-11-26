//
//  EventsViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 2014-10-13.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit
import CoreData

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, EventCellDelegate {
    @IBOutlet var tableView: UITableView!

    private lazy var shortStandaloneMonthSymbols: [AnyObject] = {
        return NSDateFormatter().shortStandaloneMonthSymbols
    }()
    
    private lazy var shortStandaloneWeekdaySymbols: [AnyObject]! = {
        return NSDateFormatter().shortStandaloneWeekdaySymbols
    }()
    
    private let editingCommitLength: CGFloat = 60
    
    private var eventInEditState: Event?

    var dismissDelegate: DismissProtocol?

    private lazy var fetchedResultsController: NSFetchedResultsController = {
        var fetchRequest = NSFetchRequest(entityName: "Event")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
        fetchRequest.fetchBatchSize = 20
        
        var controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.MR_defaultContext(), sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        
        var error: NSErrorPointer = NSErrorPointer()
        if !controller.performFetch(error) {
            println("Unresolved error \(error)")
            exit(-1)
        }
        
        return controller
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.addPullingWithActionHandler { (state: AIPullingState, previousState: AIPullingState, height: CGFloat) -> Void in
            if state == AIPullingState.Action && (previousState == AIPullingState.PullingAdd || previousState == AIPullingState.PullingClose) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let _ = self.dismissDelegate?.didDismiss()
                })
            }
        }
        
        tableView.pullingView.addingHeight = 0
        tableView.pullingView.closingHeight = 60
        
        if let guid = State.instance().selectedEventGUID {
            var event: Event = Event.MR_findFirstByAttribute("guid", withValue: guid) as Event
            
            if let indexPath = fetchedResultsController.indexPathForObject(event) {
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            }
        }
        
        modalPresentationStyle = .Custom
    }

    override func viewDidAppear(animated: Bool) {
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueToTagsFromEvents" {
            var controller = segue.destinationViewController as TagsTableViewController
            controller.didDismissHandler = { () -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            
            if let indexPath = tableView.indexPathForCell(sender as UITableViewCell) {
                var event = fetchedResultsController.objectAtIndexPath(indexPath) as Event
                
                controller.eventGUID = event.guid
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureCell(cell: EventCell, atIndexPath: NSIndexPath) -> Void {
        var event: Event = fetchedResultsController.objectAtIndexPath(atIndexPath) as Event

        if event.inTag != nil {
            let attributedString = NSAttributedString(string: event.inTag.name, attributes:
                [NSFontAttributeName: UIFont(name: "Helvetica Neue", size: 14.0)!])
            cell.tagButton.setAttributedTitle(attributedString, forState: .Normal)
        } else {
            let attributedString = NSAttributedString(string: "\u{f02b}", attributes:
                [NSFontAttributeName: UIFont(name: "FontAwesome", size: 20.0)!])
            cell.tagButton.setAttributedTitle(attributedString, forState: .Normal)
        }
        
        // StartTime
        let startTimeFlags: NSCalendarUnit = .MinuteCalendarUnit | .HourCalendarUnit | .DayCalendarUnit | .WeekCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit
        let startTimeComponents = NSDate.calendar().components(startTimeFlags, fromDate: event.startDate)
        
        cell.eventStartTime.text = String(format: "%02ld:%02ld", startTimeComponents.hour, startTimeComponents.minute)
        cell.eventStartDay.text = String(format: "%02ld", startTimeComponents.day)
        cell.eventStartYear.text = String(format: "%04ld", startTimeComponents.year)
        
        let startMonth = shortStandaloneMonthSymbols[startTimeComponents.month - 1] as String
        cell.eventStartMonth.text = startMonth
        
        // EventTime
        let stopDate = event.stopDate != nil ? event.stopDate : NSDate()
        let eventTimeFlags: NSCalendarUnit = .MinuteCalendarUnit | .HourCalendarUnit
        let eventTimeComponents = NSDate.calendar().components(eventTimeFlags, fromDate: event.startDate, toDate: stopDate, options: NSCalendarOptions(0))

        cell.eventTimeHours.text = String(format: "%02ld", eventTimeComponents.hour)
        cell.eventTimeMinutes.text = String(format: "%02ld", eventTimeComponents.minute)
        
        // StopTime
        if event.stopDate != nil {
            let stopTimeFlags: NSCalendarUnit = .MinuteCalendarUnit | .HourCalendarUnit | .DayCalendarUnit | .WeekCalendarUnit | .MonthCalendarUnit | .YearCalendarUnit
            let stopTimeComponents = NSDate.calendar().components(stopTimeFlags, fromDate: event.stopDate)
            
            cell.eventStopTime.text = String(format: "%02ld:%02ld", stopTimeComponents.hour, stopTimeComponents.minute)
            cell.eventStopDay.text = String(format: "%02ld", stopTimeComponents.day)
            cell.eventStopYear.text = String(format: "%04ld", stopTimeComponents.year)
            
            let stopMonth = shortStandaloneMonthSymbols[stopTimeComponents.month - 1] as String
            cell.eventStopMonth.text = stopMonth
        } else {
            cell.eventStopTime.text = ""
            cell.eventStopDay.text = ""
            cell.eventStopYear.text = ""
            cell.eventStopMonth.text = ""
        }
        
        cell.delegate = self
    }

}

// MARK: - UITableViewDelegate
typealias T_UITableViewDelegate = EventsViewController
extension T_UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var event: Event = fetchedResultsController.objectAtIndexPath(indexPath) as Event
        
        var cell: EventCell = tableView.cellForRowAtIndexPath(indexPath) as EventCell
        cell.setSelected(true, animated: true)
        
        State.instance().selectedEventGUID = event.guid
        
        dismissDelegate?.didDismiss()
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        var cell: EventCell = tableView.cellForRowAtIndexPath(indexPath) as EventCell
        cell.setSelected(false, animated: true)
    }
}

// MARK: - UITableViewDataSource
typealias T_UITableViewDataSource = EventsViewController
extension T_UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: EventCell = tableView.dequeueReusableCellWithIdentifier("EventCellIdentifier") as EventCell
        configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
}

// MARK: - EventCellDelegate
typealias T_EventCellDelegate = EventsViewController
extension T_EventCellDelegate {
    func didDeleteEventCell(cell: EventCell) {
        if let indexPath = tableView.indexPathForCell(cell) {
            var event: Event = fetchedResultsController.objectAtIndexPath(indexPath) as Event
            
            if event.guid == State.instance().selectedEventGUID {
                State.instance().selectedEventGUID = nil
            }
            
            event.MR_deleteEntity()
            
            eventInEditState = nil
            
            NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion(nil)
        }
    }
    
    func didPressTag(cell: EventCell) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.performSegueWithIdentifier("segueToTagsFromEvents", sender: cell)
        })
    }
}

// MARK: - NSFetchedResultsControllerDelegate
typealias T_NSFetchedResultsControllerDelegate = EventsViewController
extension T_NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            var cell: EventCell = tableView.cellForRowAtIndexPath(indexPath!) as EventCell
            configureCell(cell, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}
