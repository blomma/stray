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

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, DismissProtocol
{
    @IBOutlet var tableView: UITableView!

    var didDismiss: Dismiss?

    var userReorderingCells: Bool = false
    var stack: CoreDataStack?
    let state: State = State()
    
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

        tableView.pullingView.addingHeight = 30
        tableView.pullingView.closingHeight = 60

        if let guid = self.state.selectedEventGUID,
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
    }

    func configureCell(cell: TagCell, atIndexPath: NSIndexPath) -> Void {
        if let tag = fetchedResultsController.objectAtIndexPath(atIndexPath) as? Tag {
            cell.setTitle(tag.name)
        }
    }

    @IBAction func toggleEdit(sender: UIButton) {
        if self.tableView.editing {
            self.tableView.setEditing(false, animated: true)
        } else {
            self.tableView.setEditing(true, animated: true)
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
            
            if let guid = self.state.selectedEventGUID,
                let moc = self.stack?.managedObjectContext,
                let event = Event.findFirstByAttribute(moc, property: "guid", value: guid) as? Event {
                    if let inTag = event.inTag where inTag.isEqual(tag) {
                        event.inTag = nil
                    } else {
                        event.inTag = tag
                    }
                    saveContextAndWait(moc)
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let tag = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Tag,
                let moc = self.stack?.managedObjectContext {
                    moc.deleteObject(tag)
                    saveContextAndWait(moc)
            }
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if !self.tableView.editing {
            return UITableViewCellEditingStyle.None;
        }
        
        return UITableViewCellEditingStyle.Delete;
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if sourceIndexPath == destinationIndexPath {
            return
        }
        
        if let tag = self.fetchedResultsController.objectAtIndexPath(sourceIndexPath) as? Tag,
            let moc = self.stack?.managedObjectContext {
                self.userReorderingCells = true
                tag.sortIndex = destinationIndexPath.row
                saveContextAndWait(moc)
                self.userReorderingCells = false
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
        let cell = tableView.dequeueReusableCellWithIdentifier("TagCellIdentifier") as! TagCell
        self.configureCell(cell, atIndexPath:indexPath)
            
        return cell
    }
}

// MARK: - TagCellDelegate
//typealias TagsViewController_TagCellDelegate = TagsViewController
//extension TagsViewController_TagCellDelegate {
//    func didEditTagCell(cell: TagCell) {
//        if let indexPath = tableView.indexPathForCell(cell),
//            let name = cell.tagNameTextField?.text {
//                if !name.isEmpty,
//                    let moc = self.stack?.managedObjectContext,
//                    let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag {
//                        
//                        tag.name = name
//                        cell.setTitle(name)
//                        saveContextAndWait(moc)
//                }
//
//                UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: .CurveLinear, animations: { () -> Void in
//                    cell.frontViewLeadingConstraint?.constant = 0
//                    cell.frontViewTrailingConstraint?.constant = 0
//                    cell.frontView?.layoutIfNeeded()
//                    }, completion: nil)
//
//                self.tagInEditState = nil
//        }
//    }
//}

// MARK: - NSFetchedResultsControllerDelegate
typealias TagsViewController_NSFetchedResultsControllerDelegate = TagsViewController
extension TagsViewController_NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if self.userReorderingCells {
            return
        }
        
        tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {

        if self.userReorderingCells {
            return
        }

        switch type {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? TagCell {
                self.configureCell(cell, atIndexPath: indexPath!)
            }
        case .Move:
            self.tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if self.userReorderingCells {
            return
        }
        
        tableView.endUpdates()
    }
}