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

class TagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, DismissProtocol {
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var editBarButtonItem: UIBarButtonItem!
	@IBOutlet weak var addBarButtonItem: UIBarButtonItem!

    var didDismiss: Dismiss?

    var userReorderingCells: Bool = false
    var stack: CoreDataStack?
    let state: State = State()

    private lazy var fetchedResultsController: NSFetchedResultsController = {
        if let moc = self.stack?.managedObjectContext {
            var fetchRequest = NSFetchRequest(entityName: Tag.entityName)
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

        let model = CoreDataModel(name: "CoreDataModel", bundle: NSBundle.mainBundle())
        stack = CoreDataStack(model: model)

        if let guid = state.selectedEventGUID,
            let moc = stack?.managedObjectContext,
            let entity = NSEntityDescription.entityForName(Event.entityName, inManagedObjectContext: moc) {
                let request = FetchRequest<Event>(moc: moc, attribute: "guid", value: guid)
                let result = fetch(request)

                if result.success,
                    let indexPath = fetchedResultsController.indexPathForObject(result.objects[0]) {
                        tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
                }
        }

		editBarButtonItem?.target = self
		editBarButtonItem?.action = "toggleEdit"

		addBarButtonItem?.target = self
		addBarButtonItem?.action = "addTagRow"
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        fetchedResultsController.delegate = nil
    }

    func configureCell(cell: UITableViewCell, atIndexPath: NSIndexPath) -> Void {
        if let tag = fetchedResultsController.objectAtIndexPath(atIndexPath) as? Tag {
			cell.textLabel?.text = tag.name
        }
    }

    func toggleEdit() {
        if tableView.editing {
            tableView.setEditing(false, animated: true)
        } else {
            tableView.setEditing(true, animated: true)
        }
    }

	func addTagRow() {
		if let moc = self.stack?.managedObjectContext {
			let _ = Tag(moc)
			saveContextAndWait(moc)
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

            if let guid = state.selectedEventGUID,
                let moc = stack?.managedObjectContext,
                let entity = NSEntityDescription.entityForName(Event.entityName, inManagedObjectContext: moc) {

                    let request = FetchRequest<Event>(moc: moc, attribute: "guid", value: guid)
                    let result = fetch(request)

                    if result.success {
                        let event = result.objects[0]
                        if let inTag = event.inTag where inTag.isEqual(tag) {
                            event.inTag = nil
                        } else {
                            event.inTag = tag
                        }
                        saveContextAndWait(moc)
                    }
            }

            dismissViewControllerAnimated(true, completion: nil)
        }
    }

	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if let tag = fetchedResultsController.objectAtIndexPath(indexPath) as? Tag,
                let moc = stack?.managedObjectContext {
                    moc.deleteObject(tag)
                    saveContextAndWait(moc)
            }
        }
    }

	func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

	func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        if sourceIndexPath == destinationIndexPath {
            return
        }

        if let tag = fetchedResultsController.objectAtIndexPath(sourceIndexPath) as? Tag,
            let moc = stack?.managedObjectContext {
                userReorderingCells = true
                tag.sortIndex = destinationIndexPath.row
                saveContextAndWait(moc)
                userReorderingCells = false
        }
    }
}

// MARK: - UITableViewDataSource
typealias TagsViewController_UITableViewDataSource = TagsViewController
extension TagsViewController_UITableViewDataSource {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sectionInfo = fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo {
            return sectionInfo.numberOfObjects
        }

        return 0
    }

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TagCellIdentifier") as! UITableViewCell
        configureCell(cell, atIndexPath:indexPath)

        return cell
    }
}

// MARK: - NSFetchedResultsControllerDelegate
typealias TagsViewController_NSFetchedResultsControllerDelegate = TagsViewController
extension TagsViewController_NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if userReorderingCells {
            return
        }

        tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if userReorderingCells {
            return
        }

        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            if let cell = tableView.cellForRowAtIndexPath(indexPath!) as? TagCell {
                configureCell(cell, atIndexPath: indexPath!)
            }
        case .Move:
            tableView.moveRowAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if userReorderingCells {
            return
        }

        tableView.endUpdates()
    }
}
