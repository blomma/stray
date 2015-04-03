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

class EventsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, EventCellDelegate, DismissProtocol {
    @IBOutlet var tableView: UITableView!

    private lazy var shortStandaloneMonthSymbols: [AnyObject] = {
        return NSDateFormatter().shortStandaloneMonthSymbols
    }()
    
    private lazy var shortStandaloneWeekdaySymbols: [AnyObject]! = {
        return NSDateFormatter().shortStandaloneWeekdaySymbols
    }()
    
    private let editingCommitLength: CGFloat = 60
    
    private var eventInEditState: Event?

    var didDismiss: Dismiss?

    var stack: CoreDataStack?
    
    private lazy var fetchedResultsController: NSFetchedResultsController = {
        if let moc = self.stack?.managedObjectContext {
            var fetchRequest = NSFetchRequest(entityName: "Event")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: true)]
            fetchRequest.fetchBatchSize = 20
            
            var controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
            controller.delegate = self
            
            var error: NSErrorPointer = NSErrorPointer()
            if !controller.performFetch(error) {
                println("Unresolved error \(error)")
                exit(-1)
            }
            
            return controller
        }
        
        println("No moc")
        exit(-1)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bundle = NSBundle(identifier: "com.artsoftheinsane.Drift")
        let model = CoreDataModel(name: "CoreDataModel", bundle: bundle!)
        self.stack = CoreDataStack(model: model)
        
        tableView.addPullingWithActionHandler { (state: AIPullingState, previousState: AIPullingState, height: CGFloat) -> Void in
            if state == AIPullingState.Action && (previousState == AIPullingState.PullingAdd || previousState == AIPullingState.PullingClose) {
                let _ = self.didDismiss?()
            }
        }
        
        tableView.pullingView.addingHeight = 0
        tableView.pullingView.closingHeight = 60
        
        if let guid = State.instance().selectedEventGUID,
            let event = Event.findFirstByAttribute(self.stack?.managedObjectContext, property: "guid", value: State.instance().selectedEventGUID),
            let indexPath = fetchedResultsController.indexPathForObject(event) {
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
        }
        
        modalPresentationStyle = .Custom
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueToTagsFromEvents",
            let controller = segue.destinationViewController as? TagsViewController,
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPathForCell(cell),
            let event = fetchedResultsController.objectAtIndexPath(indexPath) as? Event {

                controller.didDismiss = {
                    dispatch_async(dispatch_get_main_queue(), { [unowned self] in
                        self.dismissViewControllerAnimated(true, completion: nil)
                        })
                }
        }
    }
    
    func configureCell(cell: EventCell, atIndexPath: NSIndexPath) -> Void {
        if let event = fetchedResultsController.objectAtIndexPath(atIndexPath) as? Event {
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
            let startTimeFlags: NSCalendarUnit = .CalendarUnitMinute | .CalendarUnitHour | .CalendarUnitDay | .CalendarUnitMonth | .CalendarUnitYear
            let startTimeComponents = NSDate.calendar().components(startTimeFlags, fromDate: event.startDate)
            
            cell.eventStartTime.text = String(format: "%02ld:%02ld", startTimeComponents.hour, startTimeComponents.minute)
            cell.eventStartDay.text = String(format: "%02ld", startTimeComponents.day)
            cell.eventStartYear.text = String(format: "%04ld", startTimeComponents.year)
            
            if let startMonth = shortStandaloneMonthSymbols[startTimeComponents.month - 1] as? String {
                cell.eventStartMonth.text = startMonth
            }
            
            // EventTime
            let stopDate = event.stopDate != nil ? event.stopDate : NSDate()
            let eventTimeFlags: NSCalendarUnit = .CalendarUnitMinute | .CalendarUnitHour
            let eventTimeComponents = NSDate.calendar().components(eventTimeFlags, fromDate: event.startDate, toDate: stopDate, options: NSCalendarOptions(0))
            
            cell.eventTimeHours.text = String(format: "%02ld", eventTimeComponents.hour)
            cell.eventTimeMinutes.text = String(format: "%02ld", eventTimeComponents.minute)
            
            // StopTime
            if event.stopDate != nil {
                let stopTimeFlags: NSCalendarUnit = .CalendarUnitMinute | .CalendarUnitHour | .CalendarUnitDay | .CalendarUnitMonth | .CalendarUnitYear
                let stopTimeComponents = NSDate.calendar().components(stopTimeFlags, fromDate: event.stopDate)
                
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
        if let event = fetchedResultsController.objectAtIndexPath(indexPath) as? Event,
            let cell = tableView.cellForRowAtIndexPath(indexPath) as? EventCell {
                cell.setSelected(true, animated: true)
                
                State.instance().selectedEventGUID = event.guid
                
                self.didDismiss?()
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? EventCell {
            cell.setSelected(false, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
typealias EventsViewController_UITableViewDataSource = EventsViewController
extension EventsViewController_UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = self.fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo {
            return sectionInfo.numberOfObjects
        }
        
        return 0
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
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
        if let indexPath = tableView.indexPathForCell(cell),
            let event = fetchedResultsController.objectAtIndexPath(indexPath) as? Event,
            let moc = self.stack?.managedObjectContext {
            
                if event.guid == State.instance().selectedEventGUID {
                    State.instance().selectedEventGUID = nil
                }
            
                moc.deleteObject(event)
            
                eventInEditState = nil
                
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
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? EventCell {
                configureCell(cell, atIndexPath: indexPath!)
            }
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}
