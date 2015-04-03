//
//  TagsTableViewController.swift
//  Drift
//
//  Created by Mikael Hultgren on 28/11/14.
//  Copyright (c) 2014 Artsoftheinsane. All rights reserved.
//

import UIKit
import CoreData
import JSQCoreDataKit

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, TagCellDelegate, DismissProtocol
{
    @IBOutlet var tableView: UITableView!

    var didDismiss: Dismiss?

//    var tableViewRecognizer: TransformableTableViewGestureRecognizer?
//    var reorderTableViewController: ReorderTableViewController?
    var tagInEditState: Tag?

    var reOrderIndexPath: NSIndexPath?

    let editingCommitLength: NSInteger = 60

    var stack: CoreDataStack?

    private lazy var fetchedResultsController: NSFetchedResultsController = {
        if let moc = self.stack?.managedObjectContext {
            var fetchRequest = NSFetchRequest(entityName: "Tag")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sortIndex", ascending: true)]
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

//        self.tableViewRecognizer = self.tableView.enableGestureTableViewWithDelegate(self)

//        self.tableView.registerClass(UITableViewCell.self, forHeaderFooterViewReuseIdentifier: "reorderTableViewCellIdentifier")

//        self.reorderTableViewController = ReorderTableViewController(tableView: self.tableView)

        tableView.addPullingWithActionHandler { (state: AIPullingState, previousState: AIPullingState, height: CGFloat) -> Void in

            if state == AIPullingState.Action {
                if previousState == AIPullingState.PullingAdd {
                    var popTime = dispatch_time(DISPATCH_TIME_NOW, 400000000)
                    dispatch_after(popTime, dispatch_get_main_queue(), { () -> Void in
                        let _ = Tag.createEntity(self.stack?.managedObjectContext)
                    })
                } else if (previousState == AIPullingState.PullingAdd || previousState == AIPullingState.PullingClose) {
                    let _ = self.didDismiss?()
                }
            }
        }

        tableView.pullingView.addingHeight = 0
        tableView.pullingView.closingHeight = 60

        if let guid = State.instance().selectedEventGUID,
            let moc = self.stack?.managedObjectContext,
            let event = Event.findFirstByAttribute(moc, property: "guid", value: guid) as? Event,
            let indexPath = fetchedResultsController.indexPathForObject(event) {
                tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.fetchedResultsController.delegate = nil
        self.tableView.disablePulling()
        
//        self.tableView.disableGestureTableViewWithRecognizer(self.tableViewRecognizer)
    }

    func configureCell(cell: TagCell, atIndexPath: NSIndexPath) -> Void {
        if let tag = fetchedResultsController.objectAtIndexPath(atIndexPath) as? Tag {
            cell.setTitle(tag.name)
            cell.delegate = self
        }
    }

}

// MARK: - UITableViewDelegate
typealias TagsViewController_UITableViewDelegate = TagsViewController
extension TagsViewController_UITableViewDelegate {
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag {
            if tag.name == nil {
                return
            }
            
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? TagCell {
                cell.setSelected(cell.selected, animated: true)
            }
            
            if let guid = State.instance().selectedEventGUID,
                let moc = self.stack?.managedObjectContext,
                let event = Event.findFirstByAttribute(moc, property: "guid", value: guid) as? Event {
                    event.inTag = event.inTag.isEqual(Tag) ? nil : tag
                    saveContextAndWait(moc)
            }
            
            self.didDismiss?()
        }
    }
}

// MARK: - UITableViewDataSource
typealias TagsViewController_UITableViewDataSource = TagsViewController
extension TagsViewController_UITableViewDataSource {
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
//        if let cell = tableView.dequeueReusableCellWithIdentifier("reorderTableViewCellIdentifier") as? UITableViewCell,
//            let reOrderIndexPath = self.reOrderIndexPath where reOrderIndexPath.isEqual(indexPath) {
//
//            cell.selectionStyle = .None
//            return cell
//        }

        
        let cell = tableView.dequeueReusableCellWithIdentifier("TagCellIdentifier") as! TagCell
        self.configureCell(cell, atIndexPath:indexPath)
            
        return cell
    }
}

// MARK: - TagCellDelegate
typealias TagsViewController_TagCellDelegate = TagsViewController
extension TagsViewController_TagCellDelegate {
    func didDeleteTagCell(cell: TagCell) {
        if let indexPath = tableView.indexPathForCell(cell),
            let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag,
            let moc = self.stack?.managedObjectContext {
            
                moc.deleteObject(tag)
                tagInEditState = nil
                saveContextAndWait(moc)
        }
    }

    func didEditTagCell(cell: TagCell) {
        if let indexPath = tableView.indexPathForCell(cell),
            let name = cell.tagNameTextField?.text {
                if !name.isEmpty,
                    let moc = self.stack?.managedObjectContext,
                    let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag {
                        
                        tag.name = name
                        cell.setTitle(name)
                        saveContextAndWait(moc)
                }

                UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .CurveLinear, animations: { () -> Void in
                    cell.frontViewLeadingConstraint?.constant = 0
                    cell.frontViewTrailingConstraint?.constant = 0
                    cell.frontView?.layoutIfNeeded()
                    }, completion: nil)

                self.tagInEditState = nil
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
typealias TagsViewController_NSFetchedResultsControllerDelegate = TagsViewController
extension TagsViewController_NSFetchedResultsControllerDelegate {
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
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? TagCell {
                self.configureCell(cell, atIndexPath: indexPath!)
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

// MARK - TransformableTableViewGestureEditingRowDelegate
//typealias TagsViewController_TransformableTableViewGestureEditingRowDelegate = TagsViewController
//extension TagsViewController_TransformableTableViewGestureEditingRowDelegate {
//    func gestureRecognizer(gestureRecognizer: TransformableTableViewGestureRecognizer, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        return true
//    }
//
//    func gestureRecognizer(gestureRecognizer: TransformableTableViewGestureRecognizer, didEnterEditingState state: TransformableTableViewCellEditingState, forRowAtIndexPath indexPath: NSIndexPath) {
//        
//        if let tagInEditState = self.tagInEditState,
//            let editStateIndexPath = self.fetchedResultsController.indexPathForObject(tagInEditState)
//            where !editStateIndexPath.isEqual(indexPath) {
//                // TODO
//                // [self gestureRecognizer:gestureRecognizer
//                // cancelEditingState:state
//                // forRowAtIndexPath:editStateIndexPath];
//        }
//    }
//
//    func gestureRecognizer(gestureRecognizer: TransformableTableViewGestureRecognizer, didChangeEditingState state: TransformableTableViewCellEditingState, forRowAtIndexPath indexPath: NSIndexPath) {
//        
//        if let tagInEditState = self.tagInEditState,
//            let editStateIndexPath = self.fetchedResultsController.indexPathForObject(tagInEditState)
//            where editStateIndexPath.isEqual(indexPath) {
//                // TODO
//                // [self gestureRecognizer:gestureRecognizer
//                // cancelEditingState:state
//                // forRowAtIndexPath:editStateIndexPath];
//        }
//        
//    }
//}
